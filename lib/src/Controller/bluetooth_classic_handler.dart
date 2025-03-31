import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothClassicHandler {
  BluetoothConnection? _connection;
  String _deviceName = '';
  StreamSink<Uint8List>? get outputSink => _connection?.output;

  /// Retorna true si la conexión está activa.
  bool get isConnected => _connection?.isConnected ?? false;

  /// Nombre del dispositivo actualmente conectado.
  String get deviceName => _deviceName;

  /// Conecta a un dispositivo por nombre. Devuelve true si fue exitoso.
  Future<bool> connectTo(String targetName) async {
    try {
      // Buscar dispositivos emparejados
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();

      // Buscar el dispositivo con nombre específico
      final targetDevice = devices.firstWhere(
            (d) => d.name == targetName,
        orElse: () => throw Exception('🔍 Dispositivo "$targetName" no encontrado.'),
      );

      // Intentar conexión
      _connection = await BluetoothConnection.toAddress(targetDevice.address);
      _deviceName = targetDevice.name ?? '';
      print("✅ Conectado a $_deviceName");

      return true;
    } catch (e) {
      print("❌ Error al conectar a Classic: $e");
      return false;
    }
  }

  /// Cierra la conexión si está activa
  Future<void> disconnect() async {
    if (_connection != null && _connection!.isConnected) {
      await _connection!.close();
      _connection = null;
      _deviceName = '';
      print("🔌 Conexión Classic cerrada.");
    }
  }
}

