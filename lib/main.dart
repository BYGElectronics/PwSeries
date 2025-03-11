import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/home_controller.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/Controller/idioma_controller.dart';
import 'package:pw/src/Controller/text_size_controller.dart';
import 'package:pw/src/localization/app_localization.dart';
import 'package:pw/src/pages/control_screen.dart';
import 'package:pw/src/pages/splash_screen.dart';
import 'package:pw/src/pages/home_screen.dart';
import 'package:pw/src/pages/config_screen.dart';
import 'package:pw/src/pages/idioma_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// **Función principal que inicia la aplicación**
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => IdiomaController()),
        ChangeNotifierProvider(create: (context) => TextSizeController()),
        ChangeNotifierProvider(create: (context) => ConfigController()), // ✅ Aquí debe estar
      ],
      child: MyAppWrapper(),
    ),
  );
}

/// **Este widget encapsula `MyApp` para asegurar que tenga acceso a los providers**
class MyAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

/// **Clase principal de la aplicación Flutter**
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// **Estado de la aplicación principal**
class _MyAppState extends State<MyApp> {
  final HomeController _homeController = HomeController();

  @override
  Widget build(BuildContext context) {
    final idiomaController = Provider.of<IdiomaController>(context);
    final textSizeController = Provider.of<TextSizeController>(context);
    final configController = Provider.of<ConfigController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // **Configuración de idiomas**
      locale: idiomaController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // **Tema Claro**
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: textSizeController.textScaleFactor,
          bodyColor: Colors.black, // ✅ Color de texto en modo claro
          displayColor: Colors.black, // ✅ Color de texto en modo claro
        ),
      ),

      // **Tema Oscuro**
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, // ✅ Fondo negro
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: textSizeController.textScaleFactor,
          bodyColor: Colors.white, // ✅ Color de texto en modo oscuro
          displayColor: Colors.white, // ✅ Color de texto en modo oscuro
        ),
      ),

      // ✅ Se usa `ConfigController` para gestionar el modo oscuro
      themeMode: configController.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      initialRoute: "splash",
      routes: {
        "splash": (context) => const SplashScreen(),
        "home": (context) => HomeScreen(
          toggleTheme: configController.toggleDarkMode,
          themeMode: ThemeMode.system,
        ),
        "config": (context) => ConfigScreen(controller: configController),
        "idioma": (context) => IdiomaScreen(),
        "control": (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is BluetoothDevice) {
            return ControlScreen(connectedDevice: args);
          } else {
            return HomeScreen(
                toggleTheme: configController.toggleDarkMode,
                themeMode: ThemeMode.system);
          }
        },
      },
    );
  }
}
