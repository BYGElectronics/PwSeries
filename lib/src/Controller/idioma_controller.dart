import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdiomaController extends ChangeNotifier {
  Locale _locale = const Locale('es'); // Idioma predeterminado

  // Obtener el idioma actual
  Locale get locale => _locale;

  IdiomaController() {
    _cargarIdiomaGuardado();
  }

  // Cambiar el idioma y guardar la preferencia
  void cambiarIdioma(String idioma) async {
    _locale = Locale(idioma);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idiomaSeleccionado', idioma);
  }

  // Cargar idioma almacenado al iniciar la app
  Future<void> _cargarIdiomaGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final idiomaGuardado = prefs.getString('idiomaSeleccionado');

    if (idiomaGuardado != null) {
      _locale = Locale(idiomaGuardado);
      notifyListeners();
    }
  }
}
