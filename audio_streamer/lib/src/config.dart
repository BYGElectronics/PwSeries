enum ChannelConfig {
  CHANNEL_IN_MONO,
}

enum AudioFormat {
  ENCODING_PCM_16BIT,
}

class StreamConfig {
  final int sampleRate;
  final ChannelConfig channelConfig;
  final AudioFormat audioFormat;

  StreamConfig({
    required this.sampleRate,
    required this.channelConfig,
    required this.audioFormat,
  });
}