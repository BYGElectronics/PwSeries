// lib/src/pages/splash_screen.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

// Bluetooth Classic
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as btClassic
    show BluetoothConnection;

// Bluetooth LE
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/control_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciarAplicacion();
  }

  Future<void> _iniciarAplicacion() async {
    // 1️⃣ Permisos de Bluetooth y ubicación
    await _solicitarPermisos();

    // 2️⃣ Asegurar Bluetooth Classic ON (Android)
    if (Platform.isAndroid) {
      final state = await FlutterBluetoothSerial.instance.state;
      if (state != BluetoothState.STATE_ON) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }
    }

    // 3️⃣ Asegurar Bluetooth LE ON
    if (!await ble.FlutterBluePlus.isOn) {
      await ble.FlutterBluePlus.turnOn();
    }

    // 4️⃣ Mostrar splash 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 5️⃣ Buscar dispositivo emparejado “BTPW”
    BluetoothDevice? paired;
    if (Platform.isAndroid) {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (var d in bonded) {
        if ((d.name ?? '').toLowerCase().contains('btpw')) {
          paired = d;
          break;
        }
      }
    }

    if (paired == null) {
      // ❌ No hay dispositivo BTPW → a /home
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // 6️⃣ Intentar conectar por Classic con retries
    await FlutterBluetoothSerial.instance.cancelDiscovery();
    await Future.delayed(const Duration(milliseconds: 500));

    btClassic.BluetoothConnection? classicConn;
    for (int intento = 1; intento <= 3; intento++) {
      try {
        classicConn = await btClassic.BluetoothConnection.toAddress(
          paired.address,
        ).timeout(const Duration(seconds: 10));
        debugPrint('✅ Classic conectado (intento $intento)');
        break;
      } catch (e) {
        debugPrint('⚠️ Falló conexión Classic (intento $intento): $e');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (classicConn != null) {
      // 7️⃣ Guardar la conexión en el controlador
      final ctrl = Provider.of<ControlController>(context, listen: false);
      ctrl.classicConnection = classicConn;
      ctrl.connectedClassicDevice = paired;
    } else {
      debugPrint('❌ No se pudo conectar Classic tras 3 intentos');
    }

    // 8️⃣ Seguir con BLE
    await _conectarAutomaticamenteBLE(paired.address);
  }

  Future<void> _solicitarPermisos() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  Future<void> _conectarAutomaticamenteBLE(String macAddress) async {
    ble.BluetoothDevice? bleDevice;
    final completer = Completer<ble.BluetoothDevice>();
    final sub = ble.FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (r.device.remoteId.str.toLowerCase() == macAddress.toLowerCase()) {
          completer.complete(r.device);
          break;
        }
      }
    });

    try {
      await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      bleDevice = await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      bleDevice = null;
    } finally {
      await ble.FlutterBluePlus.stopScan();
      await sub.cancel();
    }

    if (bleDevice != null) {
      try {
        await bleDevice.connect(timeout: const Duration(seconds: 5));
        await bleDevice.discoverServices();

        ble.BluetoothCharacteristic? writeChar;
        for (var svc in bleDevice.servicesList) {
          for (var ch in svc.characteristics) {
            if (ch.uuid.toString().toLowerCase().contains('ff01')) {
              writeChar = ch;
              break;
            }
          }
          if (writeChar != null) break;
        }

        if (writeChar != null) {
          final ctrl = Provider.of<ControlController>(context, listen: false);
          ctrl.setDevice(bleDevice);
          ctrl.setWriteCharacteristic(writeChar);
          ctrl.startBatteryStatusMonitoring();
          ctrl.requestSystemStatus();
        }
      } catch (e) {
        debugPrint("⚠️ Error en BLE automática: $e");
      }
    }

    // 9️⃣ Ir a pantalla de control (con o sin BLE)
    Navigator.pushReplacementNamed(
      context,
      '/control',
      arguments: {'device': bleDevice},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/img/splashScreen/splashScreen.png",
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder:
              (ctx, error, stack) => Container(
                color: Colors.black,
                child: const Icon(Icons.error, color: Colors.red, size: 50),
              ),
        ),
      ),
    );
  }
}
