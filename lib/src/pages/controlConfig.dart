import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/idioma_controller.dart';

class ControlConfigScreen extends StatelessWidget {
  const ControlConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final idiomaController = Provider.of<IdiomaController>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // 🔹 Ajustes dinámicos del header
    double headerHeight = screenHeight * 0.16; // 18% de la pantalla

    // Ajuste dinámico del fondo según la pantalla
    double fondoWidth = screenWidth * 0.85;
    double fondoHeight = fondoWidth * 0.5;

    // Ajuste dinámico de los botones
    double buttonWidth = fondoWidth * 0.38;
    double buttonHeight = fondoHeight * 0.35;
    double buttonSpacing = screenHeight * 0.02;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🔹 Header Responsivo
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
          // 🔹 Botón de regreso
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 🔹 Fondo del teclado
          Positioned(
            top: screenHeight * 0.34,
            child: Image.asset(
              "assets/images/Teclado/Config/fondoConfig.png",
              width: fondoWidth,
              height: fondoHeight,
              fit: BoxFit.contain,
            ),
          ),

          // 🔹 Botones sobre el fondo (Distribución en cuadrícula)
          Positioned(
            top: screenHeight * 0.36,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(
                      "assets/images/Teclado/Config/cambioLuces:Aux.png",
                      buttonWidth,
                      buttonHeight,
                      () {
                        print("Botón Cambio Luces & Aux presionado");
                      },
                    ),
                    _buildButton(
                      "assets/images/Teclado/Config/sincLucesyAux.png",
                      buttonWidth,
                      buttonHeight,
                      () {
                        print("Botón Sinc. Luces y Aux presionado");
                      },
                    ),
                  ],
                ),
                SizedBox(height: buttonSpacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(
                      "assets/images/Teclado/Config/cambioHorn.png",
                      buttonWidth,
                      buttonHeight,
                      () {},
                    ),
                    _buildButton(
                      "assets/images/Teclado/Config/Autoajuste.png",
                      buttonWidth,
                      buttonHeight,
                      () {
                        print("Botón Autoajuste presionado");
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// **Función para construir botones con tamaños personalizados**
  Widget _buildButton(
    String assetPath,
    double width,
    double height,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 5,
        ), // Espacio entre botones
        width: width,
        height: height,
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
