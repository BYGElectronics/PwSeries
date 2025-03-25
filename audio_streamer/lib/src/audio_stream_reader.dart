import 'dart:async';
import 'dart:typed_data';
import 'config.dart'; // 👈 Este import es necesario

class AudioStreamReader {
  final StreamConfig config;

  AudioStreamReader(this.config);

  Future<Stream<Uint8List>> start() async {
    return Stream.periodic(
      const Duration(milliseconds: 50),
          (_) => Uint8List.fromList(List<int>.generate(320, (i) => i % 256)),
    );
  }

  Future<void> stop() async {}
}
