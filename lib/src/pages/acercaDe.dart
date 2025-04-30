// lib/src/pages/acercade_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/drawerMenuWidget.dart';       // define AppDrawer()
import '../../widgets/header_menu_widget.dart';     // botón hamburguesa
import '../Controller/ConfiguracionBluetoothController.dart';

class AcercadeScreen extends StatelessWidget {
  const AcercadeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Proveedor para el controller, si lo necesitas para algo
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _AcercadeScreen(),
    );
  }
}

class _AcercadeScreen extends StatelessWidget {
  const _AcercadeScreen({Key? key}) : super(key: key);

  // URI de WhatsApp con tu número y mensaje predefinido
  static final Uri _whatsappUri = Uri.parse(
    'https://api.whatsapp.com/send/?phone=573115997562'
        '&text=Hola%2C+mi+nombre+es+Pw+Series+y+me+gustar%C3%ADa+m%C3%A1s+informaci%C3%B3n.'
        '&type=phone_number&app_absent=0',
  );

  Future<void> _launchWhatsApp(BuildContext context) async {
    if (await canLaunchUrl(_whatsappUri)) {
      await launchUrl(
        _whatsappUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      // aquí usas tu Drawer reutilizable
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // 1) Header con botón hamburguesa
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),

          // 2) Contenido principal
          Positioned(
            top: screenH * 0.18,
            left: 27,
            right: 27,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Center(
                  child: Text(
                    'Acerca De',
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

                // Texto "Desarrollado Por:"
                const Text(
                  'Desarrollado Por:',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                // Logo centrado
                Center(
                  child: Image.asset(
                    'assets/img/iconos/byg_electronics.png',
                    width: screenW * 0.6,
                    fit: BoxFit.contain,
                  ),
                ),

                // Empuja el botón hacia el fondo
                const Spacer(),

                // Botón "Contactanos"
                Center(
                  child: GestureDetector(
                    onTap: () => _launchWhatsApp(context),
                    child: Image.asset(
                      'assets/img/botones/contactanos.png',
                      width: screenW * 0.8,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Texto de versión
                Center(
                  child: Text(
                    'Version 1.0.1',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
