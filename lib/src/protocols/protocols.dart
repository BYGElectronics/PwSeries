class Protocols {
  /// **Cálculo del CRC ModBus**
  static List<int> _calculateCRC(List<int> data) {
    int crc = 0xFFFF;
    for (var byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    // Retornar los bytes del CRC en orden correcto
    return [(crc & 0xFF), (crc >> 8) & 0xFF];
  }

  /// **Método privado para construir comandos**
  static List<int> _buildCommand(List<int> command, List<int>? crc) {
    List<int> frame = [0xAA] + command;
    frame.addAll(
      crc ?? _calculateCRC(command),
    ); // Si CRC no es forzado, calcularlo
    frame.add(0xFF);
    return frame;
  }

  /// **Protocolos con CRC Forzado**
  static List<int> activateSiren() {
    return _buildCommand([0x14, 0x07, 0x44], [0xCF, 0xC8]); // CRC `CFC8`
  }

  static List<int> activateAux() {
    return _buildCommand([0x14, 0x08, 0x44], [0xCC, 0xF8]); // CRC `CCF8`
  }

  static List<int> deactivateWail() {
    return _buildCommand(
      [0x14, 0x10, 0x00],
      [0x00, 0x00],
    ); // CRC de desactivación
  }

  static List<int> deactivateInter() {
    return _buildCommand(
      [0x14, 0x12, 0x00],
      [0x00, 0x00],
    ); // CRC de desactivación
  }

  static List<int> activateHorn() {
    return _buildCommand([0x14, 0x09, 0x44], [0x0C, 0xA9]); // CRC `0CA9`
  }

  static List<int> deactivateHorn() {
    return _buildCommand(
      [0x14, 0x09, 0x00],
      [0x00, 0x00],
    ); // CRC de desactivación
  }

  static List<int> activateWail() {
    return _buildCommand([0x14, 0x10, 0x44], [0xF2, 0x78]); // CRC `F278`
  }

  static List<int> activateInter() {
    return _buildCommand([0x14, 0x12, 0x44], [0x32, 0xD9]); // CRC `32D9`
  }

  static List<int> activatePTT() {
    return _buildCommand([0x14, 0x11, 0x44], [0x32, 0x29]); // CRC `3229`
  }

  static List<int> deactivatePTT() {
    return _buildCommand(
      [0x14, 0x11, 0x00],
      [0x00, 0x00],
    ); // CRC de desactivación
  }
}
