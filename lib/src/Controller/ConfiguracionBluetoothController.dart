// lib/src/Controller/ConfiguracionBluetoothController.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';

import 'control_controller.dart';

class DeviceData {
  final String name;
  final String address;
  final bool isBLE;
  int missedScans;

  DeviceData({
    required this.name,
    required this.address,
    required this.isBLE,
    this.missedScans = 0,
  });
}

class ConfiguracionBluetoothController extends ChangeNotifier {
  List<DeviceData> dispositivosEncontrados = [];
  StreamSubscription<List<ble.ScanResult>>? _scanSubscription;
  Timer? _scanTimer;

  /// PIN que ve el usuario (máscara)
  final String pinMask = "9459";

  /// Clave real para emparejar Classic (nunca en UI)
  final String pinReal = "1865";

  String pinIngresado = "";
  DeviceData? selectedDevice;
  DeviceData? dispositivoConectando;

  ConfiguracionBluetoothController() {
    _inicializarBluetooth();
  }

  Future<void> _inicializarBluetooth() async {
    if (!Platform.isAndroid) return;

    // 1) Asegurar Bluetooth ON
    final estado = await FlutterBluetoothSerial.instance.state;
    if (estado != BluetoothState.STATE_ON) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }

    // 2) Permisos Classic
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
      if (await Permission.bluetoothConnect.isDenied) return;
    }

    // 3) Auto-detectar primer Classic emparejado “btpw”
    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    for (var d in bonded) {
      if ((d.name ?? '').toLowerCase().contains("btpw")) {
        final auto = DeviceData(
          name: d.name!,
          address: d.address,
          isBLE: false,
        );
        dispositivosEncontrados.add(auto);
        if (dispositivosEncontrados.length == 1) {
          selectedDevice = auto;
        }
        break;
      }
    }
    notifyListeners();

    // 4) Iniciar escaneo periódico
    _iniciarEscaneoPeriodico();
  }

  void togglePinVisibility(DeviceData device) {
    if (selectedDevice?.address == device.address) {
      selectedDevice = null;
      pinIngresado = "";
    } else {
      selectedDevice = device;
      pinIngresado = "";
    }
    notifyListeners();
  }

  void agregarDigito(String d) {
    if (pinIngresado.length < 6) {
      pinIngresado += d;
      notifyListeners();
    }
  }

  void borrarPin() {
    if (pinIngresado.isNotEmpty) {
      pinIngresado = pinIngresado.substring(0, pinIngresado.length - 1);
      notifyListeners();
    }
  }

  Future<void> enviarPinYConectar(BuildContext context) async {
    if (selectedDevice == null) return;

    // 1) Validar PIN máscara
    if (pinIngresado != pinMask) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("PIN incorrecto")));
      return;
    }

    final mac = selectedDevice!.address;
    dispositivoConectando = selectedDevice;
    notifyListeners();

    // 2) Pair Classic
    final okBond = await _pairClassic(mac);
    if (!okBond) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error emparejando Classic")));
      return;
    }

    // 3) Conectar Classic
    await _connectClassic(mac);

    // 4) Conectar BLE
    await _conectarBLE(context, mac);
  }

  Future<bool> _pairClassic(String mac) async {
    try {
      final success = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
        mac,
        pin: pinReal,
      );
      return success == true;
    } catch (e) {
      debugPrint("❌ Error bond Classic: $e");
      return false;
    }
  }

  Future<void> _connectClassic(String mac) async {
    try {
      final conn = await BluetoothConnection.toAddress(mac);
      debugPrint("✅ Classic conectado a $mac");
      // guarda conn si lo necesitas
    } catch (e) {
      debugPrint("❌ Error conectando Classic: $e");
    }
  }

  Future<void> _conectarBLE(BuildContext context, String macAddress) async {
    ble.BluetoothDevice? deviceBLE;
    try {
      await ble.FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();

      final completer = Completer<ble.BluetoothDevice>();
      _scanSubscription =
          ble.FlutterBluePlus.scanResults.listen((results) {
            for (var r in results) {
              if (r.device.remoteId.id.toLowerCase() ==
                  macAddress.toLowerCase()) {
                completer.complete(r.device);
                break;
              }
            }
          });

      await ble.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );
      deviceBLE = await completer.future.timeout(
        const Duration(seconds: 5),
      );

      await ble.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();

      if (deviceBLE == null) {
        throw Exception("No se encontró BLE $macAddress");
      }

      await deviceBLE.connect(timeout: const Duration(seconds: 10));
      debugPrint("✅ BLE conectado a ${deviceBLE.remoteId.id}");

      await deviceBLE.discoverServices();
      ble.BluetoothCharacteristic? writeChar;
      for (var svc in deviceBLE.servicesList) {
        for (var ch in svc.characteristics) {
          if (ch.uuid.toString().toLowerCase().contains("ff01")) {
            writeChar = ch;
            break;
          }
        }
        if (writeChar != null) break;
      }
      if (writeChar == null) {
        throw Exception("Característica ff01 no encontrada");
      }

      final ctrl = ControlController();
      ctrl.setDevice(deviceBLE);
      ctrl.setWriteCharacteristic(writeChar);

      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/splash_confirmacion',
          arguments: {
            'device': deviceBLE,
            'controller': ctrl,
          },
        );
      }
    } catch (e) {
      debugPrint("❌ Error en _conectarBLE: $e");
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/splash_denegate');
      }
    }
  }

  void _iniciarEscaneoPeriodico() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _escanearYActualizarDispositivos();
    });
    _escanearYActualizarDispositivos();
  }

  Future<void> _escanearYActualizarDispositivos() async {
    if (!await Permission.bluetoothScan.isGranted) return;

    final nuevos = <DeviceData>[];

    // Classic emparejados
    if (Platform.isAndroid) {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      nuevos.addAll(bonded
          .where((d) =>
          (d.name ?? "").toLowerCase().contains("btpw"))
          .map((d) => DeviceData(
        name: d.name!,
        address: d.address,
        isBLE: false,
      )));
    }

    // BLE
    await ble.FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    final encontradosBLE = <DeviceData>[];
    _scanSubscription =
        ble.FlutterBluePlus.scanResults.listen((results) {
          for (var r in results) {
            final name = r.device.name;
            final id = r.device.remoteId.id;
            if (name.toLowerCase().contains("btpw") &&
                !encontradosBLE.any((e) => e.address == id)) {
              encontradosBLE.add(
                DeviceData(name: name, address: id, isBLE: true),
              );
            }
          }
        });
    await ble.FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );
    await Future.delayed(const Duration(seconds: 5));
    await ble.FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    nuevos.addAll(encontradosBLE);

    // Actualizar lista
    final direcciones = nuevos.map((d) => d.address).toSet();
    for (var old in dispositivosEncontrados) {
      old.missedScans += direcciones.contains(old.address) ? 0 : 1;
    }
    for (var n in nuevos) {
      if (!dispositivosEncontrados.any((d) => d.address == n.address)) {
        dispositivosEncontrados.add(n);
      }
    }
    dispositivosEncontrados.removeWhere((d) => d.missedScans >= 3);

    notifyListeners();
  }

  /// Cancela escaneo BLE y timer
  void _cancelarEscaneo() {
    _scanSubscription?.cancel();
    ble.FlutterBluePlus.stopScan();
    _scanTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelarEscaneo();
    super.dispose();
  }
}
