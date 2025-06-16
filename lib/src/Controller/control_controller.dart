//   IMPORTACIONES NECESARIAS   //
import 'dart:async'; // Proporciona utilidades para manejo asincrónico: Future, Stream, Timer, etc.
import 'dart:convert'; // Permite codificar y decodificar datos (JSON, UTF8, base64, etc.)
import 'package:flutter/material.dart'; // Importa el framework principal de Flutter para construir interfaces gráficas.
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as btClassic; // Biblioteca para manejar Bluetooth Classic (perfil serial), usada para audio por PTT.
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pw/src/Controller/pttController.dart';
import 'dart:io' show Platform;

/// --NIVEL DE BATERIA-- ///
enum BatteryLevel {
  // Define una enumeración llamada `BatteryLevel`
  full, // Nivel de batería lleno
  medium, // Nivel de batería medio
  low, // Nivel de batería bajo
} // Sirve para representar el estado de batería del dispositivo Bluetooth conectado

class ControlController extends ChangeNotifier {
  /// Internamente en tu ControlController:
  bool _hornT04Active = false;
  bool _wailT04Active = false;
  bool _pttT04Active = false;

  /// --- Helper para reset previo a cualquier comando ---
  void _resetFrame() {
    final reset = <int>[
      0xAA, // header
      0x00, // código “neutro”
      0x00,
      0x00,
      0x00,
      0x00, // payload vacío
      0xFF, // footer
    ];
    sendCommand(reset);
  }

  // ────────────────────────────────────────────────────────────────
  // 📦 BLE - Dispositivo y características
  // ────────────────────────────────────────────────────────────────
  BluetoothDevice? _bleDevice; // Dispositivo BLE genérico
  BluetoothDevice? connectedDevice; // BLE conectado (para operaciones)
  BluetoothDevice?
  connectedDeviceBond; // BLE conectado (posible duplicado innecesario)
  ble.BluetoothDevice?
  connectedBleDevice; // BLE con alias (evitar duplicados si usas `Ble`)
  BluetoothCharacteristic?
  targetCharacteristic; // Característica BLE destino (escritura)
  BluetoothCharacteristic? _writeCharacteristic; // Alias interno para escritura

  // ────────────────────────────────────────────────────────────────
  // 📶 Classic Bluetooth - Dispositivo y conexión
  // ────────────────────────────────────────────────────────────────
  btClassic.BluetoothDevice?
  connectedClassicDevice; // Dispositivo emparejado vía Bluetooth Classic
  btClassic.BluetoothConnection?
  classicConnection; // Conexión activa para transmisión de datos
  String? _bondedMac; // Dirección MAC emparejada
  Timer? _bondMonitorTimer; // Timer que vigila el vínculo Classic

  // ────────────────────────────────────────────────────────────────
  // 🔋 Batería
  // ────────────────────────────────────────────────────────────────
  BatteryLevel batteryLevel = BatteryLevel.full; // Enum del nivel de batería
  String batteryImagePath =
      'assets/images/Estados/battery_full.png'; // Ruta actual de imagen
  Timer? _batteryMonitorTimer; // Timer que escucha batería

  // ────────────────────────────────────────────────────────────────
  // 🔊 Push-To-Talk (PTT)
  // ────────────────────────────────────────────────────────────────
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(); // Recorder para PTT
  bool _isRecorderInitialized = false; // Estado de inicialización del recorder

  StreamSubscription<Uint8List>?
  _micSub; // Subscripción al stream de audio del mic

  final StreamController<Uint8List> _micController =
      StreamController<Uint8List>.broadcast(); // Controlador de audio

  bool isPTTActive = false; // Estado de PTT

  final MethodChannel _audioTrackChannel = const MethodChannel(
    'bygelectronics.pw/audio_track',
  );

  static const MethodChannel _audioSessionChannel = MethodChannel(
    'bygelectronics.pw/audio_session',
  );

  // ────────────────────────────────────────────────────────────────
  // 🚨 Sirena y luces
  // ────────────────────────────────────────────────────────────────
  bool _isSirenActive = false; // Estado de la sirena
  bool get isSirenActive => _isSirenActive; // Getter

  // ────────────────────────────────────────────────────────────────
  // 📡 Conexión y UI
  // ────────────────────────────────────────────────────────────────
  final ValueNotifier<bool> shouldSetup = ValueNotifier(
    false,
  ); // Aviso para volver a configurar
  final ValueNotifier<bool> isBleConnected = ValueNotifier(
    false,
  ); // Estado BLE para la UI

  /// =======================================//
  /// CONFIGURACION DE DISPOSITIVO CONECTADO //
  /// =======================================//

