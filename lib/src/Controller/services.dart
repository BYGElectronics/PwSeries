import 'package:flutter/services.dart';

class AudioSco {
  static const _channel = MethodChannel('app.pw/audio_sco');

  static Future<void> startSco() async {
    await _channel.invokeMethod('startSco');
  }

  static Future<void> stopSco() async {
    await _channel.invokeMethod('stopSco');
  }
}