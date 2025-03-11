import 'package:flutter/material.dart';

// Controlador para gestionar el cambio de idioma
class IdiomaController extends ChangeNotifier {
  Locale _locale = const Locale('es'); // Idioma predeterminado en español

  // Obtener el idioma actual
  Locale get locale => _locale;

  // Cambiar el idioma y notificar a la aplicación
  void cambiarIdioma(String idioma) {
    _locale = Locale(idioma);
    notifyListeners(); // Notifica a la app sobre el cambio de idioma
  }
}