  // Configura el dispositivo BLE conectado, guarda su referencia y busca sus servicios disponibles.
  Future<void> setDevice(BluetoothDevice device) async {
    connectedDevice = device; // Guarda la referencia del dispositivo
    isBleConnected.value = true; // Notifica que hay conexión BLE activa

    // Escucha cambios en el estado de conexión (desconexión automática)
    device.connectionState.listen((state) {
      isBleConnected.value = (state == BluetoothConnectionState.connected);
    });

    await _discoverServices(); // Descubre servicios y características disponibles
  }

  /// Inicia un temporizador para verificar periódicamente si el dispositivo Classic sigue emparejado.
  void startBondMonitoring() {
    _bondMonitorTimer?.cancel(); // Detiene cualquier timer anterior
    _bondMonitorTimer = Timer.periodic(
      const Duration(seconds: 2), // Verifica cada 5 segundos
      (_) => _checkStillBonded(), // Ejecuta la función privada
    );
  }

  /// Detiene el monitoreo del vínculo con el dispositivo emparejado.
  void stopBondMonitoring() {
    _bondMonitorTimer?.cancel(); // Cancela el timer si existe
    _bondMonitorTimer = null;
  }

  /// Verifica si el dispositivo Classic aún está emparejado (presente en la lista bond).
  Future<void> _checkStillBonded() async {
    if (!Platform.isAndroid) return;
    if (_bondedMac == null) {
      _fireSetup(); // Si no hay MAC registrada, redirige a configuración
      return;
    }
    try {
      final bonded =
          await btClassic.FlutterBluetoothSerial.instance
              .getBondedDevices(); // Lista de dispositivos emparejados
      final stillPaired = bonded.any(
        (d) => d.address == _bondedMac,
      ); // Verifica si sigue en la lista
      if (!stillPaired) {
        _fireSetup(); // Si ya no está, dispara el reinicio de configuración
      }
    } catch (e) {
      debugPrint(
        "Error comprobando bond: $e",
      ); // Captura errores de emparejamiento
    }
  }

  /// Dispara el proceso para volver a pantalla de configuración inicial.
  void _fireSetup() {
    stopBondMonitoring(); // Detiene el monitoreo
    shouldSetup.value = true; // Notifica a la UI que debe redirigir
  }

  /// Registra la MAC del dispositivo BLE emparejado como Classic y activa el monitoreo.
  void setDeviceBond(BluetoothDevice bleDevice) {
    _bondedMac =
        bleDevice
            .id
            .id; // Obtiene la MAC desde el objeto BLE (flutter_blue_plus)
    startBondMonitoring(); // Comienza a vigilar si permanece emparejado
  }

  /// Asigna la característica BLE con permisos de escritura (usada para enviar comandos).
  void setWriteCharacteristic(BluetoothCharacteristic characteristic) {
    _writeCharacteristic = characteristic;
  }

  /// Envia un comando de texto como bytes por la característica BLE si tiene permiso de escritura.
  Future<void> sendBtCommand(String command) async {
    if (_writeCharacteristic!.properties.write) {
      // Verifica que se puede escribir
      await _writeCharacteristic?.write(
        utf8.encode(command), // Convierte a bytes
        withoutResponse: true, // No espera respuesta del dispositivo
      );
    }
  }

  /// Cierra manualmente la conexión Classic (si está activa).
  Future<void> disconnectClassic() async {
    await _deactivateBluetoothClassic(); // Lógica de desconexión interna (privada)
  }

  /// Inicia un timer que solicita el estado del sistema (ej. batería) cada 3 segundos.
  void startBatteryStatusMonitoring() {
    _batteryMonitorTimer?.cancel(); // Detiene uno anterior si existe
    _batteryMonitorTimer = Timer.periodic(Duration(seconds: 3), (_) {
      requestSystemStatus(); // Llama a método que envía protocolo
    });
  }

  /// Detiene el monitoreo periódico de estado de batería.
  void stopBatteryStatusMonitoring() {
    _batteryMonitorTimer?.cancel();
    _batteryMonitorTimer = null;
  }

  /// ==============================================//
  /// DESCUBRIR LOS SERVICIOS Y CARACTERISTICAS BLE //
  /// =============================================//

