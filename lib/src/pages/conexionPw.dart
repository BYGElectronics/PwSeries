// lib/src/pages/conexion_pw_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/drawerMenuWidget.dart';    // define AppDrawer()
import '../../widgets/header_menu_widget.dart';  // botón hamburguesa
import '../Controller/ConfiguracionBluetoothController.dart';

class ConexionpwScreen extends StatelessWidget {
  const ConexionpwScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _ConexionpwScreen(),
    );
  }
}

class _ConexionpwScreen extends StatelessWidget {
  const _ConexionpwScreen({Key? key}) : super(key: key);

  Widget _actionButton({
    required String text,
    required VoidCallback onPressed,
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'PWSeriesFont',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // 1) Header con hamburguesa
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),

          // 2) Contenido
          Positioned(
            top: screenH * 0.18,
            left: 27,
            right: 27,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título centrado
                Center(
                  child: Text(
                    'Conexión PW',
                    style: const TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Línea negra bajo el título
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(thickness: 2, color: Colors.black),
                ),

                const SizedBox(height: 15),

                // Fila con nombre/address y botones
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Izquierda: BTPW + dirección
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'BTPW',
                            style: TextStyle(
                              fontFamily: 'PWSeriesFont',
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'EC:64:C9:41:C3:BA',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Derecha: los dos botones
                    Column(
                      children: [
                        _actionButton(
                          text: 'Olvidar PW',
                          width: screenW * 0.4,
                          onPressed: () {
                            // tu lógica para "olvidar"
                          },
                        ),
                        const SizedBox(height: 12),
                        _actionButton(
                          text: 'Desconectar',
                          width: screenW * 0.4,
                          onPressed: () {
                            // tu lógica para "desconectar"
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // Empuja todo hacia arriba
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
