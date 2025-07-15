// lib/src/pages/idioma_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/header_menu_widget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../Controller/idioma_controller.dart';

class IdiomaScreen extends StatelessWidget {
  const IdiomaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Capturamos el MediaQuery original para forzar textScaleFactor
    final mq = MediaQuery.of(context);

    return MediaQuery(
      data: mq.copyWith(textScaleFactor: 1.0),
      child: Scaffold(
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
              top: mq.size.height * 0.18,
              left: 27,
              right: 27,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Idioma',
                      style: const TextStyle(
                        fontFamily: 'PWSeriesFont',
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ► Español
                  _idiomaTile(
                    context,
                    image: 'assets/img/iconos/espanol.png',
                    label: 'Español',
                    idiomaCode: 'es',
                  ),
                  const SizedBox(height: 20),

                  // ► Francés
                  _idiomaTile(
                    context,
                    image: 'assets/img/iconos/frances.png',
                    label: 'Français',
                    idiomaCode: 'fr',
                  ),
                  const SizedBox(height: 20),

                  // ► Inglés
                  _idiomaTile(
                    context,
                    image: 'assets/img/iconos/ingles.png',
                    label: 'English',
                    idiomaCode: 'en',
                  ),
                  const SizedBox(height: 20),

                  // ► Portugués
                  _idiomaTile(
                    context,
                    image: 'assets/img/iconos/portugues.png',
                    label: 'Português',
                    idiomaCode: 'pt',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _idiomaTile(
      BuildContext context, {
        required String image,
        required String label,
        required String idiomaCode,
      }) {
    return ListTile(
      leading: Image.asset(image, width: 50, height: 50),
      title: Text(
        label,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
      ),
      onTap: () {
        // Cambiamos el idioma
        Provider.of<IdiomaController>(context, listen: false)
            .cambiarIdioma(idiomaCode);
        // Volvemos a ControlScreen
        Navigator.pushNamedAndRemoveUntil(context, '/control', (_) => false);
      },
    );
  }
}
