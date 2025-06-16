import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:io' show Platform;

class PttAudioController {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>();

  bool _isRecorderInitialized = false;
  BluetoothConnection? classicConnection;

  /// Inicializa el grabador y escucha el audio
  Future<void> init() async {
    if (!_isRecorderInitialized && _recorder.isStopped) {
      await _recorder.openRecorder();
      _isRecorderInitialized = true;

      _audioStreamController.stream.listen((buffer) async {
        if (classicConnection != null && classicConnection!.isConnected) {
          classicConnection!.output.add(buffer);
          await classicConnection!.output.allSent;
        }
      });
    }
  }

  /// Inicia la transmisión de audio
  Future<void> start() async {
    if (!_isRecorderInitialized || _recorder.isRecording) return;

    await _recorder.startRecorder(
      codec: Codec.pcm16,
      sampleRate: 8000,
      numChannels: 1,
      audioSource: AudioSource.microphone,
      toStream: _audioStreamController.sink,
    );
  }

  /// Detiene la transmisión de audio
  Future<void> stop() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
  }

  /// Limpia recursos al cerrar
  Future<void> dispose() async {
    await stop();

    if (_isRecorderInitialized) {
      await _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }

    await _audioStreamController.close();
  }

  /// Permite inyectar la conexión Bluetooth Classic desde fuera
  void setClassicConnection(BluetoothConnection connection) {
    if (Platform.isAndroid) {
      classicConnection = connection;
    }
  }
}
