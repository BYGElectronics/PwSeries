import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pw/src/Controller/home_controller.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/pages/control_screen.dart';
import 'package:pw/src/pages/splash_screen.dart';
import 'package:pw/src/pages/home_screen.dart';
import 'package:pw/src/pages/config_screen.dart';

/// Función principal que inicia la aplicación Flutter
void main() => runApp(const MyApp());

/// Clase principal de la aplicación Flutter
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// Estado de la aplicación principal
class _MyAppState extends State<MyApp> {
  /// Controlador para la pantalla principal (HomeScreen)
  final HomeController _homeController = HomeController();

  /// Controlador para la configuración de la app
  final ConfigController _configController = ConfigController();

  /// Modo de tema actual (Claro/Oscuro)
  ThemeMode _themeMode = ThemeMode.system;

  /// Función para alternar entre modo claro y oscuro
  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  /// Construcción de la aplicación
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de "debug"
      //Tema Claro
      theme: ThemeData(
        brightness: Brightness.light, // Modo claro
        primarySwatch: Colors.blue, // Color principal
      ),

      // Tema Oscuro
      darkTheme: ThemeData(
        brightness: Brightness.dark, // Modo oscuro
        primarySwatch: Colors.blue, // Color principal
      ),

      themeMode: _themeMode, // Aplica el modo de tema seleccionado
      /// Ruta inicial de la aplicación
      initialRoute: "splash",

      /// Definición de rutas en la aplicación
      routes: {
        // Pantalla de carga (SplashScreen)
        "splash": (context) => const SplashScreen(),

        // Pantalla principal (HomeScreen)
        "home":
            (context) =>
                HomeScreen(toggleTheme: _toggleTheme, themeMode: _themeMode),

        // Pantalla de configuración (ConfigScreen)
        "config": (context) => ConfigScreen(controller: _configController),

        // Pantalla de control (ControlScreen)
        "control": (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          // Verifica si el argumento es un dispositivo Bluetooth
          if (args is BluetoothDevice) {
            return ControlScreen(connectedDevice: args);
          } else {
            // Si no hay dispositivo, regresa a HomeScreen
            return HomeScreen(toggleTheme: _toggleTheme, themeMode: _themeMode);
          }
        },
      },
    );
  }
}