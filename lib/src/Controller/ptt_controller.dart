import 'package:flutter/foundation.dart';

class PttController {
  // Bandera para verificar si PTT está activo
  bool _isPTTActive = false;

  bool get isPTTActive => _isPTTActive;

  /// Activar PTT (BT Classic + Micrófono)
  void activatePTT() {
    if (!_isPTTActive) {
      // Enviar el protocolo para activar PTT
      _sendPttCommand();

      // Aquí puedes iniciar la captura de audio o cualquier otro proceso
      startMicCapture();

      _isPTTActive = true;
      debugPrint("✅ PTT activado: BT Classic y micrófono activos.");
    }
  }

  /// Desactivar PTT (BT Classic + Micrófono)
  void deactivatePTT() {
    if (_isPTTActive) {
      // Enviar el mismo protocolo para alternar a desactivado
      _sendPttCommand();

      // Aquí puedes detener la captura de audio o cualquier otro proceso
      stopMicCapture();

      _isPTTActive = false;
      debugPrint("⛔ PTT desactivado: BT Classic y micrófono desactivados.");
    }
  }

  // Función ficticia para enviar el comando PTT
  void _sendPttCommand() {
    List<int> frame = [0xAA, 0x14, 0x11, 0x44, 0x32, 0x29, 0xFF];
    // Aquí puedes integrar un método para enviar el comando
    debugPrint(
      "🔄 Comando PTT enviado: ${frame.map((e) => e.toRadixString(16)).join(' ')}",
    );
  }

  // Funciones ficticias para iniciar/detener captura de audio
  void startMicCapture() {
    // Lógica para iniciar la captura de audio
    debugPrint("🎤 Micrófono capturando audio...");
  }

  void stopMicCapture() {
    // Lógica para detener la captura de audio
    debugPrint("⛔ Micrófono detenido.");
  }
}
