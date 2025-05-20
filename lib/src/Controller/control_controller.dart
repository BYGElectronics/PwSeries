///================================///
///     IMPORTACIONES NECESARIAS   ///
///================================///
library; // ⚠️ Incorrecto: falta el nombre de la biblioteca. Debería ser algo como `library mi_biblioteca;`

import 'dart:async'; // Proporciona utilidades para manejo asincrónico: Future, Stream, Timer, etc.
import 'dart:convert'; // Permite codificar y decodificar datos (JSON, UTF8, base64, etc.)
import 'dart:io';
import 'package:flutter/material.dart'; // Importa el framework principal de Flutter para construir interfaces gráficas.
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:path_provider/path_provider.dart'; // Permite obtener rutas de almacenamiento del sistema (temporales, documentos, etc.)
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as btClassic; // Biblioteca para manejar Bluetooth Classic (perfil serial), usada para audio por PTT.
import 'package:get/get.dart'; // Framework para manejo de estado, navegación y dependencias. ⚠️ Actualmente no se usa en este archivo.
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pw/src/Controller/pttController.dart';

import 'package:pw/src/Controller/services.dart'; // Permite trabajar con arrays de bytes (Uint8List, ByteBuffer, etc.), útil para transmisión de datos binarios.

/// --NIVEL DE BATERIA-- ///
enum BatteryLevel {
  // Define una enumeración llamada `BatteryLevel`
  full, // Nivel de batería lleno
  medium, // Nivel de batería medio
  low, // Nivel de batería bajo
} // Sirve para representar el estado de batería del dispositivo Bluetooth conectado

class ControlController extends ChangeNotifier {
  // ────────────────────────────────────────────────────────────────
  // 📦 BLE - Dispositivo y características
  // ────────────────────────────────────────────────────────────────
  BluetoothDevice? _bleDevice; // Dispositivo BLE genérico
  BluetoothDevice? connectedDevice; // BLE conectado (para operaciones)
  BluetoothDevice?
  connectedDeviceBond; // BLE conectado (posible duplicado innecesario)
  ble.BluetoothDevice?
  connectedBleDevice; // BLE con alias (evitar duplicados si usas `Ble`)
  late BluetoothDevice
  _device; // Local (puede unificarse con `connectedDevice`)
  late ble.BluetoothService _service; // Servicio BLE encontrado
  late ble.BluetoothCharacteristic
  _characteristic; // Característica BLE dentro del servicio
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
  Timer? _batteryStatusTimer; // Timer que solicita estado del sistema (BLE)
  Timer? _batteryMonitorTimer; // Timer que escucha batería

  // ────────────────────────────────────────────────────────────────
  // 🔊 Push-To-Talk (PTT)
  // ────────────────────────────────────────────────────────────────
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(); // Recorder para PTT

  StreamSubscription<Uint8List>?
  _micSub; // Subscripción al stream de audio del mic

  final StreamController<Uint8List> _micController =
      StreamController<Uint8List>.broadcast(); // Controlador de audio

  bool isPTTActive = false; // Estado de PTT
  bool _isRecorderInitialized = false; // Estado de inicialización del recorder

  final PttAudioController _pttAudio = PttAudioController();

  static const MethodChannel _scoChannel = MethodChannel(
    'bygelectronics.pw/sco',
  );

