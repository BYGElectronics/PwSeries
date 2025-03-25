/**
 * main.dart
 *
 * Punto de entrada de la aplicación Flutter que:
 * - Define la clase principal (MyApp) con todo el soporte de Provider para la configuración,
 *   localización (idioma) y manejo de tamaño de texto.
 * - Construye la interfaz inicial y configura los temas claro/oscuro.
 * - Define las rutas de navegación para las diferentes pantallas.
 */

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/control_controller.dart';

// Importaciones de controladores que proveen estado compartido y lógica de negocio.
import 'package:pw/src/Controller/home_controller.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/Controller/idioma_controller.dart';
import 'package:pw/src/Controller/text_size_controller.dart';

// Importaciones relacionadas con la localización (traducción de textos).
import 'package:pw/src/localization/app_localization.dart';
import 'package:pw/src/pages/controlConfig.dart';

// Importaciones de las pantallas/ páginas que conforman la UI de la app.
import 'package:pw/src/pages/control_screen.dart';
import 'package:pw/src/pages/splash_screen.dart';
import 'package:pw/src/pages/home_screen.dart';
import 'package:pw/src/pages/config_screen.dart';
import 'package:pw/src/pages/idioma_screen.dart';

/// **Función principal que inicia la aplicación**
///
/// - Envolvemos la app con `MultiProvider` para que los controladores (Providers)
///   estén disponibles globalmente desde la raíz.
/// - Inicializa la pantalla inicial con el widget `MyAppWrapper`.
void main() {
  runApp(
    MultiProvider(
      providers: [
        // Proveedor para manejar el idioma seleccionado.
        ChangeNotifierProvider(create: (context) => IdiomaController()),

        // Proveedor para manejar el factor de escala de texto (accesibilidad).
        ChangeNotifierProvider(create: (context) => TextSizeController()),

        // Proveedor para manejar la configuración de la app (p.e. modo oscuro/ claro).
        ChangeNotifierProvider(create: (context) => ConfigController()),
      ],
      child: MyAppWrapper(),
    ),
  );
}

/**
 * **Este widget encapsula `MyApp`** para asegurar que tenga acceso a los Providers.
 *
 * - `MyAppWrapper` existe como intermediario, aunque podría no ser estrictamente
 *   necesario. Sirve para tener un punto claro donde se inyectan los providers.
 */
class MyAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Retorna la clase principal MyApp (Stateful) para gestionar estados generales.
    return const MyApp();
  }
}

/**
 * **Clase principal de la aplicación Flutter**: MyApp
 *
 * - StatefulWidget para manejar potenciales cambios de configuración o estado
 *   que requieran una reconstrucción de la vista principal.
 */
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/**
 * **Estado de la aplicación principal**: _MyAppState
 *
 * - Aquí se configuran:
 *   1. Localización e idiomas
 *   2. Temas (claro y oscuro)
 *   3. Rutas de navegación inicial y rutas disponibles
 */
class _MyAppState extends State<MyApp> {
  // HomeController se instancia como ejemplo para uso global.
  final HomeController _homeController = HomeController();

  @override
  Widget build(BuildContext context) {
    // Se obtienen los controladores/ providers necesarios
    final idiomaController = Provider.of<IdiomaController>(context);
    final textSizeController = Provider.of<TextSizeController>(context);
    final configController = Provider.of<ConfigController>(context);

    return MaterialApp(
      // Desactiva la banda de depuración en la esquina superior derecha
      debugShowCheckedModeBanner: false,

      // **Configuración de idiomas**: localización actual y soporte de idiomas disponibles
      locale: idiomaController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // **Tema Claro**: estilo y colores para modo claro
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          // Ajuste global del factor de escala de texto.
          fontSizeFactor: textSizeController.textScaleFactor,
          bodyColor: Colors.black, // Color del texto en modo claro
          displayColor: Colors.black, // Color de títulos en modo claro
        ),
      ),

      // **Tema Oscuro**: estilo y colores para modo oscuro
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        // Color de fondo para pantallas en modo oscuro
        scaffoldBackgroundColor: Colors.black,
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: textSizeController.textScaleFactor,
          bodyColor: Colors.white, // Color del texto en modo oscuro
          displayColor: Colors.white, // Color de títulos en modo oscuro
        ),
      ),

      // Define qué modo de tema se va a usar (claro / oscuro / automático del sistema).
      // En este caso, se basa en un valor booleano de ConfigController (isDarkMode).
      themeMode: configController.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Ruta inicial de la app: muestra la pantalla de Splash
      initialRoute: "splash",

      // Mapa de rutas: asociar nombres de rutas con pantallas concretas
      routes: {
        // Pantalla inicial (Splash Screen)
        "splash": (context) => const SplashScreen(),

        // Pantalla principal (Home)
        "home":
            (context) => HomeScreen(
              // Permite alternar entre modo claro y oscuro
              toggleTheme: configController.toggleDarkMode,
              themeMode: ThemeMode.system,
            ),

        // Pantalla de configuración con un controlador recibido por parámetro
        "config": (context) => ConfigScreen(controller: configController),

        // Pantalla para cambiar el idioma
        "idioma": (context) => IdiomaScreen(),


        "control": (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is BluetoothDevice && args.platformName.contains("Pw")) {
            return ControlScreen(
              connectedDevice: args,
              controller: ControlController(),
            );
          } else {
            debugPrint("⚠️ No se ha conectado un dispositivo PW.");
            return HomeScreen(
              toggleTheme: configController.toggleDarkMode,
              themeMode: ThemeMode.system,
            );
          }
        },


        "/controlConfig": (context) => ControlConfigScreen(), // Teclado configuración



      },
    );
  }
}
