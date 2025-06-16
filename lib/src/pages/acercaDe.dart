// lib/src/pages/acercade_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';
import '../Controller/idioma_controller.dart';
import '../localization/app_localization.dart';

class AcercadeScreen extends StatelessWidget {
  const AcercadeScreen({Key? key}) : super(key: key);

  /// Dado el "name" base del botón (sin extensión) y el código de idioma,
  /// devuelve la ruta correcta dentro de assets/images/Botones/...
  String _localizedButton(String name, String languageCode) {
    const folder = "assets/images/Botones";
    switch (languageCode) {
      case "es":
        return "$folder/Espanol/$name.png";
      case "en":
        return "$folder/Ingles/${name}_1.png";
      case "pt":
        return "$folder/Portugues/${name}_2.png";
      case "fr":
        return "$folder/Frances/${name}_3.png";
      default:
        return "$folder/Espanol/$name.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el localizador para acceder a las traducciones
    final localizer = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      builder: (context, _) {
        return Consumer<IdiomaController>(
          builder: (context, idiomaCtrl, __) {
            // El consumer redibuja esta pantalla cada vez que cambia el idioma
            final code = idiomaCtrl.locale.languageCode;

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              drawer: const AppDrawer(),
              body: Stack(
                children: [
                  // 1) Header con botón de menú
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: HeaderMenuWidget(),
                  ),

                  // 2) Contenido principal
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.18,
                    left: 27,
                    right: 27,
                    bottom: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título "Acerca De"
                        Center(
                          child: Text(
                            localizer.translate('acercaDe'),
                            style: TextStyle(
                              fontFamily: 'PWSeriesFont',
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Divider(
                          thickness: 2,
                          color: Theme.of(context).dividerColor,
                        ),
                        const SizedBox(height: 15),

                        // "Desarrollado por:"
                        Text(
                          localizer.translate('desarrollado_por'),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Logo central
                        Center(
                          child: Image.asset(
                            'assets/img/iconos/byg_electronics.png',
                            width: MediaQuery.of(context).size.width * 0.6,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const Spacer(),

                        Center(
                          child: Consumer<IdiomaController>(
                            builder: (context, idiomaCtrl, _) {
                              // 1) Obtenemos el código de idioma actual ("es", "en", "pt" o "fr")
                              final code = idiomaCtrl.locale.languageCode;
                              // 2) Nombre base fijo de la imagen (sin sufijo ni extensión)
                              const String nombreBase = "Contactanos";
                              // 3) Construimos la ruta completa usando tu helper _localizedButton(...)
                              final assetPath = _localizedButton(
                                nombreBase,
                                code,
                              );

                              return GestureDetector(
                                onTap: () => _launchWhatsApp(context),
                                child: Image.asset(
                                  assetPath,
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Label de versión
                        Center(
                          child: Text(
                            "${localizer.translate('version')} 1.0.1",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------
  // Método auxiliar para abrir WhatsApp
  // --------------------------------------------------
  Future<void> _launchWhatsApp(BuildContext context) async {
    final localizer = AppLocalizations.of(context)!;
    final whatsappUri = Uri.parse(
      'https://api.whatsapp.com/send/?phone=573115997562'
      '&text=Hola%2C+mi+nombre+es+Pw+Series+y+me+gustar%C3%ADa+m%C3%A1s+informaci%C3%B3n.'
      '&type=phone_number&app_absent=0',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizer.translate('whatsapp_error'))),
      );
    }
  }
}
