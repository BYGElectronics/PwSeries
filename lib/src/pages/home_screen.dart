// **Importaciones necesarias**
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Asegúrate de que estas rutas sean correctas para tu proyecto
// import 'package:pw/src/Controller/home_controller.dart'; // No se usa directamente en este build
// import 'package:pw/src/Controller/config_controller.dart'; // config_controller no se usa aquí directamente
import 'package:pw/src/Controller/idioma_controller.dart'; // Confirmado: se usa IdiomaController
// import 'package:pw/src/localization/app_localization.dart'; // Descomentar si se usa para textos localizados

// **Clase principal que representa la pantalla de inicio**
class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // --- Ajustes Responsivos ---

    // 1. Altura del Header:
    double headerHeight = (screenHeight * 0.15).clamp(80.0, 150.0);

    // 2. Posicionamiento y Tamaño del Botón Principal:
    final double horizontalPadding = screenWidth * 0.1;
    final double topPaddingForButton = headerHeight + (screenHeight * 0.05);

    double buttonMaxWidth = 600.0;
    double buttonWidth = (screenWidth - (2 * horizontalPadding)) * 1;
    if (buttonWidth > buttonMaxWidth) {
      buttonWidth = buttonMaxWidth;
    }
    // Ajustar la altura máxima del botón para que ocupe una porción significativa pero deje algo de espacio.
    double buttonMaxHeight =
        screenHeight * 0.65; // Aumentado un poco ya que no hay botones abajo
    // Ajustar el 'bottom' del Positioned para el botón principal para que se centre mejor verticalmente
    // si no hay otros elementos debajo.
    double mainButtonBottomPadding = screenHeight * 0.1; // Padding desde abajo

    return Scaffold(
      body: Stack(
        children: [
          // --- Header ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: headerHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "assets/images/header.png",
                  ), // Asegúrate que esta ruta sea correcta
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // --- Botón Principal ---
          Positioned(
            top: topPaddingForButton,
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: mainButtonBottomPadding, // Usar el nuevo padding inferior
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/configuracionBluetooth');
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: buttonWidth,
                    maxHeight: buttonMaxHeight,
                  ),
                  child: Image.asset(
                    'assets/images/Botones/Espanol/ConfigInicial.png', // Ruta de tu imagen de botón
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text(
                            'Error al cargar imagen',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // --- SECCIÓN DE BOTONES DE IDIOMA Y TEMA ELIMINADA ---
          // El Align widget y su contenido (LayoutBuilder, Flex, _buildOptionButton calls)
          // han sido removidos según tu solicitud.
        ],
      ),
    );
  }

  // El método _buildOptionButton ya no es necesario si solo hay un botón principal.
  // Puedes eliminarlo o comentarlo si no se usa en ningún otro lugar.
  /*
  Widget _buildOptionButton({
    required BuildContext context,
    required String imagePath,
    required VoidCallback onTap,
    required bool isColumnLayout,
    required double screenWidth,
    required double buttonBaseSizeRatio, // Ratio para calcular el tamaño del botón
  }) {
    final theme = Theme.of(context);
    double buttonWidth = (screenWidth * (isColumnLayout ? buttonBaseSizeRatio : (buttonBaseSizeRatio / 1.5))).clamp(80.0, 180.0);
    double buttonHeightRatio = 0.4;
    double buttonHeight = buttonWidth * buttonHeightRatio;

    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        imagePath,
        width: buttonWidth,
        height: buttonHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print("Error cargando imagen del botón: $imagePath, Error: $error");
          return Container(
            width: buttonWidth,
            height: buttonHeight,
            color: theme.colorScheme.errorContainer.withOpacity(0.5),
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: theme.colorScheme.onErrorContainer,
                size: buttonHeight * 0.8,
              ),
            ),
          );
        },
      ),
    );
  }
  */

  // El método _getLocalizedButtonImage ya no es necesario si solo hay un botón principal
  // y ese botón no cambia con el idioma. Si el botón principal SÍ cambia, necesitarás esta lógica.
  // Por ahora, lo comento.
  /*
  String _getLocalizedButtonImage(String buttonNameBase, String languageCode) {
    String folder = "assets/images/Botones";
    Map<String, Map<String, String>> langConfig = {
      "es": {"folder": "Espanol", "suffix": ""},
      "en": {"folder": "Ingles", "suffix": "_1"},
      "fr": {"folder": "Frances", "suffix": "_3"},
      "pt": {"folder": "Portugues", "suffix": "_2"},
    };
    Map<String, String> currentLang = langConfig[languageCode] ?? langConfig["es"]!;
    return "$folder/${currentLang['folder']}/$buttonNameBase${currentLang['suffix']}.png";
  }
  */
}
