import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';

class ControlController {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;

  bool isConnected = false; // Estado de conexión

  /// Configurar dispositivo conectado
  void setDevice(BluetoothDevice device) async {
    connectedDevice = device;
    isConnected = true;
    await _discoverServices();
  }

  /// Descubrir servicios y características BLE
  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;
    List<BluetoothService> services = await connectedDevice!.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        debugPrint("🔍 Característica encontrada: ${characteristic.uuid}");
        if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
          targetCharacteristic = characteristic;
          debugPrint("✅ Característica de escritura seleccionada: ${characteristic.uuid}");
          enableNotifications();
          return;
        }
      }
    }
    debugPrint("⚠️ No se encontró característica de escritura en los servicios BLE.");
  }

  /// **Enviar Comando BLE** con delay y ajuste de escritura
  Future<void> sendCommand(List<int> command) async {
    if (targetCharacteristic == null) {
      debugPrint("❌ No hay característica de escritura disponible.");
      return;
    }
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Delay para estabilidad
      bool useWithoutResponse = targetCharacteristic!.properties.writeWithoutResponse;
      await targetCharacteristic!.write(command, withoutResponse: useWithoutResponse);
      debugPrint("📡 Comando enviado: ${command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}");
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

  /// 🔊 **Activar funciones del hardware con comandos BLE**
  void activateSiren() {
    sendCommand(buildCommand([0x14, 0x07, 0x44]));
  }

  void activateAux() {
    sendCommand(buildCommand([0x14, 0x08, 0x44]));
  }

  void activateHorn() {
    sendCommand(buildCommand([0x14, 0x09, 0x44]));
  }

  void activateInter() {
    sendCommand(buildCommand([0x14, 0x10, 0x44]));
  }

  void activatePTT() {
    sendCommand(buildCommand([0x14, 0x12, 0x44]));
  }

  void activateWail() {
    sendCommand(buildCommand([0x14, 0x11, 0x44]));
  }

  /// 🔄 **Solicitar estado del sistema**
  void requestSystemStatus() {
    sendCommand(buildCommand([0x14, 0x18, 0x44]));
  }

  /// **Leer respuesta del hardware (Notificaciones BLE)**
  void enableNotifications() {
    if (targetCharacteristic != null && targetCharacteristic!.properties.notify) {
      targetCharacteristic!.setNotifyValue(true);
      targetCharacteristic!.value.listen((response) {
        try {
          String hexResponse = response.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          debugPrint("📡 Respuesta del hardware en HEX: $hexResponse");
        } catch (e) {
          debugPrint("⚠️ Error procesando respuesta del hardware: $e");
        }
      });
    } else {
      debugPrint("⚠️ La característica no soporta notificaciones.");
    }
  }

  /// **Desconectar Dispositivo**
  void disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      debugPrint("🔌 Dispositivo desconectado.");
      connectedDevice = null;
      isConnected = false; // Habilitar botón de búsqueda nuevamente
    }
  }
}