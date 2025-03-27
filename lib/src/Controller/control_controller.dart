///================================///
///     IMPORTACIONES NECESARIAS   ///
///================================///
library;

import 'dart:async'; // Proporciona herramientas para trabajar con programación asíncrona, como Future y Stream.
import 'dart:convert';
import 'package:flutter/material.dart'; // Framework principal de Flutter para construir interfaces de usuario.
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as Ble;
import 'package:permission_handler/permission_handler.dart'; // Maneja permisos en tiempo de ejecución para acceder a hardware y funciones del dispositivo.
import 'package:flutter_sound/flutter_sound.dart'; // Biblioteca para grabación y reproducción de audio.
import 'package:path_provider/path_provider.dart'; // Permite acceder a directorios específicos del sistema de archivos, como caché y documentos.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Maneja la comunicación con dispositivos Bluetooth Low Energy (BLE).
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as btClassic; // Biblioteca para manejar Bluetooth Classic, utilizado para conexiones seriales.
import 'package:get/get.dart';

enum BatteryLevel { full, medium, low }

class ControlController extends ChangeNotifier {
  BluetoothDevice?
  connectedDevice; //Dispositivo BLE actualmente conectado. | Se usará para realizar operaciones de comunicación con el hardware.
  btClassic.BluetoothConnection?
  classicConnection; //Conexión Bluetooth Classic. | Se usará para realizar operaciones de comunicación serial.
  BluetoothCharacteristic?
  targetCharacteristic; //Característica BLE de escritura. | Se usa para enviar comandos al dispositivo BLE.
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(); //Grabador de audio para manejar la funcionalidad de PTT (Push-to-Talk). | Permite iniciar y detener la grabación de audio.
  bool isPTTActive =
      false; //Estado del botón PTT. | Indica si el PTT está activado o desactivado.
  String batteryImagePath = 'assets/images/Estados/battery_medium.png';
  Timer? _batteryStatusTimer;
  Timer? _batteryMonitorTimer;
  late BluetoothDevice _device;
  BatteryLevel batteryLevel = BatteryLevel.full;

  late Ble.BluetoothService _service;
  late Ble.BluetoothCharacteristic _characteristic;
  late BluetoothCharacteristic _writeCharacteristic;

