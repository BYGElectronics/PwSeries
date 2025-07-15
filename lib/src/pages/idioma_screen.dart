import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/header_menu_widget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../Controller/idioma_controller.dart';
import '../localization/app_localization.dart';

class IdiomaScreen extends StatelessWidget {
  const IdiomaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final localizer = AppLocalizations.of(context)!;

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
                    child: Column(
                      children: [
                        Text(
                          localizer.translate('idioma'),
                          style: const TextStyle(
                            fontFamily: 'PWSeriesFont',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 2,
                          width: 500,
                          color: Theme.of(context).dividerColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _idiomaTile(
                    context,
                    image: 'assets/img/iconos/espanol.png',
                    label: localizer.translate('idioma_es'),
                    idiomaCode: 'es',
                  ),
                  const SizedBox(height: 20),

                  _idiomaTile(
                    context,
                    image: 'assets/img/iconos/frances.png',
                    label: localizer.translate('idioma_fr'),
                    idiomaCode: 'fr',
                  ),
                  const SizedBox(height: 20),

                  _idiomaTile(
                    context,
                    image: 'assets/img/iconos/ingles.png',
                    label: localizer.translate('idioma_en'),
                    idiomaCode: 'en',
                  ),
                  const SizedBox(height: 20),

                  _idiomaTile(
                    context,
                    image: 'assets/img/iconos/portugues.png',
                    label: localizer.translate('idioma_pt'),
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
        Provider.of<IdiomaController>(context, listen: false)
            .cambiarIdioma(idiomaCode);
        Navigator.pushNamedAndRemoveUntil(context, '/control', (_) => false);
      },
    );
  }
}
