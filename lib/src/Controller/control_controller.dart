///================================///
///     IMPORTACIONES NECESARIAS   ///
///================================///
library; // Se utiliza para definir una biblioteca

import 'dart:async'; // Proporciona herramientas para trabajar con asincronía: Future, Stream, Timer, etc.
import 'dart:convert'; // Permite codificación y decodificación de datos, útil para manejar ASCII, JSON, UTF8, etc.
import 'package:flutter/material.dart'; // Framework principal de Flutter para construir interfaces gráficas.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    as Ble; // Manejo de Bluetooth Low Energy (BLE), renombrado como Ble para diferenciarlo si se usa también flutter_blue_plus sin alias.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Importación directa de BLE sin alias. Podría ser redundante si ya se usa la versión con alias (verificar si ambas son necesarias).
import 'package:permission_handler/permission_handler.dart'; // Solicita y gestiona permisos en tiempo de ejecución (ej. Bluetooth, micrófono, ubicación).
import 'package:flutter_sound/flutter_sound.dart'; // Biblioteca para grabar y reproducir audio, usada en la función de Push-To-Talk (PTT).
import 'package:path_provider/path_provider.dart'; // Proporciona acceso a rutas del sistema de archivos (temporales, documentos, etc.), útil para guardar audios grabados.
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as btClassic; // Biblioteca para manejar Bluetooth Classic (Serial Port Profile), usada para la conexión de audio por PTT.
import 'package:get/get.dart'; // Framework para manejo de estado, navegación y dependencias. (Actualmente **no se usa en tu código**, pero podría estar planeado para futuras integraciones).
import 'dart:typed_data';

enum BatteryLevel {
  full,
  medium,
  low,
} //Sirve para representar el estado de batería del dispositivo Bluetooth conectado

class ControlController extends ChangeNotifier {
  BluetoothDevice?
  connectedDevice; // Dispositivo BLE actualmente conectado, usado para operaciones de comunicación.
  btClassic.BluetoothConnection?
  classicConnection; // Conexión Bluetooth Classic activa, utilizada para transmisión de audio (PTT).
  BluetoothCharacteristic?
  targetCharacteristic; // Característica BLE con permiso de escritura, usada para enviar comandos.
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(); // Grabador de audio utilizado en la funcionalidad Push-To-Talk (PTT).
  bool isPTTActive =
      false; // Estado actual del botón PTT; indica si está activado o desactivado.
  String batteryImagePath =
      'assets/images/Estados/battery_full.png'; // Ruta de la imagen que representa el nivel actual de batería.
  Timer?
  _batteryStatusTimer; // Temporizador para manejar el envío periódico de solicitudes de estado.
  Timer?
  _batteryMonitorTimer; // Temporizador encargado de monitorear el estado de batería en intervalos definidos.
  late BluetoothDevice
  _device; // Referencia local al dispositivo conectado, similar a `connectedDevice`.
  BatteryLevel batteryLevel =
      BatteryLevel
          .full; // Nivel actual de batería, representado como enum: full, medium o low.
  late Ble.BluetoothService
  _service; // Servicio BLE descubierto en el dispositivo, utilizado para acceder a características.
  late Ble.BluetoothCharacteristic
  _characteristic; // Característica específica descubierta dentro del servicio BLE.
  late BluetoothCharacteristic
  _writeCharacteristic; // Característica específica con permisos de escritura, usada para enviar comandos.
  RxBool isPttActive =
      false
          .obs; // Estado reactivo del botón PTT, útil para interfaces que usan programación reactiva (GetX).

  StreamSubscription? _micStreamSubscription;

  /// =======================================//
  /// CONFIGURACION DE DISPOSITIVO CONECTADO //
  /// =======================================//

  // Configura el dispositivo BLE conectado, guarda su referencia y busca sus servicios disponibles.
  void setDevice(BluetoothDevice device) async {
    // Guarda el dispositivo BLE seleccionado
    connectedDevice = device;

    // Descubre los servicios y características del dispositivo conectado
    await _discoverServices();
  } //FIN setDevice