  // Descubre los servicios del dispositivo BLE conectado, busca una característica de escritura y la asigna a 'targetCharacteristic'; si no hay, lo reporta en el log.
  Future<void> _discoverServices() async {
    if (connectedDevice == null)
      return; // Si no hay dispositivo conectado, termina la función.

    List<BluetoothService> services =
        await connectedDevice!
            .discoverServices(); // Obtiene todos los servicios disponibles del dispositivo.

    for (var service in services) {
      // Itera por cada servicio encontrado
      for (var characteristic in service.characteristics) {
        // Itera por cada característica del servicio
        debugPrint(
          "Característica encontrada: ${characteristic.uuid}",
        ); // Muestra el UUID de cada característica encontrada

        if (characteristic.properties.write) {
          // Verifica si la característica permite escritura
          targetCharacteristic =
              characteristic; // Guarda esta característica como la seleccionada para enviar comandos
          debugPrint(
            "Característica de escritura seleccionada: ${characteristic.uuid}", // Muestra cuál fue seleccionada
          );

          await characteristic.setNotifyValue(
            true,
          ); // Activa notificaciones para esa característica
          listenForResponses(
            characteristic,
          ); // Empieza a escuchar respuestas que el dispositivo envíe

          List<int> batteryStatusCommand = [
            // Comando para solicitar estado del sistema (nivel de batería)
            0xAA, 0x14, 0x18, 0x44, 0x30, 0xF9, 0xFF,
          ];

          await characteristic.write(
            // Envía el comando a la característica
            batteryStatusCommand,
            withoutResponse: false, // Espera respuesta del dispositivo
          );

          debugPrint(
            "📤 Protocolo REAL enviado: ${batteryStatusCommand.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase()}",
            // Muestra el comando enviado en formato hexadecimal legible
          );

          return; // Sale de la función después de encontrar y usar la característica
        }
      }
    }

    debugPrint(
      // Si no se encontró una característica de escritura, lo informa
      "No se encontró característica de escritura en los servicios BLE.",
    );
  }

  /// =====================================================================================//
  /// ENVIAR COMANDO / PROTOCOLO AL DISPOSITIVO PW CONECTADO A BLUETOOTH EN FORMATO ASCII //
  /// ===================================================================================//

  // Envía un comando al dispositivo BLE en formato ASCII hexadecimal usando la característica de escritura;
  // valida conexión, convierte los bytes, envía y registra el resultado.

  /// Método que envía una lista de bytes como ASCII por la característica BLE.
  Future<void> sendCommand(List<int> command) async {
    if (targetCharacteristic == null || connectedDevice == null) {
      debugPrint("No hay dispositivo o característica BLE disponible.");
      return;
    }

    String asciiCommand =
        command
            .map((e) => e.toRadixString(16).padLeft(2, '0'))
            .join('')
            .toUpperCase();
    List<int> asciiBytes = asciiCommand.codeUnits;

    try {
      await targetCharacteristic!.write(asciiBytes, withoutResponse: false);
      debugPrint("Comando ASCII enviado: $asciiCommand");
    } catch (e) {
      debugPrint("Error enviando comando ASCII: $e");
    }
  }

  /// ==========================//
  /// CALCULO DE CRC / MOD-BUS //
  /// ========================//

  // Calcula el CRC ModBus para una lista de bytes y devuelve el resultado con los bytes invertidos (low byte primero).
  int calculateCRC(List<int> data) {
    int crc = 0xFFFF; // Valor inicial del CRC según estándar ModBus

    // Recorre cada byte y actualiza el CRC aplicando el algoritmo ModBus
    for (var byte in data) {
      crc ^= byte; // Aplica XOR entre el CRC actual y el byte actual

      for (int i = 0; i < 8; i++) {
        // Procesa los 8 bits de cada byte
        if ((crc & 1) != 0) {
          crc =
              (crc >> 1) ^
              0xA001; // Si el bit menos significativo es 1, aplica desplazamiento y XOR con polinomio ModBus
        } else {
          crc >>= 1; // Si no, solo desplaza a la derecha
        }
      }
    }

    // Reordena los bytes: devuelve el low byte primero y luego el high byte (ModBus usa little endian)
    return ((crc & 0xFF) << 8) |
        ((crc >> 8) & 0xFF); // Combina los bytes en el orden correcto
  } // FIN calculateCRC

  /// =======================//
  /// TEST DE CRC / MOD-BUS //
  /// =====================//

  // Prueba la función `calculateCRC` usando un ejemplo específico y muestra el resultado esperado vs calculado.
  void testCRC() {
    List<int> testData = [
      0xAA,
      0x14,
      0x07,
      0x44,
    ]; // Datos de ejemplo que deberían producir CRC CFC8
    int crc = calculateCRC(testData); // Calcula el CRC real usando la función

    // Muestra en consola el valor esperado vs el obtenido
    debugPrint(
      "CRC esperado: CFC8, CRC calculado: ${crc.toRadixString(16).toUpperCase()}", // Imprime en mayúsculas como string hexadecimal
    );
  } // FIN testCRC

  /// ===============================================//
  /// FUNCIONES DE CONTROL CON PROTOCOLOS CORRECTOS //
  /// =============================================//

