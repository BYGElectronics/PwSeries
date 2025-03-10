import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

class ControlController {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;

  /// Configurar dispositivo conectado
  void setDevice(BluetoothDevice device) async {
    connectedDevice = device;
    await _discoverServices();
  }

  /// Descubrir servicios y características BLE
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
          return;
        }
      }
    }
    debugPrint(
      "No se encontró característica de escritura en los servicios BLE.",
    );
  }

  /// Enviar Comando BLE al dispositivo conectado en formato ASCII
  Future<void> sendCommand(List<int> command) async {
    if (targetCharacteristic == null) {
      debugPrint("No hay característica de escritura disponible.");
      return;
    }
    if (connectedDevice == null) {
      debugPrint("No hay dispositivo BLE conectado.");
      return;
    }

    // Convertir cada byte a su representación ASCII antes de enviarlo
    String asciiCommand =
        command
            .map((e) => e.toRadixString(16).padLeft(2, '0'))
            .join('')
            .toUpperCase();
    List<int> asciiBytes = asciiCommand.codeUnits;

    try {
      await targetCharacteristic!.write(asciiBytes, withoutResponse: false);
      debugPrint(
        "Comando ASCII enviado a ${connectedDevice!.platformName}: $asciiCommand",
      );
    } catch (e) {
      debugPrint(
        "Error enviando comando ASCII a ${connectedDevice!.platformName}: $e",
      );
    }
  }

  /// Cálculo del CRC ModBus
  int calculateCRC(List<int> data) {
    int crc = 0xFFFF;
    for (var byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    // Asegurar que los bytes del CRC se envían en el orden correcto
    return ((crc & 0xFF) << 8) | ((crc >> 8) & 0xFF);
  }

  void testCRC() {
    List<int> testData = [0xAA, 0x14, 0x07, 0x44];
    int crc = calculateCRC(testData);
    debugPrint(
      "CRC esperado: CFC8, CRC calculado: ${crc.toRadixString(16).toUpperCase()}",
    );
  }

  /// Generador de Comandos con Conversión a ASCII
  List<int> buildCommand(List<int> data) {
    List<int> frame = [0xAA] + data;

    frame.add(0xFF);
    return frame;
  }

  /// Funciones de control con protocolos correctos
  void activateSiren() {
    List<int> frame = [0xAA, 0x14, 0x07, 0x44];

    // FORZAR EL CRC A `CFC8` SOLO PARA SIRENA
    frame.addAll([0xCF, 0xC8]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  void activateAux() {
    List<int> frame = [0xAA, 0x14, 0x08, 0x44];

    // FORZAR EL CRC A `CCF8` SOLO PARA AUXILIAR
    frame.addAll([0xCC, 0xF8]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  void deactivateWail() {
    sendCommand([0xAA, 0x14, 0x10, 0x00, 0x00, 0x00, 0xFF]);
    debugPrint("Wail desactivado.");
  }

  void deactivateInter() {
    sendCommand([0xAA, 0x14, 0x12, 0x00, 0x00, 0x00, 0xFF]);
    debugPrint("Intercom desactivado.");
  }

  void activateHorn() {
    List<int> frame = [0xAA, 0x14, 0x09, 0x44];

    // FORZAR EL CRC A `0CA9` SOLO PARA HORN
    frame.addAll([0x0C, 0xA9]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  void deactivateHorn() {
    List<int> frame = [
      0xAA,
      0x14,
      0x09,
      0x00,
    ]; // 0x00 para indicar desactivación

    // FORZAR EL CRC DE DESACTIVACIÓN (Ajustar si es necesario)
    frame.addAll([0x00, 0x00]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  void activateWail() {
    List<int> frame = [0xAA, 0x14, 0x10, 0x44];

    // FORZAR EL CRC A `F278` SOLO PARA WAIL
    frame.addAll([0xF2, 0x78]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  void activateInter() {
    List<int> frame = [0xAA, 0x14, 0x12, 0x44];

    // FORZAR EL CRC A `32D9` SOLO PARA INTER
    frame.addAll([0x32, 0xD9]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  void activatePTT() {
    List<int> frame = [0xAA, 0x14, 0x11, 0x44];

    // FORZAR EL CRC A `3229` SOLO PARA PTT
    frame.addAll([0x32, 0x29]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  void deactivatePTT() {
    List<int> frame = [
      0xAA,
      0x14,
      0x11,
      0x00,
    ]; // 0x00 para indicar desactivación

    // FORZAR EL CRC DE DESACTIVACIÓN (AJUSTA SI ES NECESARIO)
    frame.addAll([0x00, 0x00]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  /// Solicitar Estado del Sistema
  void requestSystemStatus() {
    List<int> frame = [0xAA, 0x14, 0x18, 0x44];

    // FORZAR EL CRC A `30F9` SOLO PARA SOLICITUD DE ESTADO DEL SISTEMA
    frame.addAll([0x30, 0xF9]);

    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  }

  /// Escuchar Respuestas del Hardware en ASCII
  void listenForResponses() {
    if (targetCharacteristic != null) {
      targetCharacteristic!.setNotifyValue(true);
      targetCharacteristic!.value.listen((response) {
        String hexResponse =
            response
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(' ')
                .toUpperCase();
        debugPrint("Respuesta del hardware: $hexResponse");

        // Validar respuesta
        if (response.length >= 6) {
          String command = hexResponse.substring(3, 5); // Extrae el comando
          String crc = hexResponse.substring(
            hexResponse.length - 4,
          ); // Extrae el CRC

          if (command == "18" && crc == "3733") {
            debugPrint("Estado del sistema: DataOK");
          } else if (command == "22" && crc == "D45A") {
            debugPrint("Estado del sistema: DataFail");
          } else if (command == "33" && crc == "B8CA") {
            debugPrint("Estado del sistema: CRC error");
          } else {
            debugPrint("Estado desconocido: $hexResponse");
          }
        }
      });
    }
  }

  /// Desconectar Dispositivo
  void disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      debugPrint("Dispositivo desconectado.");
      connectedDevice = null;
    }
  }
}