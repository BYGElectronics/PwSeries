import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calcular altura del header responsiva
    final headerHeight = screenHeight * 0.15;

    return SizedBox(
      width: screenWidth,
      height: headerHeight,
      child: Image.asset(
        'assets/images/header.png', //  Ruta a tu imagen PNG
        width: screenWidth,
        height: headerHeight,
        fit: BoxFit.cover, // Para que se ajuste bien
      ),
    );
  }
}
