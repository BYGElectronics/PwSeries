// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/src/Controller/home_controller.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/Controller/idioma_controller.dart';
import 'package:pw/src/Controller/text_size_controller.dart';

import 'package:pw/src/localization/app_localization.dart';

import 'package:pw/src/pages/acercaDe.dart';
import 'package:pw/src/pages/conexionPw.dart';
import 'package:pw/src/pages/configAvanzadaScreen.dart';
import 'package:pw/src/pages/configTecladoScreen.dart';
import 'package:pw/src/pages/configuracionBluetoothScreen.dart';
import 'package:pw/src/pages/controlConfig.dart';
import 'package:pw/src/pages/control_screen.dart';
import 'package:pw/src/pages/darkModeScreen.dart';
import 'package:pw/src/pages/dark_mode_screen.dart';
import 'package:pw/src/pages/splashScreenConfirmation.dart';
import 'package:pw/src/pages/splashScreenDenegate.dart';
import 'package:pw/src/pages/splash_screen.dart';
import 'package:pw/src/pages/home_screen.dart';
import 'package:pw/src/pages/config_screen.dart';
import 'package:pw/src/pages/idioma_screen.dart';
import 'package:pw/src/pages/text_size_screen.dart';

// Instancia única de ControlController para toda la app
final ControlController _controlController = ControlController();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IdiomaController()),
        ChangeNotifierProvider(create: (_) => TextSizeController()),
        ChangeNotifierProvider(create: (_) => ConfigController()),
        // Inyectamos globalmente el ControlController
        ChangeNotifierProvider<ControlController>.value(
          value: _controlController,
        ),
      ],
      child: const MyAppWrapper(),
    ),
  );
}

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});
  @override
  Widget build(BuildContext context) => const MyApp();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final idiomaController    = Provider.of<IdiomaController>(context);
    final textSizeController  = Provider.of<TextSizeController>(context);
    final configController    = Provider.of<ConfigController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: idiomaController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: textSizeController.textScaleFactor,
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: textSizeController.textScaleFactor,
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      themeMode: configController.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),

        "home": (context) => HomeScreen(
          toggleTheme: configController.toggleDarkMode,
          themeMode: ThemeMode.system,
        ),

        "config": (context) => ConfigScreen(controller: configController),
        "idioma": (context) => IdiomaScreen(),
        "configuracionBluetooth": (context) => ConfiguracionBluetoothScreen(),
        "configAvanzada": (context) => const ConfigAvanzadaScreen(),

        // Configuración de Teclado usa la misma instancia del ControlController
        "configTeclado": (context) => ConfigTecladoScreen(
          controller: _controlController,
        ),

        "themeConfig": (context) =>  DarkModeScreen(),
        "splash_denegate": (context) => const SplashConexionDenegateScreen(),
        "textSize": (context) => const TextSizeScreen(),
        "acercaDe": (context) => const AcercadeScreen(),
        "conexionPw": (context) => const ConexionpwScreen(),

        // Splash de confirmación pasa la instancia y el dispositivo
        "splash_confirmacion": (context) {
          final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return SplashConexionScreen(
            device:     args['device']     as BluetoothDevice,
            controller: args['controller'] as ControlController,
          );
        },

        // ControlScreen: si no vienen args al volver, reutiliza la conexión existente
        "/control": (context) {
          final settings = ModalRoute.of(context)!.settings;
          final args = settings.arguments;
          BluetoothDevice? device;

          if (args is Map<String, dynamic> && args['device'] is BluetoothDevice) {
            device = args['device'] as BluetoothDevice;
          } else {
            device = _controlController.connectedDevice;
          }

          return ControlScreen(
            connectedDevice: device,
            controller:      _controlController,
          );
        },

        // Configuración avanzada del control
        "/controlConfig": (context) {
          final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return ControlConfigScreen(
            connectedDevice: args['device']     as BluetoothDevice,
            controller:      _controlController,
          );
        },
      },
    );
  }
}
