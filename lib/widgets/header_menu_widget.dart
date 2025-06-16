// lib/widgets/header_widget.dart
import 'package:flutter/material.dart';

class HeaderMenuWidget extends StatelessWidget {
  const HeaderMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calcular altura del header responsiva (incluye status bar)
    final headerHeight = screenHeight * 0.15;
    // Altura de la barra de estado (notch / status bar)
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SizedBox(
      width: screenWidth,
      height: headerHeight,
      child: Stack(
        children: [
          // Fondo del header
          Image.asset(
            'assets/img/header/header.png',
            width: screenWidth,
            height: headerHeight,
            fit: BoxFit.cover,
          ),

          // Botón hamburguesa
          Positioned(
            left: 8,
            top: statusBarHeight + 4, // para separarlo del notch/status bar
            child: Builder(
              builder:
                  (ctx) => IconButton(
                    icon: const Icon(Icons.menu, size: 32, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
            ),
          ),

          // (Opcional) logo/texto centrado
          // Positioned.fill(
          //   child: Center(
          //     child: Text(
          //       'PW series',
          //       style: TextStyle(
          //         color: Colors.white,
          //         fontSize: headerHeight * 0.3,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
