
import 'package:flutter/material.dart';

/// Helper para obtener medidas relativas (% de ancho y alto)
class Responsive {
  final BuildContext context;
  late double _w, _h;

  Responsive(this.context) {
    final size = MediaQuery.of(context).size;
    _w = size.width;
    _h = size.height;
  }

  /// Retorna un % del ancho de pantalla (0–100)
  double wp(double pct) => _w * pct / 100;

  /// Retorna un % del alto de pantalla (0–100)
  double hp(double pct) => _h * pct / 100;

  /// True si es teléfono muy pequeño
  bool get isSmallPhone => _w < 360;

  /// True si es tablet o pantallas anchas
  bool get isTablet => _w >= 600;

  /// Ancho total de la pantalla en px
  double get width => _w;

  /// Alto total de la pantalla en px
  double get height => _h;
}
