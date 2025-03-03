import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

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
        debugPrint("🔍 Característica encontrada: ${characteristic.uuid}");
        if (characteristic.properties.write) {
          targetCharacteristic = characteristic;
          debugPrint("✅ Característica de escritura seleccionada: ${characteristic.uuid}");
          return;
        }
      }
    }
    debugPrint("⚠️ No se encontró característica de escritura en los servicios BLE.");
  }

  /// **Enviar Comando BLE**
  Future<void> sendCommand(List<int> command) async {
    if (targetCharacteristic == null) {
      debugPrint("❌ No hay característica de escritura disponible.");
      return;
    }
    try {
      await targetCharacteristic!.write(command, withoutResponse: false);
      debugPrint("📡 Comando enviado: ${command.map((e) => e.toRadixString(16)).join(' ')}");
    } catch (e) {
      debugPrint("❌ Error enviando comando: $e");
    }
  }

  /// **Cálculo del CRC ModBus**
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
    return crc;
  }

  /// **Generador de Comandos**
  List<int> buildCommand(List<int> data) {
    List<int> frame = [0xAA] + data;
    int crc = calculateCRC(frame);
    frame.addAll([(crc >> 8) & 0xFF, crc & 0xFF]); // CRC en 2 bytes
    frame.add(0xFF);
    return frame;
  }

  /// **Funciones de botones con protocolos**
  void activateSiren() {
    sendCommand(buildCommand([0x14, 0x07, 0x44]));
  }

  void activateAux() {
    sendCommand(buildCommand([0x14, 0x08, 0x44]));
  }

  void activateHorn() {
    sendCommand(buildCommand([0x14, 0x09, 0x44]));
  }

  void activateWail() {
    sendCommand(buildCommand([0x14, 0x10, 0x44]));
  }

  void activateInter() {
    sendCommand(buildCommand([0x14, 0x12, 0x44]));
  }

  void activatePTT() {
    sendCommand(buildCommand([0x14, 0x11, 0x44]));
  }

  /// **Solicitar Estado del Sistema**
  void requestSystemStatus() {
    sendCommand(buildCommand([0x14, 0x18, 0x44]));
  }

  /// **Desconectar Dispositivo**
  void disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      debugPrint("🔌 Dispositivo desconectado.");
      connectedDevice = null;
    }
  }
}