  void setWriteCharacteristic(
    BluetoothService service,
    BluetoothCharacteristic charac,
  ) {
    _service = service;
    _writeCharacteristic = charac;
  }

  Future<void> sendBtCommand(String command) async {
    if (_writeCharacteristic.properties.write) {
      await _writeCharacteristic.write(
        utf8.encode(command),
        withoutResponse: true,
      );
    }
  }

  Future<void> activatePTT() async {
    isPttActive.value = true;
    await sendBtCommand("PTT_ON");
    // Aquí podrías iniciar lógica Classic BT si aplica
  }

  void startBatteryStatusMonitoring() {
    _batteryMonitorTimer?.cancel(); // Limpia si hay uno activo
    _batteryMonitorTimer = Timer.periodic(Duration(seconds: 3), (_) {
      requestSystemStatus();
    });
  }

  void stopBatteryStatusMonitoring() {
    _batteryMonitorTimer?.cancel();
    _batteryMonitorTimer = null;
  }

  /// ==============================================//
  /// DESCUBRIR LOS SERVICIOS Y CARACTERISTICAS BLE //
  /// =============================================//

  // Descubre los servicios del dispositivo BLE conectado, busca una característica de escritura y la asigna a 'targetCharacteristic'; si no hay, lo reporta en el log.
  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        debugPrint("Característica encontrada: ${characteristic.uuid}");

