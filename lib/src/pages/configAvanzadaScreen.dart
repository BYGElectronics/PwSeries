// lib/src/pages/configAvanzadaScreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';
import '../Controller/idioma_controller.dart';
import '../localization/app_localization.dart';

class ConfigAvanzadaScreen extends StatelessWidget {
  const ConfigAvanzadaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos el localizador para acceder a los textos traducidos
    final localizer = AppLocalizations.of(context)!;

    // Envolvemos toda la pantalla en Consumer<IdiomaController> para que
    // se vuelva a dibujar cada vez que cambie el idioma.
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      child: Consumer<IdiomaController>(
        builder: (context, idiomaCtrl, _) {
          // Idioma actual (por ejemplo: "es", "en", "pt" o "fr")
          final code = idiomaCtrl.locale.languageCode;

          final theme = Theme.of(context);
          final screenHeight = MediaQuery.of(context).size.height;

          return Scaffold(
            drawer: const AppDrawer(),
            backgroundColor: theme.scaffoldBackgroundColor,
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
                  top: screenHeight * 0.18,
                  left: 27,
                  right: 27,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título “Configuración Avanzada”
                      Center(
                        child: Text(
                          localizer.translate('config_avanzada'),
                          style: TextStyle(
                            fontFamily: 'PWSeriesFont',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Divider(thickness: 2, color: theme.dividerColor),
                      const SizedBox(height: 15),

                      // ► ListTile: Configuración Teclado
                      ListTile(
                        leading: Image.asset(
                          'assets/img/iconos/iconoConfigTeclado.png',
                          width: 50,
                          height: 50,
                        ),
                        title: Text(
                          localizer.translate('config_teclado'),
                          style: TextStyle(
                            fontSize: 21,
                            fontFamily: 'PWSeriesFont',
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/configTeclado');
                        },
                      ),

                      const SizedBox(height: 20),

                      // ► ListTile: Conexión Pw
                      ListTile(
                        leading: Image.asset(
                          'assets/img/iconos/iconoBtConexion.png',
                          width: 50,
                          height: 50,
                        ),
                        title: Text(
                          localizer.translate('conexion_pw'),
                          style: TextStyle(
                            fontSize: 21,
                            fontFamily: 'PWSeriesFont',
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/conexionPw');
                        },
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