  final MethodChannel _channel = const MethodChannel(
    'bygelectronics.pw/audio_track',
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
      const Duration(seconds: 5), // Verifica cada 5 segundos
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
  Future<void> sendCommand(List<int> command) async {
    if (targetCharacteristic == null || connectedDevice == null) {
      debugPrint(
        "No hay dispositivo o característica BLE disponible.",
      ); // ⚠️ Sin dispositivo o característica: no se puede enviar
      return;
    }

    // Convierte la lista de bytes [int] en una cadena hexadecimal tipo 'AA14184430F9FF'
    String asciiCommand =
        command
            .map(
              (e) => e.toRadixString(16).padLeft(2, '0'),
            ) // Cada byte → string hex con 2 dígitos
            .join('')
            .toUpperCase(); // En mayúsculas

    // Transforma el string hexadecimal en código ASCII (A → 65, F → 70, etc.)
    List<int> asciiBytes = asciiCommand.codeUnits;

    try {
      await targetCharacteristic!.write(
        asciiBytes,
        withoutResponse: false,
      ); // Escribe en la característica BLE

      debugPrint(
        "Comando ASCII enviado a ${connectedDevice!.platformName}: $asciiCommand", // Muestra el string enviado
      );

      // ✅ Si deseas que cada comando refresque el estado del sistema, descomenta:
      // requestSystemStatus();
    } catch (e) {
      debugPrint(
        "Error enviando comando ASCII a ${connectedDevice!.platformName}: $e", // Muestra error en caso de fallo
      );
    }
  } // FIN sendCommand

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

  /// === HORN ===
  // Alterna la bocina (Horn). Primero envía un reset neutro y luego el comando principal.
  void toggleHorn() {
    List<int> resetFrame = [
      0xAA,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xFF,
    ]; // Frame neutro para reset
    sendCommand(resetFrame);

    List<int> frame = [
      0xAA,
      0x14,
      0x09,
      0x44,
      0x0C,
      0xA9,
      0xFF,
    ]; // Comando de bocina (Horn)
    sendCommand(frame);
    debugPrint("✅ Horn alternado después de reset.");
    requestSystemStatus();
  } // FIN toggleHorn

  /// === WAIL ===
  // Activa el sonido Wail con el frame correspondiente
  void toggleWail() {
    List<int> frame = [
      0xAA,
      0x14,
      0x10,
      0x44,
      0xF2,
      0x78,
      0xFF,
    ]; // Protocolo Wail
    sendCommand(frame);
    debugPrint("✅ Wail alternado.");
    requestSystemStatus();
  } // FIN toggleWail

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

  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>();

  Future<void> togglePTT() async {
    const pttFrame = <int>[0xAA, 0x14, 0x11, 0x44, 0x32, 0x29, 0xFF];

    if (!await Permission.microphone.request().isGranted) return;

    if (!isPTTActive) {
      await sendCommand(pttFrame); // Activa PTT hardware

      if (!_isRecorderInitialized) {
        await _recorder.openRecorder();
        _isRecorderInitialized = true;

        _micSub = _micController.stream.listen((buffer) async {
          // Enviar por Bluetooth Classic
          if (classicConnection != null && classicConnection!.isConnected) {
            classicConnection!.output.add(buffer);
            await classicConnection!.output.allSent;
          }

          // Enviar a la bocina del celular
          try {
            await _channel.invokeMethod('writeAudio', buffer);
          } catch (e) {
            debugPrint("❌ Error enviando a AudioTrack: $e");
          }
        });
      }

      // 🟢 Iniciar canal de audio nativo
      await _channel.invokeMethod('startAudioTrack');

      // Iniciar grabación
      await _recorder.startRecorder(
        codec: Codec.pcm16,
        sampleRate: 8000,
        numChannels: 1,
        audioSource: AudioSource.microphone,
        toStream: _micController.sink,
      );

      isPTTActive = true;
    } else {
      // Detener grabación
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }

      // 🔴 Detener canal de audio nativo
      await _channel.invokeMethod('stopAudioTrack');

      await sendCommand(pttFrame); // Desactiva PTT hardware
      isPTTActive = false;
    }

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

  // === Métodos auxiliares ===

  Future<void> _startLiveMicToClassic() async {
    try {
      if (!_recorder.isRecording) {
        await _recorder.openRecorder();

        final controller = StreamController<Uint8List>();

        controller.stream.listen((chunk) {
          debugPrint("🎧 Enviando chunk de ${chunk.length} bytes");
          if (classicConnection != null && classicConnection!.isConnected) {
            classicConnection!.output.add(chunk);
            classicConnection!.output.allSent;
          }
        });

        await _recorder.startRecorder(
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: 8000,
          toStream: controller.sink,
        );

        debugPrint("🎤 Transmisión de audio en tiempo real INICIADA");
      }
    } catch (e) {
      debugPrint("❌ Error iniciando transmisión en vivo: $e");
    }
  }

  Future<void> _stopLiveMicToClassic() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
        await _recorder.closeRecorder();
        debugPrint("⛔ Transmisión de audio DETENIDA");
      }
    } catch (e) {
      debugPrint("❌ Error deteniendo audio en vivo: $e");
    }
  }

  Future<void> _connectClassicIfRemembered(String mac) async {
    try {
      final bonded =
          await btClassic.FlutterBluetoothSerial.instance.getBondedDevices();
      final device = bonded.firstWhere(
        (d) => d.address == mac,
        orElse: () => throw Exception("⚠️ Classic no encontrado"),
      );
      classicConnection = await btClassic.BluetoothConnection.toAddress(mac);
      debugPrint("✅ Conexión Classic establecida con $mac");
    } catch (e) {
      debugPrint("❌ Error conectando Classic: $e");
    }
  }

  /// === PERMISO MICRÓFONO ===
  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _deactivateBluetoothClassic() async {
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
  // Solicita el estado del sistema construyendo y enviando el frame [0xAA, 0x14, 0x18, 0x44, 0x30, 0xF9, 0xFF] por BLE.
  void requestSystemStatus() {
    List<int> frame = [0xAA, 0x14, 0x18, 0x44];
    frame.addAll([0x30, 0xF9]); // ✅ CRC correcto
    frame.add(0xFF); // Fin de trama
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
          Navigator.pushReplacementNamed(context, 'splash_denegate');
          return false;
        }

        // 5. Configurar este controller
        setDevice(device);
        setWriteCharacteristic(writeChar);

        // 6. Mostrar splash de confirmación
        Navigator.pushReplacementNamed(
          context,
          'splash_confirmacion',
          arguments: {'device': device, 'controller': this},
        );
        return true;
      } else {
        Navigator.pushReplacementNamed(context, 'splash_denegate');
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error en conectarManualBLE: $e");
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, 'splash_denegate');
      }
      return false;
    }
  }
} //FIN ControlController
