import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../Controller/control_controller.dart';
import '../localization/app_localization.dart';

class ConfigTecladoScreen extends StatelessWidget {
  const ConfigTecladoScreen({Key? key, required this.controller})
      : super(key: key);

  final ControlController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ControlController>.value(
      value: controller,
      child: const _ConfigTecladoView(),
    );
  }
}

class _ConfigTecladoView extends StatelessWidget {
  const _ConfigTecladoView({Key? key}) : super(key: key);

  void _showMessage(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ControlController>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final localizer = AppLocalizations.of(context)!;
    final bool isConnected = controller.connectedDevice != null;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),
          Positioned(
            top: screenHeight * 0.18,
            left: 27,
            right: 27,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    localizer.translate('config_teclado'),
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Divider(thickness: 2, color: theme.dividerColor),
                const SizedBox(height: 15),

                _customTile(
                  context,
                  enabled: isConnected,
                  image: 'assets/img/botones/PA.png',
                  label: localizer.translate('autoajuste_pa'),
                  onTap: () {
                    controller.autoAdjustPA();
                    _showMessage(context, '⏳ ${localizer.translate('msg_autoajuste_pa')}');
                  },
                ),

                const SizedBox(height: 20),

                _customTile(
                  context,
                  enabled: isConnected,
                  image: 'assets/img/botones/sincronizacion.png',
                  label: localizer.translate('sincronizar_luces'),
                  onTap: () {
                    controller.syncLightsWithSiren();
                    _showMessage(context, '🔄 ${localizer.translate('msg_sincronizacion')}');
                  },
                ),

                const SizedBox(height: 20),

                _customTile(
                  context,
                  enabled: isConnected,
                  image: 'assets/img/botones/cambioHorn.png',
                  label: localizer.translate('cambio_horn'),
                  onTap: () {
                    controller.changeHornTone();
                    _showMessage(context, '🎺 ${localizer.translate('msg_cambio_horn')}');
                  },
                ),

                const SizedBox(height: 20),

                _customTile(
                  context,
                  enabled: isConnected,
                  image: 'assets/img/botones/luces-aux.png',
                  label: localizer.translate('aux_luces'),
                  onTap: () {
                    controller.switchAuxLights();
                    _showMessage(context, '💡 ${localizer.translate('msg_aux_luces')}');
                  },
                ),

                const SizedBox(height: 20),

                _customTile(
                  context,
                  enabled: isConnected,
                  image: 'assets/img/botones/sync_pw.png',
                  label: localizer.translate('sincronizar_pw'),
                  onTap: () {
                    controller.sendSyncAppToPw();
                    _showMessage(context, '🔄 ${localizer.translate('msg_sincronizacionpw')}');
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customTile(
      BuildContext context, {
        required bool enabled,
        required String image,
        required String label,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final localizer = AppLocalizations.of(context)!;

    return ListTile(
      leading: Image.asset(image, width: 80, height: 80),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 21,
          fontFamily: 'Roboto-bold',
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      enabled: enabled,
      onTap: () {
        if (!enabled) {
          _showMessage(context, '❗ ${localizer.translate('dispositivo_no_conectado')}');
        } else {
          onTap();
        }
      },
    );
  }
}
