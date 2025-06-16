import 'dart:async';
import 'dart:io' show Platform;
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
  StreamSubscription? _scanSubscription;
  Timer? _scanTimer;

  /// PIN que ve el usuario (máscara)
  final String pinMask = "123456";

  /// Clave real para emparejar Classic (nunca en UI)
  final String pinReal = "GYB253";

  String pinIngresado = "";
  DeviceData? selectedDevice;
  DeviceData? dispositivoConectando;

  ConfiguracionBluetoothController() {
    _inicializarBluetooth();
  }

  Future<void> _inicializarBluetooth() async {
    if (Platform.isAndroid) {
      // 1) Asegurar Bluetooth ON
      final estado = await FlutterBluetoothSerial.instance.state;
      if (estado != BluetoothState.STATE_ON) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }

      // 2) Pedir permiso de conexión Classic
      if (await Permission.bluetoothConnect.isDenied) return;

      // 3) Detectar automáticamente el primer Pw Classic emparejado
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (var d in bonded) {
        if (d.name?.toLowerCase().contains("btpw") == true) {
          final auto = DeviceData(
            name: d.name!,
            address: d.address,
            isBLE: false,
          );
          dispositivosEncontrados.add(auto);
          // Si solo hay uno, seleccionarlo y mostrar PIN
          if (dispositivosEncontrados.length == 1) {
            selectedDevice = auto;
          }
          break;
        }
      }
      notifyListeners();

      // 4) Iniciar escaneo periódico (BLE + nuevos Classic)
      _iniciarEscaneoPeriodico();
    }
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

  /// Usuario presiona “Aceptar” tras ingresar el PIN
  Future<void> enviarPinYConectar(BuildContext context) async {
    if (selectedDevice == null) return;

    // 1) Validar PIN máscara
    if (pinIngresado != pinMask) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PIN incorrecto")));
      return;
    }

    final mac = selectedDevice!.address;
    dispositivoConectando = selectedDevice;
    notifyListeners();

    // 2) Emparejar Classic usando la clave real
    final bonded = await _pairClassic(mac);
    if (!bonded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al emparejar Classic")),
      );
      return;
    }

    // 3) Conectar Classic (puedes guardar la conexión si la necesitas)
    await _connectClassic(mac);

    // 4) Conectar BLE (tu flujo existente)
    await _conectarBLE(context, mac);
  }

  Future<bool> _pairClassic(String mac) async {
    try {
      // Aquí inyectamos pinReal en el pairing
      final success = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
        mac,
        pin: pinReal,
      );
      return success == true;
    } catch (e) {
      debugPrint("❌ Error en bond Classic: $e");
      return false;
    }
  }

  Future<void> _connectClassic(String mac) async {
    if (!Platform.isAndroid) return;
    try {
      final conn = await BluetoothConnection.toAddress(mac);
      debugPrint("✅ Classic conectado a $mac");
      // opcional: guarda conn si lo vas a usar
    } catch (e) {
      debugPrint("❌ Error conectando Classic: $e");
    }
  }

  /// Dentro de ConfiguracionBluetoothController
  /// Reemplaza tu método _conectarBLE por éste:
  Future<void> _conectarBLE(BuildContext context, String macAddress) async {
    ble.BluetoothDevice? dispositivoBLE;
    try {
      // 1) Detener cualquier escaneo pendiente
      await ble.FlutterBluePlus.stopScan();

      // 2) Escaneo para encontrar el dispositivo con esa MAC
      final completer = Completer<ble.BluetoothDevice>();
      _scanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          if (result.device.remoteId.id.toLowerCase() ==
              macAddress.toLowerCase()) {
            completer.complete(result.device);
            break;
          }
        }
      });
      await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      dispositivoBLE = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      await ble.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();

      if (dispositivoBLE == null) {
        throw Exception(
          "No se encontró el dispositivo BLE con MAC $macAddress",
        );
      }

      // 3) Conectarse al dispositivo
      await dispositivoBLE.connect(timeout: const Duration(seconds: 10));
      debugPrint("✅ Conectado por BLE a ${dispositivoBLE.remoteId.id}");

      // 4) Descubrir servicios y buscar característica de escritura (ff01)
      await dispositivoBLE.discoverServices();
      ble.BluetoothCharacteristic? writeChar;
      for (var svc in dispositivoBLE.servicesList) {
        for (var ch in svc.characteristics) {
          if (ch.uuid.toString().toLowerCase().contains('ff01')) {
            writeChar = ch;
            break;
          }
        }
        if (writeChar != null) break;
      }
      if (writeChar == null) {
        throw Exception("Característica ff01 no encontrada");
      }

      // 5) Configurar el controlador de Control
      final controlController = ControlController();
      controlController.setDevice(dispositivoBLE);
      controlController.setWriteCharacteristic(writeChar);

      // 6) Navegar al splash de confirmación pasándole device y controller
      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/splash_confirmacion',
          arguments: {
            'device': dispositivoBLE,
            'controller': controlController,
          },
        );
      }
    } catch (e) {
      debugPrint("❌ Error en _conectarBLE: $e");
      // Si falla, vamos al splash de denegación
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

    // 1) Recolectar Classic emparejados (solo Android)
    if (Platform.isAndroid) {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      nuevos.addAll(
        bonded
            .where((d) => d.name?.toLowerCase().contains("btpw") == true)
            .map(
              (d) =>
                  DeviceData(name: d.name!, address: d.address, isBLE: false),
            ),
      );
    }

    // 2) Escanear BLE
    await ble.FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    final encontradosBLE = <DeviceData>[];
    _scanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        final n = r.device.platformName;
        if (n.toLowerCase().contains("btpw") &&
            !encontradosBLE.any((e) => e.address == r.device.remoteId.str)) {
          encontradosBLE.add(
            DeviceData(name: n, address: r.device.remoteId.str, isBLE: true),
          );
        }
      }
    });
    await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await Future.delayed(const Duration(seconds: 5));
    await ble.FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    nuevos.addAll(encontradosBLE);

    // 3) Actualizar lista / contadores
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

  Future<void> cancelarTodo() async {
    _scanSubscription?.cancel();
    await ble.FlutterBluePlus.stopScan();
    _scanTimer?.cancel();
  }

  @override
  void dispose() {
    cancelarTodo();
    super.dispose();
  }
}
