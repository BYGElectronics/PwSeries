// lib/src/pages/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
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
    // 1️⃣ Pedimos permisos de Bluetooth y ubicación
    await _solicitarPermisos();

    // 2️⃣ Nos aseguramos de que el Bluetooth clásico esté encendido
    final classicState = await FlutterBluetoothSerial.instance.state;
    if (classicState != BluetoothState.STATE_ON) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }

    // 3️⃣ Nos aseguramos de que el Bluetooth LE esté encendido
    final isBleOn = await ble.FlutterBluePlus.isOn;
    if (!isBleOn) {
      await ble.FlutterBluePlus.turnOn();
    }

    // 4️⃣ Pausa breve para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 5️⃣ Revisamos dispositivos Classic emparejados
    List<BluetoothDevice> bonded =
    await FlutterBluetoothSerial.instance.getBondedDevices();
    BluetoothDevice? paired;
    for (var d in bonded) {
      if (d.name?.toLowerCase().contains('btpw') ?? false) {
        paired = d;
        break;
      }
    }

    if (paired == null) {
      // ❌ No hay dispositivo Pw emparejado: vamos a home/configuración
      Navigator.pushReplacementNamed(context, 'home');
      return;
    }

    // 6️⃣ Hay un Pw emparejado: intentamos conexión BLE
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

    // 1️⃣ Escaneo BLE buscando la dirección MAC
    final subscription =
    ble.FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (result.device.remoteId.str == macAddress) {
          completer.complete(result.device);
          break;
        }
      }
    });

    try {
      await ble.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );
      bleDevice = await completer.future
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      bleDevice = null;
    } finally {
      await ble.FlutterBluePlus.stopScan();
      await subscription.cancel();
    }

    if (bleDevice != null) {
      try {
        // 2️⃣ Conexión BLE
        await bleDevice.connect(timeout: const Duration(seconds: 5));
        // 3️⃣ Descubrimos servicios
        await bleDevice.discoverServices();

        // 4️⃣ Buscamos la característica 'ff01'
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
          // 5️⃣ Configuramos el controlador con BLE
          final ctrl =
          Provider.of<ControlController>(context, listen: false);
          ctrl.setDevice(bleDevice);
          ctrl.setWriteCharacteristic(writeChar);
          // Opcional: iniciar monitoreo de batería aquí
          ctrl.startBatteryStatusMonitoring();
          ctrl.requestSystemStatus();
        }
      } catch (e) {
        debugPrint("⚠️ Error en conexión BLE automática: $e");
      }
    }

    // 6️⃣ Navegamos a la pantalla de control (con o sin BLE)
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
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.black,
              child: const Icon(Icons.error, color: Colors.red, size: 50),
            );
          },
        ),
      ),
    );
  }
}
