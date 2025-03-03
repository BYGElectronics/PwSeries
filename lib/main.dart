import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pw/src/Controller/home_controller.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/pages/control_screen.dart';
import 'package:pw/src/pages/splash_screen.dart';
import 'package:pw/src/pages/home_screen.dart';
import 'package:pw/src/pages/config_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final HomeController _homeController = HomeController();
  final ConfigController _configController = ConfigController();
  ThemeMode _themeMode = ThemeMode.system; // Estado inicial del tema

  /// **🔄 Alternar entre tema claro y oscuro**
  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light, // Tema claro
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, // Tema oscuro
        primarySwatch: Colors.blue,
      ),
      themeMode: _themeMode, // Modo de tema dinámico
      initialRoute: "splash",
      routes: {
        "splash": (context) => const SplashScreen(),
        "home": (context) => HomeScreen(
              toggleTheme: _toggleTheme, // Alternar tema
              themeMode: _themeMode,
            ),
        "config": (context) => ConfigScreen(controller: _configController),
        "control": (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is BluetoothDevice) {
            return ControlScreen(connectedDevice: args);
          } else {
            return HomeScreen(
              toggleTheme: _toggleTheme,
              themeMode: _themeMode,
            );
          }
        },
      },
    );
  }
}
