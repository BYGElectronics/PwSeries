// lib/src/Controller/ptt_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as btClassic;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PttController extends ChangeNotifier {
  late BluetoothDevice _bleDevice;
  late BluetoothCharacteristic _bleWriteChar;
  btClassic.BluetoothConnection? _classicConn;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription<Uint8List>? _micSub;

  bool _isActive = false;
  bool get isActive => _isActive;

  /// Inicializa con el dispositivo BLE y la characteristic de escritura.
  void init(BluetoothDevice device, BluetoothCharacteristic writeChar) {
    _bleDevice = device;
    _bleWriteChar = writeChar;
  }

  /// Llama esto en onTapDown / onTapUp
  Future<void> toggle() async {
    if (!_isActive) {
      await _activate();
    } else {
      await _deactivate();
    }
    _isActive = !_isActive;
    notifyListeners();
  }

  Future<void> _activate() async {
    // 1) Pasa BLE → Classic audio mode
    await _sendBle(_buildFrame([0x14, 0x30, 0x44]));
    await Future.delayed(const Duration(seconds: 2));

    // 2) Conecta Classic por MAC
    final mac = _bleDevice.remoteId.id;
    await _connectClassic(mac);

    // 3) Permiso mic + streaming
    if (!await _requestMic()) return;
    await _startMicStreaming();

    // 4) Comando PTT_ON
    await _sendBle(_buildFrame([0x14, 0x11, 0x44]));
  }

  Future<void> _deactivate() async {
    // 1) Comando PTT_OFF
    await _sendBle(_buildFrame([0x14, 0x11, 0x00]));

    // 2) Detiene mic + cierra Classic
    await _stopMicStreaming();
    await _disconnectClassic();
  }

  Future<void> _connectClassic(String mac) async {
    try {
      final bonded = await btClassic.FlutterBluetoothSerial.instance.getBondedDevices();
      final target = bonded.firstWhere((d) => d.address == mac);
      _classicConn = await btClassic.BluetoothConnection.toAddress(mac);
    } catch (e) {
      debugPrint('Error conectando Classic: $e');
    }
  }

  Future<void> _disconnectClassic() async {
    if (_classicConn?.isConnected ?? false) {
      await _classicConn!.close();
    }
    _classicConn = null;
  }

  Future<void> _startMicStreaming() async {
    await _recorder.openRecorder();
    final ctrl = StreamController<Uint8List>();
    _micSub = ctrl.stream.listen((chunk) {
      if (_classicConn?.isConnected ?? false) {
        _classicConn!.output.add(chunk);
      }
    });
    await _recorder.startRecorder(
      toStream: ctrl.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 8000,
    );
  }

  Future<void> _stopMicStreaming() async {
    if (_recorder.isRecording) await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    await _micSub?.cancel();
    _micSub = null;
  }

  Future<void> _sendBle(List<int> frame) async {
    await _bleWriteChar.write(frame, withoutResponse: false);
  }

  List<int> _buildFrame(List<int> cmd) {
    final crc = _modbusCrc(cmd);
    return [0xAA, ...cmd, crc[0], crc[1], 0xFF];
  }

  List<int> _modbusCrc(List<int> data) {
    int crc = 0xFFFF;
    for (var b in data) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xA001 : crc >> 1;
      }
    }
    return [crc & 0xFF, (crc >> 8) & 0xFF];
  }

  Future<bool> _requestMic() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
}
