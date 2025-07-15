// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../src/Controller/idioma_controller.dart';
import '../src/localization/app_localization.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Capturamos el MediaQuery original para sobreescribir el textScaleFactor
    final mq = MediaQuery.of(context);

    return Consumer<IdiomaController>(
      builder: (context, idiomaCtrl, _) {
        final localizer = AppLocalizations.of(context)!;

        // Forzamos textScaleFactor a 1.0 dentro del Drawer
        return MediaQuery(
          data: mq.copyWith(textScaleFactor: 1.0),
          child: Drawer(
            width: screenW * 0.89,
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
                          child: Text(
                            localizer.translate('pw_series'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 35,
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
                    title: Text(
                      localizer.translate('config_avanzada'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'PWSeriesFont',
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/configAvanzada');
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
                    title: Text(
                      localizer.translate('configuracion'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'PWSeriesFont',
                      ),
                    ),
                    childrenPadding: const EdgeInsets.only(left: 72.0),
                    children: [
                      ListTile(
                        leading: Image.asset(
                          'assets/img/iconos/iconoIdiomas.png',
                          width: 32,
                          height: 32,
                        ),
                        title: Text(
                          localizer.translate('idiomas'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'PWSeriesFont',
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/idioma');
                        },
                      ),
                      ListTile(
                        leading: Image.asset(
                          'assets/img/iconos/iconoDarkMode.png',
                          width: 32,
                          height: 32,
                        ),
                        title: Text(
                          localizer.translate('dark_mode'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'PWSeriesFont',
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/themeConfig');
                        },
                      ),
                      ListTile(
                        leading: Image.asset(
                          'assets/img/iconos/iconoTextSize.png',
                          width: 32,
                          height: 32,
                        ),
                        title: Text(
                          localizer.translate('text_size'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'PWSeriesFont',
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/textSize');
                        },
                      ),
                      ListTile(
                        leading: Image.asset(
                          'assets/img/iconos/iconoAcercaDe.png',
                          width: 32,
                          height: 32,
                        ),
                        title: Text(
                          localizer.translate('acerca_de'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'PWSeriesFont',
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/acercaDe');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