  /// === SIRENA ===
  // Activa la sirena enviando el frame [0xAA, 0x14, 0x07, 0x44, 0xCF, 0xC8, 0xFF] por BLE y muestra confirmación en consola.
  void activateSiren() {
    _isSirenActive = true; // Marca estado como activo
    notifyListeners(); // Notifica a la UI si está escuchando

    List<int> frame = [
      0xAA,
      0x14,
      0x07,
      0x44,
      0xCF,
      0xC8,
      0xFF,
    ]; // Protocolo completo con CRC forzado
    sendCommand(frame); // Enviar comando por BLE
    debugPrint("✅ Sirena activada."); // Confirmación en consola
    requestSystemStatus(); // Solicita estado actualizado del sistema
  }

  /// Desactiva la sirena enviando un protocolo con payload 0 y CRC nulo
  void deactivateSiren() {
    _isSirenActive = false; // Marca como desactivado
    notifyListeners(); // Notifica a la UI

    List<int> frame = [
      0xAA,
      0x14,
      0x07,
      0x00,
      0x00,
      0x00,
      0xFF,
    ]; // Protocolo de desactivación
    sendCommand(frame);
    debugPrint("⛔ Sirena desactivada.");
    requestSystemStatus();
  }

  /// === AUXILIAR ===
  // Activa la salida Auxiliar (Luces/Aux) con el frame [0xAA, 0x14, 0x08, 0x44, 0xCC, 0xF8, 0xFF]
  void activateAux() {
    List<int> frame = [
      0xAA,
      0x14,
      0x08,
      0x44,
      0xCC,
      0xF8,
      0xFF,
    ]; // Protocolo Aux
    sendCommand(frame);
    debugPrint("✅ Auxiliar activado.");
    requestSystemStatus();
  } // FIN activateAux

  /// === INTERCOMUNICADOR ===
  // Activa el Intercomunicador (aún no implementado)
  void activateInter() {
    debugPrint("✅ Intercom activado."); // Solo imprime, sin comando aún
  } // FIN activateInter

