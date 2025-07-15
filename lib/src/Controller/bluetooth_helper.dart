import 'package:flutter/services.dart';

class BluetoothHelper {
  static const _ch = MethodChannel('pwseries.bluetooth');

  /// ¿A2DP ya conectado a “BTPW”?
  static Future<bool> isBluetoothAudioConnected() async {
    try {
      return await _ch.invokeMethod<bool>('isBluetoothAudioConnected') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Conectar automáticamente A2DP a “BTPW”
  static Future<bool> connectBluetoothAudio() async {
    try {
      return await _ch.invokeMethod<bool>('connectBluetoothAudio') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Desconectar A2DP de “BTPW”
  static Future<bool> disconnectBluetoothAudio() async {
    try {
      return await _ch.invokeMethod<bool>('disconnectBluetoothAudio') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
