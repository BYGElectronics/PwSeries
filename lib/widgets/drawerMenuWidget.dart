// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return Drawer(
      width: screenW * 0.8,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- CABECERA CON LOGO-CLIENTE COMO BOTÓN ---
            Container(
              color: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: kToolbarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/control');
                    },
                    child: const Text(
                      'PW series',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PWSeriesFont',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Configuración Avanzada
            ListTile(
              leading: Image.asset(
                'assets/img/iconos/iconoLogo.png',
                width: 50,
                height: 50,
              ),
              title: const Text(
                'Configuración Avanzada',
                style: TextStyle(fontSize: 20, fontFamily: 'PWSeriesFont'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, 'configAvanzada');
              },
            ),

            const SizedBox(height: 20),

            // Submenú de Configuración
            ExpansionTile(
              leading: Image.asset(
                'assets/img/iconos/iconoConfig.png',
                width: 50,
                height: 50,
              ),
              title: const Text(
                'Configuración',
                style: TextStyle(fontSize: 20, fontFamily: 'PWSeriesFont'),
              ),
              childrenPadding: const EdgeInsets.only(left: 72.0),
              children: [
                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/iconoIdiomas.png',
                    width: 32,
                    height: 32,
                  ),
                  title: const Text('Idiomas'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'idioma');
                  },
                ),
                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/iconoDarkMode.png',
                    width: 32,
                    height: 32,
                  ),
                  title: const Text('Dark Mode'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'themeConfig');
                  },
                ),
                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/iconoTextSize.png',
                    width: 32,
                    height: 32,
                  ),
                  title: const Text('Tamaño de Texto'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'textSize');
                  },
                ),
                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/iconoAcercaDe.png',
                    width: 32,
                    height: 32,
                  ),
                  title: const Text('Acerca de'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'acercaDe');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