  /// --- Press (Horn ON) desde la App ---
  Future<void> pressHornApp() async {
    // 1) Validamos que el Horn T04 físico no esté activo
    if (_hornT04Active) {
      debugPrint(
        "❌ No puedes activar Horn de la App mientras Horn T04 está activo.",
      );
      return;
    }

    // 2) Primero enviamos el frame “neutro” de reset (si es que lo necesitas)
    _resetFrame(); // <-- Asegúrate de que este método exista y haga lo que deba (frame neutro)

    // 3) Enviamos el frame de Horn ON (App → BTPW)
    final List<int> hornOnFrame = <int>[
      0xAA, // header
      0x14, // comando general (cambiar tono / Horn)
      0x09, // función “Horn” (ON)
      0x44, // payload byte 1
      0x0C, // payload byte 2
      0xA9, // CRC (checksum)
      0xFF, // footer
    ];
    sendCommand(hornOnFrame);

    debugPrint(
      "✅ [ControlController] Horn ON (App) enviado: "
      "${hornOnFrame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    // 4) Si quieres actualizar inmediatamente el estado del sistema,
    //    solicita el estado completo del módulo:
    requestSystemStatus();
  }

  /// --- Release (Horn OFF) desde la App ---
  Future<void> releaseHornApp() async {
    // 1) Validamos que el Horn T04 físico no esté activo
    if (_hornT04Active) {
      debugPrint(
        "❌ No puedes liberar Horn de la App mientras Horn T04 está activo.",
      );
      return;
    }

    // 2) (Opcional) Si antes necesitabas un “reset” neutro, ya fue enviado en pressHornApp().
    //    De lo contrario puedes volver a hacer _resetFrame() aquí si tu protocolo lo requiere.

    // 3) Enviamos el frame de Horn OFF (App → BTPW)
    final List<int> hornOffFrame = <int>[
      0xAA, // header
      0x14, // comando general (cambiar tono / Horn)
      0x28, // función “Horn” + bit de liberación (0x28)
      0x44, // payload byte 1
      0x74, // payload byte 2
      0xF9, // CRC (checksum)
      0xFF, // footer
    ];
    sendCommand(hornOffFrame);

    debugPrint(
      "✅ [ControlController] Horn OFF (App) enviado: "
      "${hornOffFrame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    // 4) Volvemos a pedir estado completo para que se refleje en consola:
    requestSystemStatus();
  }

  /// --- Press Wail (App) ---
  Future<void> pressWailApp() async {
    // 1) Validamos que el Wail T04 físico no esté activo
    if (_wailT04Active) {
      debugPrint(
        "❌ No puedes activar Wail de la App mientras Wail T04 está activo.",
      );
      return;
    }

    // 2) (Opcional) Enviamos frame neutro de reset, si tu protocolo lo requiere:
    _resetFrame();

    // 3) Construimos y enviamos la trama de “Wail ON (App → BTPW)”
    final List<int> wailOnFrame = <int>[
      0xAA, // header
      0x14, // comando general (cambiar tono / Wail)
      0x10, // función “Wail ON”
      0x44, // payload byte1 (igual que en Horn)
      0xF2, // payload byte2 (parte alta de CRC para “press Wail”)
      0x78, // payload byte3 (parte baja de CRC para “press Wail”)
      0xFF, // footer
    ];
    sendCommand(wailOnFrame);

    debugPrint(
      "✅ [ControlController] Wail ON (App) enviado: "
      "${wailOnFrame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    // 4) Solicitamos de nuevo el estado completo, para que la próxima respuesta
    //    se imprima en consola (BTPW → App).
    requestSystemStatus();
  }

  /// --- Release Wail (App) ---
  Future<void> releaseWailApp() async {
    // 1) Validamos que el Wail T04 físico no esté activo
    if (_wailT04Active) {
      debugPrint(
        "❌ No puedes liberar Wail de la App mientras Wail T04 está activo.",
      );
      return;
    }

    // 2) (Opcional) Si tu protocolo lo requiere, podrías volver a mandar _resetFrame(),
    //    pero normalmente con el “press” basta. Si hace falta, descomenta la línea siguiente:
    // _resetFrame();

    // 3) Construimos y enviamos la trama de “Wail OFF (App → BTPW)”
    final List<int> wailOffFrame = <int>[
      0xAA, // header
      0x14, // comando general (cambiar tono / Wail)
      0x29, // función “Wail OFF” (0x29 según tu protocolo)
      0x44, // payload byte1
      0xB4, // payload byte2 alta del CRC para “release Wail”
      0xA8, // payload byte3 baja del CRC para “release Wail”
      0xFF, // footer
    ];
    sendCommand(wailOffFrame);

    debugPrint(
      "✅ [ControlController] Wail OFF (App) enviado: "
      "${wailOffFrame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    // 4) Solicitamos nuevamente el estado completo para que la respuesta llegue
    //    y se imprima en consola (BTPW → App).
    requestSystemStatus();
  }

  Future<void> initRecorder() async {
    if (_recorder.isStopped && !_isRecorderInitialized) {
      await _recorder.openRecorder();
      _isRecorderInitialized = true;

      _audioStreamController.stream.listen((buffer) async {
        if (classicConnection != null && classicConnection!.isConnected) {
          classicConnection!.output.add(buffer);
          await classicConnection!.output.allSent;
        }
      });
    }
  }

  Future<void> conectarClassicSiRecuerda(String mac) async {
    final dispositivoEmparejado = await buscarEnEmparejados(mac);

    if (dispositivoEmparejado == null) {
      debugPrint('❌ No se encontró el dispositivo emparejado con MAC $mac');
      return;
    }

    if (Platform.isAndroid) {
      classicConnection = await btClassic.BluetoothConnection.toAddress(mac);
      connectedClassicDevice = dispositivoEmparejado;
    }
  }

  Future<btClassic.BluetoothDevice?> buscarEnEmparejados(String mac) async {
    if (!Platform.isAndroid) return null;
    try {
      final bondedDevices =
          await btClassic.FlutterBluetoothSerial.instance.getBondedDevices();
      return bondedDevices.firstWhere((device) => device.address == mac);
    } catch (_) {
      return null; // No se encontró
    }
  }

  Future<bool> tryReconnectClassic() async {
    // Si no tenemos ninguna MAC guardada → no podemos reconectar
    if (_bondedMac == null) {
      debugPrint(
        "❌ No hay ningún dispositivo Bluetooth Classic emparejado registrado.",
      );
      return false;
    }

    if (!Platform.isAndroid) return false;

    try {
      // 1) Buscamos en la lista de dispositivos emparejados (bonded) por la MAC almacenada
      final bondedDevices =
          await btClassic.FlutterBluetoothSerial.instance.getBondedDevices();
      final device = bondedDevices.firstWhere(
        (d) => d.address == _bondedMac,
        orElse: () => throw Exception("Dispositivo emparejado no encontrado"),
      );

      // 2) Intentamos abrir conexión Classic
      if (Platform.isAndroid) {
        classicConnection = await btClassic.BluetoothConnection.toAddress(
          _bondedMac!,
        );
        connectedClassicDevice = device;
      }
      debugPrint("✅ Classic reenlazado automáticamente a $_bondedMac");
      return true;
    } catch (e) {
      debugPrint("❌ No se pudo reconectar Classic automáticamente: $e");
      return false;
    }
  }

  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>();

  /// ====================
  ///   Toggle PTT (App)
  /// ====================
  Future<void> togglePTT() async {
    // 1) Definimos las dos tramas: PTT ON y PTT OFF
    const List<int> pttOnFrame = <int>[
      0xAA, // header
      0x14, // comando general
      0x11, // función “PTT ON”
      0x44, // payload byte1
      0x32, // payload byte2 alta CRC
      0x29, // payload byte3 baja CRC
      0xFF, // footer
    ];
    const List<int> pttOffFrame = <int>[
      0xAA, // header
      0x14, // comando general
      0x30, // función “PTT OFF”
      0x44, // payload byte1
      0x4A, // payload byte2 alta CRC
      0x79, // payload byte3 baja CRC
      0xFF, // footer
    ];

    // 2) Pedimos permiso de micrófono
    if (!await Permission.microphone.request().isGranted) return;

    // 3) Si vamos a encender PTT App pero el PTT físico (T04) ya está activo, bloqueamos:
    if (!isPTTActive && _pttT04Active) {
      debugPrint(
        "❌ No puedes activar PTT de la App mientras PTT T04 está activo.",
      );
      return;
    }

    // 4) Ramo iOS vs Android
    if (Platform.isIOS) {
      // ─────────────── iOS ───────────────
      // 4.1) Configuramos AVAudioSession para Bluetooth/HFP
      try {
        await _audioSessionChannel.invokeMethod('configureForBluetooth');
        debugPrint("✅ AVAudioSession iOS configurado para Bluetooth/HFP.");
      } catch (e) {
        debugPrint("❌ Error configurando AVAudioSession en iOS: $e");
        // Continuamos, aunque sin ruteo BLE/HFP quizá no funcione
      }

      if (!isPTTActive) {
        // ─── PTT ON en iOS ───────────────────
        debugPrint("▶️ Iniciando PTT (iOS)...");

        // 4.2) Enviar comando PTT ON por BLE
        await sendCommand(pttOnFrame);
        debugPrint(
          "✅ [ControlController] PTT ON (App) enviado (iOS): "
          "${pttOnFrame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}",
        );

        // 4.3) Abrir recorder y suscribir al stream (si no está inicializado)
        if (!_isRecorderInitialized) {
          await _recorder.openRecorder();
          _isRecorderInitialized = true;

          _micSub = _micController.stream.listen((buffer) async {
            // En iOS, al tener AVAudioSession con allowBluetooth,
            // el AudioTrack nativo se encargará de enviar el audio al periférico emparejado.
            try {
              await _audioTrackChannel.invokeMethod('writeAudio', buffer);
              debugPrint("🔊 Audio enviado a AudioTrack (iOS).");
            } catch (e) {
              debugPrint("❌ Error enviando audio a AudioTrack: $e");
            }
          });
        }

        // 4.4) Iniciar canal nativo de audio (AudioTrack) en iOS
        try {
          await _audioTrackChannel.invokeMethod('startAudioTrack');
          debugPrint("🎵 Canal de audio nativo iniciado (iOS).");
        } catch (e) {
          debugPrint("❌ No se pudo iniciar AudioTrack en iOS: $e");
        }

        // 4.5) Iniciar grabación
        await _recorder.startRecorder(
          codec: Codec.pcm16,
          sampleRate: 8000,
          numChannels: 1,
          audioSource: AudioSource.microphone,
          toStream: _micController.sink,
        );
        debugPrint("🎙️ Grabación de PTT iniciada (iOS).");

        isPTTActive = true;
      } else {
        // ─── PTT OFF en iOS ──────────────────
        debugPrint("⏹️ Deteniendo PTT (iOS)...");

        // 4.6) Detener grabación si estaba activa
        if (_recorder.isRecording) {
          await _recorder.stopRecorder();
          debugPrint("⏹️ Grabación detenida (iOS).");
        }

        // 4.7) Detener canal nativo (AudioTrack)
        try {
          await _audioTrackChannel.invokeMethod('stopAudioTrack');
          debugPrint("🔇 Canal de audio nativo detenido (iOS).");
        } catch (e) {
          debugPrint("❌ No se pudo detener AudioTrack en iOS: $e");
        }

        // 4.8) Enviar comando PTT OFF por BLE
        await sendCommand(pttOffFrame);
        debugPrint(
          "✅ [ControlController] PTT OFF (App) enviado (iOS): "
          "${pttOffFrame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}",
        );

        isPTTActive = false;
      }
    } else {
      // ─────────────── Android ───────────────
      if (!isPTTActive) {
        // ─── PTT ON en Android ─────────────────
        await sendCommand(pttOnFrame);
        debugPrint("✅ [ControlController] PTT ON (App) enviado (Android).");

        if (!_isRecorderInitialized) {
          await _recorder.openRecorder();
          _isRecorderInitialized = true;

          _micSub = _micController.stream.listen((buffer) async {
            // Enviar por Bluetooth Classic si está conectado
            if (classicConnection != null && classicConnection!.isConnected) {
              classicConnection!.output.add(buffer);
              await classicConnection!.output.allSent;
            }
            // Enviar a la bocina del celular
            try {
              await _audioTrackChannel.invokeMethod('writeAudio', buffer);
            } catch (e) {
              debugPrint("❌ Error enviando a AudioTrack: $e");
            }
          });
        }

        // Iniciar canal nativo y grabación en Android
        await _audioTrackChannel.invokeMethod('startAudioTrack');
        await _recorder.startRecorder(
          codec: Codec.pcm16,
          sampleRate: 8000,
          numChannels: 1,
          audioSource: AudioSource.microphone,
          toStream: _micController.sink,
        );

        isPTTActive = true;
        debugPrint("🎤 [ControlController] Grabación PTT iniciada (Android).");
      } else {
        // ─── PTT OFF en Android ──────────────────
        if (_recorder.isRecording) {
          await _recorder.stopRecorder();
          debugPrint(
            "🛑 [ControlController] Grabación PTT detenida (Android).",
          );
        }
        await _audioTrackChannel.invokeMethod('stopAudioTrack');
        await sendCommand(pttOffFrame);
        debugPrint("✅ [ControlController] PTT OFF (App) enviado (Android).");
        isPTTActive = false;
      }
    }

    // 5) Tras mandar ON u OFF, pedimos el estado completo al módulo
    requestSystemStatus();

    notifyListeners();
  }

  @override
  void dispose() {
    if (_recorder.isRecording) _recorder.stopRecorder();
    _recorder.closeRecorder();
    _micSub?.cancel();
    _micController.close();
    super.dispose();
  }

  Future<void> _deactivateBluetoothClassic() async {
    if (!Platform.isAndroid) return;

    try {
      if (classicConnection != null && classicConnection!.isConnected) {
        await classicConnection!.close();
        debugPrint('⛔ Bluetooth Classic desconectado.');
      }
    } catch (e) {
      debugPrint('❌ Error desconectando Classic: $e');
    } finally {
      classicConnection = null;
    }
  }

  ///===ESTADO DE SISTEMA===
  /// Solicita al módulo que envíe el estado completo (incluido PTT físico)
  void requestSystemStatus() {
    List<int> frame = [0xAA, 0x14, 0x18, 0x44];
    frame.addAll([0x30, 0xF9]); // CRC correcto
    frame.add(0xFF);
    sendCommand(frame);
  }

  /// ===Cambiar Aux a Luces / Luces a Aux===
  void switchAuxLights() {
    List<int> frame = [0xAA, 0x14, 0x24, 0x44];
    frame.addAll([0x77, 0x39]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
    requestSystemStatus();
  }

  /// ===Cambiar Tono de Horn===
  void changeHornTone() {
    List<int> frame = [0xAA, 0x14, 0x25, 0x44];
    frame.addAll([0xB7, 0x68]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
    requestSystemStatus();
  }

  /// ===Sincronizar / Desincronizar luces con sirena===
  void syncLightsWithSiren() {
    List<int> frame = [0xAA, 0x14, 0x26, 0x44];
    frame.addAll([0xB7, 0x98]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
    requestSystemStatus();
  }

  /// ===Autoajuste PA===
  void autoAdjustPA() {
    List<int> frame = [0xAA, 0x14, 0x27, 0x44];
    frame.addAll([0x77, 0xC9]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);

    debugPrint("⏳ Esperar 30 segundos para el autoajuste PA.");
    requestSystemStatus();
  }

  /// ===Desconectar Dispositivo===
  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }
    isBleConnected.value = false;
  }

  void listenForResponses(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);
    characteristic.value.listen((response) {
      // HEX de depuración
      String hex =
          response
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(' ')
              .toUpperCase();
      debugPrint("📩 Respuesta HEX recibida: $hex");

      // 1️⃣ Detectar si la respuesta es eco ASCII (comienza con '41 41' = 'AA' en ASCII)
      if (response.length > 3 && response[0] == 0x41 && response[1] == 0x41) {
        debugPrint("🔴 Trama es un eco ASCII, intentamos decodificar...");

        try {
          String ascii = utf8.decode(response).trim();
          final hexClean = ascii.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '');
          final bytes = <int>[];

          for (int i = 0; i < hexClean.length - 1; i += 2) {
            bytes.add(int.parse(hexClean.substring(i, i + 2), radix: 16));
          }

          // 🔁 Reasignamos los bytes decodificados
          response = bytes;
        } catch (e) {
          debugPrint("❌ Error al decodificar trama ASCII: $e");
          return;
        }
      }

      // 2️⃣ Validación real del frame esperado de estado de sistema
      if (response.length >= 7 &&
          response[0] == 0xAA &&
          response[1] == 0x18 &&
          response[2] == 0x18 &&
          response[3] == 0x55) {
        final batteryByte = response[5];
        debugPrint(
          "🔋 Byte de batería: 0x${batteryByte.toRadixString(16).toUpperCase()}",
        );

        switch (batteryByte) {
          case 0x14:
            batteryLevel = BatteryLevel.full;
            batteryImagePath = 'assets/images/Estados/battery_full.png';
            debugPrint("✅ Batería COMPLETA");
            break;
          case 0x15:
            batteryLevel = BatteryLevel.medium;
            batteryImagePath = 'assets/images/Estados/battery_medium.png';
            debugPrint("⚠️ Batería MEDIA");
            break;
          case 0x16:
            batteryLevel = BatteryLevel.low;
            batteryImagePath = 'assets/images/Estados/battery_low.png';
            debugPrint("🚨 Batería BAJA");
            break;
          default:
            debugPrint("❓ Byte de batería desconocido: $batteryByte");
            break;
        }

        notifyListeners();
      } else {
        debugPrint("⚠️ Trama no coincide con estado de sistema esperada.");
      }
    });
  }

  /// Envía el protocolo por BLE para que el hardware active el modo Classic (BT_PwAudio)
  Future<void> sendActivateAudioModeOverBLE() async {
    // Ejemplo de trama para cambiar al modo Audio (ajustala si es distinta)
    final frame = [
      0xAA,
      0x14,
      0x30,
      0x44,
      0xAB,
      0xCD,
      0xFF,
    ]; // <- cámbiala si tenés otra
    await sendCommand(frame); // Usa tu función real para enviar por BLE
    print("📡 Comando enviado por BLE para activar BT_PwAudio.");
  }

  Future<bool> conectarManualBLE(BuildContext context) async {
    ble.BluetoothDevice? device;

    try {
      debugPrint("🔵 Iniciando conexión manual BLE...");

      // 1. Comprueba dispositivos ya conectados
      final connected = await ble.FlutterBluePlus.connectedDevices;
      try {
        device = connected.firstWhere(
          (d) => d.platformName.toLowerCase().contains('btpw'),
        );
        debugPrint("✅ Dispositivo Pw ya conectado: ${device.platformName}");
      } catch (_) {
        // 2. Si no hay ninguno, escanea durante 5s para encontrarlo
        debugPrint("🛜 Escaneando BLE en busca de Pw...");
        final completer = Completer<ble.BluetoothDevice>();
        final sub = ble.FlutterBluePlus.scanResults.listen((results) {
          for (var r in results) {
            if (r.device.platformName.toLowerCase().contains('btpw')) {
              completer.complete(r.device);
              break;
            }
          }
        });

        await ble.FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 5),
        );
        try {
          device = await completer.future.timeout(const Duration(seconds: 5));
          debugPrint("🔍 Pw encontrado: ${device.platformName}");
        } catch (_) {
          debugPrint("❌ No se encontró Pw tras escaneo.");
        }
        await ble.FlutterBluePlus.stopScan();
        await sub.cancel();
      }

      // 3. Si lo encontramos, nos conectamos
      if (device != null) {
        debugPrint("🔌 Conectando a ${device.platformName}...");
        await device.connect(timeout: const Duration(seconds: 8));
        debugPrint("✅ Conexión BLE exitosa.");

        // 4. Descubrir servicios y buscar característica ff01
        await device.discoverServices();
        ble.BluetoothCharacteristic? writeChar;
        for (var svc in device.servicesList) {
          for (var ch in svc.characteristics) {
            if (ch.uuid.toString().toLowerCase().contains('ff01')) {
              writeChar = ch;
              break;
            }
          }
          if (writeChar != null) break;
        }

        if (writeChar == null) {
          debugPrint("❌ No se encontró característica ff01.");
          Navigator.pushReplacementNamed(context, '/splash_denegate');
          return false;
        }

        // 5. Configurar este controller
        setDevice(device);
        setWriteCharacteristic(writeChar);

        // 6. Mostrar splash de confirmación
        Navigator.pushReplacementNamed(
          context,
          '/splash_confirmacion',
          arguments: {'device': device, 'controller': this},
        );
        return true;
      } else {
        Navigator.pushReplacementNamed(context, '/splash_denegate');
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error en conectarManualBLE: $e");
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/splash_denegate');
      }
      return false;
    }
  }
} //FIN ControlController