  // Estado del botón PTT (reactivo)
  RxBool isPttActive = false.obs;

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
    _batteryMonitorTimer = Timer.periodic(Duration(seconds: 50), (_) {
      requestSystemStatus();
    });
  }

  void stopBatteryStatusMonitoring() {
    _batteryMonitorTimer?.cancel();
    _batteryMonitorTimer = null;
  }

  /// =============================================//
  /// DESCUBIR LOS SERVICIOS Y CARACTERISTICAS BLE //
  /// ============================================//

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

          // 🟡 Enviar protocolo de estado del sistema para obtener nivel de batería
          List<int> batteryStatusCommand = ascii.encode("AA14184430F9FF");
          await characteristic.write(
            batteryStatusCommand,
            withoutResponse: true,
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
      // Escribe esos bytes en la característica BLE.
      await targetCharacteristic!.write(asciiBytes, withoutResponse: false);

      // Log de confirmación.
      debugPrint(
        "Comando ASCII enviado a ${connectedDevice!.platformName}: $asciiCommand",
      );
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
  } //FIN activateSiren

  ///===AUXILIAR===
  // Activa la salida Auxiliar enviando el frame [0xAA, 0x14, 0x08, 0x44, 0xCC, 0xF8, 0xFF] por BLE y muestra confirmación en consola.
  void activateAux() {
    // Enviar el protocolo para activar Auxiliar
    List<int> frame = [0xAA, 0x14, 0x08, 0x44, 0xCC, 0xF8, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Auxiliar activado.");
  } //FIN activateAux

  ///===INTERCOMUNICADOR===
  // Activa el Intercomunicador enviando el frame [0xAA, 0x14, 0x12, 0x44, 0x32, 0xD9, 0xFF] por BLE y muestra confirmación en consola.
  void activateInter() {
    // Enviar el protocolo para activar Intercom
    List<int> frame = [0xAA, 0x14, 0x12, 0x44, 0x32, 0xD9, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Intercom activado.");
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
  } //FIN toggleHorn

  ///===WAIL===
  // Activa el Wail enviando el frame [0xAA, 0x14, 0x10, 0x44, 0xF2, 0x78, 0xFF] por BLE y muestra confirmación en consola.
  void toggleWail() {
    // Enviar el protocolo del Wail
    List<int> frame = [0xAA, 0x14, 0x10, 0x44, 0xF2, 0x78, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Wail alternado.");
  } //FIN toggleWail

  /// =================//
  /// FUNCION DE PTT //
  /// ==============//

  // Alterna el estado del PTT activando Bluetooth Classic y el micrófono mientras esté presionado, y al soltar, los desactiva y reconecta BLE automáticamente.
  Future<void> togglePTT() async {
    if (!isPTTActive) {
      // Paso 1: Verifica conexión BLE
      if (connectedDevice == null) {
        debugPrint("❌ No hay dispositivo BLE conectado.");
        return;
      }

      // Paso 2: Enviar protocolo para cambiar al modo BT_PwAudio
      List<int> activateClassicModeFrame = [
        0xAA,
        0x14,
        0x30,
        0x44,
        0xAB,
        0xCD,
        0xFF,
      ]; // Puedes ajustar el CRC si tienes el correcto
      await sendCommand(activateClassicModeFrame);
      debugPrint("📡 Protocolo para activar BT_PwAudio enviado por BLE.");

      // Paso 3: Esperar breve delay para cambio de perfil
      await Future.delayed(Duration(seconds: 2));

      // Paso 4: Desconectar BLE temporalmente
      await connectedDevice!.disconnect();
      debugPrint("🔴 BLE desconectado temporalmente.");

      // Paso 5: Obtener la MAC y conectar Classic
      String mac = connectedDevice!.remoteId.toString();
      await _activateBluetoothClassic(mac);

      // Paso 6: Pedir permiso de micrófono
      if (!await _requestMicrophonePermission()) {
        debugPrint("🚫 Permiso de micrófono denegado.");
        return;
      }

      // Paso 7: Iniciar grabación
      await _startMicrophone();

      // Paso 8: Enviar protocolo de PTT activado
      List<int> frame = [0xAA, 0x14, 0x11, 0x44, 0x32, 0x29, 0xFF];
      await sendCommand(frame);

      isPTTActive = true;
      debugPrint("🎙️ PTT activado, transmitiendo...");
    } else {
      // Paso 1: Detener grabación y Classic
      await _stopMicrophone();
      await _deactivateBluetoothClassic();

      // Paso 2: Reconectar BLE
      if (connectedDevice != null) {
        await connectedDevice!.connect();
        await _discoverServices();
        debugPrint("🔵 BLE reconectado.");
      }

      // Paso 3: Enviar protocolo para desactivar PTT
      List<int> frame = [
        0xAA,
        0x14,
        0x11,
        0x44,
        0x32,
        0x29,
        0xFF,
      ]; // mismo frame que activa también desactiva
      await sendCommand(frame);

      isPTTActive = false;
      debugPrint("⛔ PTT desactivado.");
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
        // Abre el grabador de audio
        await _recorder.openRecorder();

        // Obtiene un directorio temporal en el dispositivo
        final tempDir = await getTemporaryDirectory();
        // Construye la ruta completa del archivo de audio temporal
        final tempPath = '${tempDir.path}/audio_ptt.aac';

        // Inicia la grabación y especifica el archivo de salida y el códec
        await _recorder.startRecorder(toFile: tempPath, codec: Codec.aacADTS);

        debugPrint("🎤 Micrófono activado y grabando audio...");
      }
    } catch (e) {
      debugPrint("❌ Error al activar el micrófono: $e");
    }
  } //FIN _startMicrophone

  // Detiene la grabacion si esta activa, cierra el recorder y muestra un mensaje en la consola.
  Future<void> _stopMicrophone() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
        await _recorder.closeRecorder();
        debugPrint("⛔ Micrófono detenido correctamente.");
      }
    } catch (e) {
      debugPrint("❌ Error al detener el micrófono: $e");
    }
  } //FIN _stopMicrophone

  // Conecta el Bluetooth Classic a una MAC especifica si no esta ya conectado y la direccion ya no es valida
  Future<void> _activateBluetoothClassic(String address) async {
    debugPrint("🔄 Intentando conectar Bluetooth Classic a $address...");
    try {
      if (address.isEmpty) {
        debugPrint('❌ Dirección MAC no disponible.');
        return;
      }

      // Si no está conectado aún, intenta la conexión usando la librería
      if (classicConnection == null || !classicConnection!.isConnected) {
        classicConnection = await btClassic.BluetoothConnection.toAddress(
          address,
        );
        debugPrint('✅ Bluetooth Classic conectado a $address');
      } else {
        debugPrint('🔵 Bluetooth Classic ya está activo.');
      }
    } catch (e) {
      debugPrint('❌ Error activando Bluetooth Classic: $e');
    }
  } //FIN _activateBluetoothClassic

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
  }

  /// ===Cambiar Tono de Horn===
  void changeHornTone() {
    List<int> frame = [0xAA, 0x14, 0x25, 0x44];
    frame.addAll([0xB7, 0x68]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
  }

  /// ===Sincronizar / Desincronizar luces con sirena===
  void syncLightsWithSiren() {
    List<int> frame = [0xAA, 0x14, 0x26, 0x44];
    frame.addAll([0xB7, 0x98]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
  }

  /// ===Autoajuste PA===
  void autoAdjustPA() {
    List<int> frame = [0xAA, 0x14, 0x27, 0x44];
    frame.addAll([0x77, 0xC9]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);

    debugPrint("⏳ Esperar 30 segundos para el autoajuste PA.");
  }

  /// ===Desconectar Dispositivo===
  void disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      debugPrint("🔴 Dispositivo desconectado.");
      connectedDevice = null;
    }
  }

  // Escucha notificaciones de una característica BLE y procesa las respuestas para detectar el estado de la batería.
  void listenForResponses(BluetoothCharacteristic characteristic) {
    // Habilita las notificaciones para la característica BLE especificada.
    characteristic.setNotifyValue(true);

    // Se suscribe a los cambios de valor (respuestas entrantes del dispositivo).
    characteristic.value.listen((response) {
      // Convierte la respuesta a formato hexadecimal para debugging.
      String hexResponse =
          response
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(' ')
              .toUpperCase();
      debugPrint("📩 Respuesta HEX recibida: $hexResponse");

      // Verifica si la respuesta es una trama válida del estado del sistema.
      if (response.length >= 7 &&
          response[0] == 0xAA && // Inicio de trama
          response[1] == 0x18 && // Dirección o categoría de estado
          response[2] == 0x18 && // Comando de estado del sistema
          response[3] == 0x55) {
        // Indicador de respuesta válida

        // Extrae el byte que representa el nivel de batería.
        int batteryByte = response[5];

        // Asigna el estado de batería según el valor del byte recibido.
        switch (batteryByte) {
          case 0x14:
            debugPrint("🔋 Batería Completa / Carro encendido");
            batteryLevel = BatteryLevel.full;
            break;
          case 0x15:
            debugPrint("🟡 Batería Media / Carro apagado");
            batteryLevel = BatteryLevel.medium;
            break;
          case 0x16:
            debugPrint("🔴 Batería Baja");
            batteryLevel = BatteryLevel.low;
            break;
          default:
            // Si el byte no coincide con ningún valor esperado, lo muestra como desconocido.
            debugPrint(
              "❓ Estado de batería desconocido: ${batteryByte.toRadixString(16)}",
            );
        }
      } else {
        // Si la trama no es válida o no está relacionada con el estado de batería, se notifica.
        debugPrint(
          "❓ Trama no válida o no relacionada al estado de batería: $hexResponse",
        );
      }

      // Notifica a los listeners para actualizar la UI si se usa Provider, Riverpod, etc.
      notifyListeners();
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
