import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';

import '../pages/control_screen.dart';

class HomeController {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  final ValueNotifier<List<ScanResult>> bleDevices = ValueNotifier([]);
  final ValueNotifier<List<ScanResult>> filteredDevices = ValueNotifier([]);
  final ValueNotifier<String?> connectedDeviceName = ValueNotifier(null);
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  BluetoothDevice? connectedDevice;

  HomeController() {
    _monitorConnectionStatus();
  }

  /// 🔄 **Solicitar permisos necesarios**
  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  /// ✅ **Activar Bluetooth**
  Future<void> enableBluetooth() async {
    try {
      bool isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        await FlutterBluePlus.turnOn();
        debugPrint("✅ Bluetooth activado.");
      } else {
        debugPrint("⚠️ Bluetooth ya estaba activado.");
      }
    } catch (e) {
      debugPrint("❌ Error al activar Bluetooth: $e");
    }
  }

  /// 🔍 **Escanear dispositivos BLE y filtrar `BT_PwData` y `BT_PwAudio`**
  Future<void> searchDevices() async {
    await requestPermissions();

    bleDevices.value.clear();
    filteredDevices.value.clear();
    debugPrint("📡 Iniciando escaneo de dispositivos BLE...");

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      bleDevices.value = results;
      List<ScanResult> validDevices = results.where((r) {
        String deviceName = r.device.platformName;
        return deviceName.contains("BT_PwData") || deviceName.contains("BT_PwAudio");
      }).toList();

      filteredDevices.value = validDevices;
      debugPrint("✅ Dispositivos filtrados: ${filteredDevices.value.length}");
    });

    await Future.delayed(const Duration(seconds: 10));
    FlutterBluePlus.stopScan();
    debugPrint("⏹ Escaneo finalizado.");
  }

  /// 🔄 **Conectar a un dispositivo filtrado**
  Future<void> connectToDevice(BluetoothDevice device) async {
    debugPrint("🔄 Intentando conectar a ${device.platformName}...");

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice = device;
      connectedDeviceName.value = device.platformName;
      isConnected.value = true;
      debugPrint("✅ Conectado correctamente a ${device.platformName}");

      _monitorConnectionStatus();
    } catch (e) {
      debugPrint("❌ Error en la conexión: $e");
    }
  }

  /// 🔌 **Desconectar el dispositivo**
  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      connectedDeviceName.value = null;
      isConnected.value = false;
      debugPrint("🔌 Dispositivo desconectado.");
    }
  }

  /// 📡 **Monitor de conexión y desconexión**
  void _monitorConnectionStatus() {
    if (connectedDevice != null) {
      connectedDevice!.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevice = null;
          connectedDeviceName.value = null;
          isConnected.value = false;
          debugPrint("🚨 Dispositivo desconectado automáticamente.");
        }
      });
    }
  }

  /// 📍 **Navegar al Control Virtual**
  void navigateToControl(BuildContext context) {
    if (connectedDevice != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ControlScreen(connectedDevice: connectedDevice!),
        ),
      );
    } else {
      debugPrint("❌ No hay un dispositivo conectado.");
    }
  }


}