        if (characteristic.properties.write) {
          targetCharacteristic = characteristic;
          debugPrint(
            "Característica de escritura seleccionada: ${characteristic.uuid}",
          );

          await characteristic.setNotifyValue(true);
          listenForResponses(characteristic);

          List<int> batteryStatusCommand = [
            0xAA,
            0x14,
            0x18,
            0x44,
            0x30,
            0xF9,
            0xFF,
          ];

          await characteristic.write(
            batteryStatusCommand,
            withoutResponse: false,
          );

          debugPrint(
            "📤 Protocolo REAL enviado: ${batteryStatusCommand.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase()}",
          );

          return;
        }
      }
    }

    debugPrint(
      "No se encontró característica de escritura en los servicios BLE.",
    );
  }

  /// =====================================================================================//
  /// ENVIAR COMANDO / PROTOCOLO AL DISPOSITIVO PW CONECTADO A BLUETOOTH EN FORMARO ASCII //
  /// ===================================================================================//

  // Envía un comando al dispositivo BLE en formato ASCII hexadecimal usando la característica de escritura; valida conexión, convierte los bytes, envía y registra el resultado.
  Future<void> sendCommand(List<int> command) async {
    // Si no tenemos una característica de escritura asignada o no hay dispositivo conectado, se avisa y se sale.
    if (targetCharacteristic == null || connectedDevice == null) {
      debugPrint("No hay dispositivo o característica BLE disponible.");
      return;
    }

    // Convertir la lista de bytes en una cadena de texto hexadecimal ASCII.
    String asciiCommand =
        command
            .map((e) => e.toRadixString(16).padLeft(2, '0'))
            .join('')
            .toUpperCase();

    // Convierte la cadena en un arreglo de bytes ASCII.
    List<int> asciiBytes = asciiCommand.codeUnits;

    try {
      await targetCharacteristic!.write(asciiBytes, withoutResponse: false);

      debugPrint(
        "Comando ASCII enviado a ${connectedDevice!.platformName}: $asciiCommand",
      );

      // ✅ Siempre que se envía un comando, solicitamos el estado de batería
      //requestSystemStatus();
    } catch (e) {
      // Si algo falla en la escritura, se registra el error.
      debugPrint(
        "Error enviando comando ASCII a ${connectedDevice!.platformName}: $e",
      );
    }
  } //FIN sendCommand

  /// ==========================//
  /// CALCULO DE CRC / MOD-BUS //
  /// ========================//

  // Calcula el CRC ModBus para una lista de bytes y devuelve el resultado con los bytes invertidos (low primero, luego high).
  int calculateCRC(List<int> data) {
    int crc = 0xFFFF;
    // Recorre cada byte y actualiza el CRC en base al algoritmo ModBus
    for (var byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        // Si el bit menos significativo de crc es 1, se desplaza y se aplica XOR con 0xA001
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          // De lo contrario, simplemente se desplaza a la derecha.
          crc >>= 1;
        }
      }
    }
    // Se reordenan los bytes del resultado final antes de retornarlo.
    return ((crc & 0xFF) << 8) | ((crc >> 8) & 0xFF);
  } //FIN calculateCRC

  /// =======================//
  /// TEST DE CRC / MOD-BUS //
  /// =====================//

  // Prueba la función `calculateCRC` usando datos de ejemplo y compara el resultado con el CRC esperado (`CFC8`).
  void testCRC() {
    // Datos de prueba para verificar el CRC.
    List<int> testData = [0xAA, 0x14, 0x07, 0x44];
    // Se calcula el CRC para los datos de prueba.
    int crc = calculateCRC(testData);
    // Se muestra el resultado comparando el CRC esperado con el calculado.
    debugPrint(
      "CRC esperado: CFC8, CRC calculado: ${crc.toRadixString(16).toUpperCase()}",
    );
  } //FIN testCRC

  /// ===============================================//
  /// FUNCIONES DE CONTROL CON PROTOCOLOS CORRECTOS //
  /// =============================================//

  ///===SIRENA===
  // Activa la sirena enviando el frame [0xAA, 0x14, 0x07, 0x44, 0xCF, 0xC8, 0xFF] por BLE y muestra confirmación en consola.
  void activateSiren() {
    // Enviar el protocolo para activar Sirena
    List<int> frame = [0xAA, 0x14, 0x07, 0x44, 0xCF, 0xC8, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Sirena activada.");
    requestSystemStatus();
  } //FIN activateSiren

  ///===AUXILIAR===
  // Activa la salida Auxiliar enviando el frame [0xAA, 0x14, 0x08, 0x44, 0xCC, 0xF8, 0xFF] por BLE y muestra confirmación en consola.
  void activateAux() {
    // Enviar el protocolo para activar Auxiliar
    List<int> frame = [0xAA, 0x14, 0x08, 0x44, 0xCC, 0xF8, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Auxiliar activado.");
    requestSystemStatus();
  } //FIN activateAux

  ///===INTERCOMUNICADOR===
  // Activa el Intercomunicador enviando el frame [0xAA, 0x14, 0x12, 0x44, 0x32, 0xD9, 0xFF] por BLE y muestra confirmación en consola.
  void activateInter() {
    // Enviar el protocolo para activar Intercom
    List<int> frame = [0xAA, 0x14, 0x12, 0x44, 0x32, 0xD9, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Intercom activado.");
    requestSystemStatus();
  } //FIN activateInter

  ///===HORN===
  // Alterna la bocina (Horn) enviando primero un frame de reset [0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF] y luego el frame principal [0xAA, 0x14, 0x09, 0x44, 0x0C, 0xA9, 0xFF], confirmando en consola.
  void toggleHorn() {
    // Enviar un comando neutro para restablecer el estado
    List<int> resetFrame = [0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF];
    sendCommand(resetFrame);

    // Luego enviar el comando deseado
    List<int> frame = [0xAA, 0x14, 0x09, 0x44, 0x0C, 0xA9, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Horn alternado después de reset.");

    requestSystemStatus();
  } //FIN toggleHorn

  ///===WAIL===
  // Activa el Wail enviando el frame [0xAA, 0x14, 0x10, 0x44, 0xF2, 0x78, 0xFF] por BLE y muestra confirmación en consola.
  void toggleWail() {
    // Enviar el protocolo del Wail
    List<int> frame = [0xAA, 0x14, 0x10, 0x44, 0xF2, 0x78, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Wail alternado.");

    requestSystemStatus();
  } //FIN toggleWail

  /// =================//
  /// FUNCION DE PTT //
  /// ==============//

  // Alterna el estado del PTT activando Bluetooth Classic y el micrófono mientras esté presionado, y al soltar, los desactiva y reconecta BLE automáticamente.
  Future<void> togglePTT() async {
    if (!isPTTActive) {
      if (connectedDevice == null) {
        debugPrint("❌ No hay dispositivo BLE conectado.");
        return;
      }

      // Paso 1: Enviar protocolo BLE para activar modo Audio Classic
      List<int> activateAudioMode = [0xAA, 0x14, 0x30, 0x44, 0xAB, 0xCD, 0xFF];
      await sendCommand(activateAudioMode);
      debugPrint("📡 Protocolo BT_PwAudio enviado");

      // Paso 2: Espera breve para que el hardware cambie a modo Classic
      await Future.delayed(const Duration(seconds: 2));

      // Paso 3: Conectar Classic sin escanear, usando MAC ya conocida
      String mac = connectedDevice!.remoteId.toString();
      await _connectClassicIfRemembered(mac);

      // Paso 4: Permisos de micrófono
      if (!await _requestMicrophonePermission()) return;

      // Paso 5: Activar transmisión de audio en vivo
      await _startLiveMicToClassic();

      // Paso 6: Enviar protocolo de activación PTT
      List<int> frame = [0xAA, 0x14, 0x11, 0x44, 0x32, 0x29, 0xFF];
      await sendCommand(frame);

      isPTTActive = true;
      debugPrint("🎙️ PTT ACTIVADO (audio en tiempo real)");
    } else {
      // Paso 1: Detener transmisión y cerrar conexión Classic
      await _stopLiveMicToClassic();
      await _deactivateBluetoothClassic();

      // Paso 2: Enviar protocolo de desactivación PTT
      List<int> frame = [0xAA, 0x14, 0x11, 0x44, 0x32, 0x29, 0xFF];
      await sendCommand(frame);

      isPTTActive = false;
      debugPrint("⛔ PTT DESACTIVADO");
    }

    requestSystemStatus(); // Consulta de batería al final
  }

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
          sampleRate: 8000, // <- MÁS COMPATIBLE
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
      final bondedDevices =
      await btClassic.FlutterBluetoothSerial.instance.getBondedDevices();

      final target = bondedDevices.firstWhere(
            (d) =>
        d.address == mac &&
            (d.name == 'BT_PWAudio' || d.name == 'BT_PWData'),
        orElse: () => throw Exception("⚠️ Dispositivo Classic no encontrado"),
      );

      if (classicConnection == null || !classicConnection!.isConnected) {
        classicConnection = await btClassic.BluetoothConnection.toAddress(mac);
        debugPrint("✅ Conexión Classic establecida con $mac");
      } else {
        debugPrint("🔵 Classic ya estaba conectado");
      }
    } catch (e) {
      debugPrint("❌ Error al conectar a Classic recordado: $e");
    }
  }


  Future<void> _connectClassicFromBonded(String bleMac) async {
    debugPrint("🔍 Buscando emparejado: $bleMac con nombre válido...");

    try {
      List<btClassic.BluetoothDevice> bondedDevices =
          await btClassic.FlutterBluetoothSerial.instance.getBondedDevices();

      final device = bondedDevices.firstWhere(
        (d) =>
            d.address == bleMac &&
            (d.name == 'BT_PWAudio' || d.name == 'BT_PWData'),
        orElse: () => throw Exception("Dispositivo emparejado no encontrado"),
      );

      if (classicConnection != null && classicConnection!.isConnected) {
        debugPrint('✅ Classic ya conectado.');
        return;
      }

      classicConnection = await btClassic.BluetoothConnection.toAddress(
        device.address,
      );

      debugPrint('✅ Conectado a ${device.name} (Classic)');
    } catch (e) {
      debugPrint("❌ Error al conectar Classic desde emparejados: $e");
    }
  }

  ///===FUNCIONES PARA FUNCION DE PTT===

  // Solicita permiso de micrófono y devuelve `true` si fue concedido, o `false` si fue denegado.
  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      debugPrint("🎤 Permiso de micrófono concedido.");
      return true;
    } else {
      debugPrint("❌ Permiso de micrófono denegado.");
      return false;
    }
  } //FIN _requestMicrophonePermission

  // Inicia la grabación de audio si no está activa, abre el recorder de Flutter Sound, crea un archivo temporal 'audio_ptt.aac' y graba en formato AAC ADTS.
  Future<void> _startMicrophone() async {
    try {
      if (!_recorder.isRecording) {
        await _recorder.openRecorder();

        final controller = StreamController<Uint8List>();

        controller.stream.listen((chunk) {
          debugPrint("🔊 Chunk de ${chunk.length} bytes");
          if (classicConnection?.isConnected == true) {
            classicConnection!.output.add(chunk);
            classicConnection!.output.allSent;
          }
        });


        await _recorder.startRecorder(
          codec: Codec.pcm16, // Ideal para transmisión cruda
          numChannels: 1, // Mono
          sampleRate: 8000, // Compatible con Classic BT
          toStream: controller.sink,
        );

        debugPrint("🎤 Micrófono activado y transmitiendo por Classic");
      }
    } catch (e) {
      debugPrint("❌ Error al iniciar micrófono en vivo: $e");
    }
  }

  // Detiene la grabacion si esta activa, cierra el recorder y muestra un mensaje en la consola.
  Future<void> _stopMicrophone() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
        await _recorder.closeRecorder();
        debugPrint("⛔ Micrófono detenido correctamente.");
      }
    } catch (e) {
      debugPrint("❌ Error al detener micrófono: $e");
    }
  }

  // Conecta el Bluetooth Classic a una MAC especifica si no esta ya conectado y la direccion ya no es valida
  Future<void> _activateBluetoothClassic(String bleMac) async {
    debugPrint(
      "🔍 Buscando dispositivo Classic emparejado con MAC: $bleMac...",
    );

    try {
      // 1. Obtener lista de dispositivos emparejados
      List<btClassic.BluetoothDevice> bondedDevices =
          await btClassic.FlutterBluetoothSerial.instance.getBondedDevices();

      // 2. Buscar dispositivo con misma MAC y nombre esperado
      final matchedDevice = bondedDevices.firstWhere(
        (device) =>
            device.address == bleMac &&
            (device.name == 'BT_PWAudio' || device.name == 'BT_PWData'),
        orElse:
            () =>
                throw Exception(
                  "No se encontró dispositivo emparejado que coincida.",
                ),
      );

      // 3. Verifica si ya está conectado
      if (classicConnection != null && classicConnection!.isConnected) {
        debugPrint('✅ Classic ya conectado.');
        return;
      }

      // 4. Conectar directamente
      classicConnection = await btClassic.BluetoothConnection.toAddress(
        matchedDevice.address,
      );
      debugPrint('✅ Conectado a ${matchedDevice.name} en modo Classic.');
    } catch (e) {
      debugPrint("❌ Error al conectar Classic: $e");
    }
  }

  // Cierra la conexión Bluetooth Classic si está activa y restablece classicConnection a null.
  Future<void> _deactivateBluetoothClassic() async {
    try {
      if (classicConnection != null && classicConnection!.isConnected) {
        await classicConnection!.close();
        debugPrint('⛔ Bluetooth Classic desconectado.');
      } else {
        debugPrint(
          '🔴 Bluetooth Classic ya está desactivado o nunca se conectó.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error desactivando Bluetooth Classic: $e');
    } finally {
      // Asegura que la referencia se limpie siempre, incluso tras un error
      classicConnection = null;
    }
  } //FIN _deactivateBluetoothClassic

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
  void disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      debugPrint("🔴 Dispositivo desconectado.");
      connectedDevice = null;
    }
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
} //FIN ControlController
