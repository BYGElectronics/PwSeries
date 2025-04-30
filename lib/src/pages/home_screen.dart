// **Importaciones necesarias**
import 'package:flutter/material.dart'; // Importa la librería de Flutter para construir la UI
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Manejo de Bluetooth BLE
import 'package:provider/provider.dart'; // Proveedor de estado para manejar la lógica de configuración
import 'package:pw/src/Controller/home_controller.dart'; // Controlador principal de la pantalla de inicio
import 'package:pw/src/Controller/config_controller.dart'; // Controlador de configuración
import 'package:pw/src/localization/app_localization.dart';

import '../Controller/idioma_controller.dart'; // Manejo de internacionalización (traducción)

// **Clase principal que representa la pantalla de inicio**
//
// Esta pantalla permite activar y buscar dispositivos Bluetooth,
// cambiar el modo de tema (oscuro/claro) y acceder a la configuración.
class HomeScreen extends StatefulWidget {
  // **Parámetro para alternar el modo de tema (oscuro/claro)**
  final VoidCallback toggleTheme;

  // **Parámetro para conocer el estado actual del tema**
  final ThemeMode themeMode;

  // **Constructor de la clase HomeScreen**
  //
  // Requiere dos parámetros:
  // - `toggleTheme`: Función para cambiar el tema.
  // - `themeMode`: Indica el tema actual del sistema.
  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  /// **Función para obtener la imagen del botón según el idioma**
  String _getLocalizedButtonImage(String buttonName, String locale) {
    String folder = "assets/images/Botones"; // Carpeta base de las imágenes

    switch (locale) {
      case "es":
        return "$folder/Espanol/$buttonName.png"; // Español
      case "fr":
        return "$folder/Frances/${buttonName}_3.png"; // Francés
      case "en":
        return "$folder/Ingles/${buttonName}_1.png"; // Inglés
      case "pt":
        return "$folder/Portugues/${buttonName}_2.png"; // Portugués
      default:
        return "$folder/Espanol/$buttonName.png"; // Español por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    final configController = Provider.of<ConfigController>(context);
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.white; // ✅ Se adapta al modo oscuro SOLO para textos
    final idiomaController = Provider.of<IdiomaController>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // 🔹 Ajustes dinámicos del header
    double headerHeight = screenHeight * 0.16; // Altura del header

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            width: screenWidth,
            child: Container(
              height: headerHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/header.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 🔵 Botón Imagen debajo
          Positioned(
            top: screenHeight * 0.2, // Deja espacio debajo del header
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, 'configuracionBluetooth');
                },
                child: Image.asset(
                  'assets/img/botones/botonConfigInicial.png', // 🔵 Ruta de tu imagen de botón
                  width: screenHeight * 0.4, // Opcional: tamaño responsivo
                  height: screenHeight * 0.6,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
