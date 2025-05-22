// lib/src/pages/acercade_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';

class AcercadeScreen extends StatelessWidget {
  const AcercadeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _AcercadeScreen(),
    );
  }
}

class _AcercadeScreen extends StatelessWidget {
  const _AcercadeScreen({Key? key}) : super(key: key);

  static final Uri _whatsappUri = Uri.parse(
    'https://api.whatsapp.com/send/?phone=573115997562'
        '&text=Hola%2C+mi+nombre+es+Pw+Series+y+me+gustar%C3%ADa+m%C3%A1s+informaci%C3%B3n.'
        '&type=phone_number&app_absent=0',
  );

  Future<void> _launchWhatsApp(BuildContext context) async {
    if (await canLaunchUrl(_whatsappUri)) {
      await launchUrl(_whatsappUri, mode: LaunchMode.externalApplication);
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),
          Positioned(
            top: screenH * 0.18,
            left: 27,
            right: 27,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Acerca De',
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    thickness: 2,
                    color: theme.dividerColor,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Desarrollado Por:',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/img/iconos/byg_electronics.png',
                    width: screenW * 0.6,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
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
                Center(
                  child: Text(
                    'Version 1.0.1',
                    style: theme.textTheme.bodySmall?.copyWith(
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
