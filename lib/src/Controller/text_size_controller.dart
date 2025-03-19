import 'package:flutter/material.dart';

class TextSizeController with ChangeNotifier {
  double _textScaleFactor = 1.0; // Escala de texto por defecto

  double get textScaleFactor => _textScaleFactor;

  void cambiarTamanioTexto(double nuevoTamanio) {
    _textScaleFactor = nuevoTamanio;
    notifyListeners(); // Notificar cambios a la app
  }
}
