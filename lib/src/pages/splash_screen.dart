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

    // 2️⃣ Esperamos unos segundos para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 3️⃣ Revisamos dispositivos Classic emparejados
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
      // ❌ No hay BTPW emparejado, vamos a configuración inicial
      Navigator.pushReplacementNamed(context, 'home');
      return;
    }

    // 4️⃣ Hay un BTPW emparejado: intentamos conexión BLE (si no sale, igual vamos a control)
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

    // 1️⃣ Escaneo BLE buscando la MAC
    final subscription = ble.FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (result.device.remoteId.str == macAddress) {
          completer.complete(result.device);
          break;
        }
      }
    });

    try {
      await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      bleDevice = await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      bleDevice = null;
    }

    await ble.FlutterBluePlus.stopScan();
    await subscription.cancel();

    if (bleDevice != null) {
      try {
        // 2️⃣ Conexión BLE
        await bleDevice.connect(timeout: const Duration(seconds: 5));
        await bleDevice.discoverServices();

        // 3️⃣ Buscamos la característica 'ff01'
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
          // 4️⃣ Configuramos el controlador global
          final ctrl = Provider.of<ControlController>(context, listen: false);
          ctrl.setDevice(bleDevice);
          ctrl.setWriteCharacteristic(writeChar);
          // (Opcional) aquí podrías iniciar un monitoreo periódico dentro de ControlController
        }
      } catch (e) {
        debugPrint("⚠️ Error en conexión BLE automática: $e");
      }
    }

    // 5️⃣ Finalmente, navegamos a la pantalla de control (con BLE conectado o no)
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