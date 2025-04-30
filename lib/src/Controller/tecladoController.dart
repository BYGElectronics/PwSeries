import 'package:flutter/material.dart';

/// Callback para enviar un frame de bytes al dispositivo BLE.
/// Debe apuntar a tu función `sendCommand(List<int>)`.
typedef CommandSender = Future<void> Function(List<int> frame);

class TecladoController extends ChangeNotifier {
  final CommandSender sendCommand;

  TecladoController({required this.sendCommand});

  /// Calcula CRC-16 ModBus (polinomio 0xA001) de `data`.
  /// Devuelve [lowByte, highByte].
  List<int> _calculateCRC(List<int> data) {
    int crc = 0xFFFF;
    for (var byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    // low byte primero
    return [crc & 0xFF, (crc >> 8) & 0xFF];
  }

  /// Construye el frame completo: [0xAA] + payload + CRC + [0xFF]
  List<int> _buildFrame(List<int> payload) {
    final header = <int>[0xAA];
    final data = [...header, ...payload];
    final crc = _calculateCRC(data);
    return [...data, ...crc, 0xFF];
  }

  /// Sirena
  void activateSiren() {
    final frame = _buildFrame([0x14, 0x07, 0x44]);
    sendCommand(frame);
    notifyListeners();
  }

  /// Auxiliar
  void activateAux() {
    final frame = _buildFrame([0x14, 0x08, 0x44]);
    sendCommand(frame);
    notifyListeners();
  }

  /// Intercomunicador
  void activateInter() {
    final frame = _buildFrame([0x14, 0x12, 0x44]);
    sendCommand(frame);
    notifyListeners();
  }

  /// Bocina (Horn): primero reset, luego horn
  void toggleHorn() {
    final resetFrame = _buildFrame([0x00, 0x00, 0x00]);
    final hornFrame = _buildFrame([0x14, 0x09, 0x44]);
    sendCommand(resetFrame).then((_) => sendCommand(hornFrame));
    notifyListeners();
  }

  /// Wail
  void toggleWail() {
    final frame = _buildFrame([0x14, 0x10, 0x44]);
    sendCommand(frame);
    notifyListeners();
  }

  /// PTT (por simplicidad aquí siempre "on" — puedes alternar internamente)
  void togglePTT() {
    final frame = _buildFrame([0x14, 0x11, 0x44]);
    sendCommand(frame);
    notifyListeners();
  }
}
