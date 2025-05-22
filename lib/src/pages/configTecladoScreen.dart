import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../Controller/control_controller.dart';

class ConfigTecladoScreen extends StatelessWidget {
  const ConfigTecladoScreen({Key? key, required this.controller}) : super(key: key);
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
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ControlController>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final bool isConnected = controller.connectedDevice != null;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned(
            top: 0, left: 0, right: 0,
            child: HeaderMenuWidget(),
          ),
          Positioned(
            top: screenHeight * 0.18,
            left: 27, right: 27, bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Configuración Teclado',
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
                  label: 'Autoajuste PA',
                  onTap: () {
                    controller.autoAdjustPA();
                    _showMessage(context, '⏳ Autoajuste PA iniciado');
                  },
                ),

                const SizedBox(height: 20),

                _customTile(
                  context,
                  enabled: isConnected,
                  image: 'assets/img/botones/sincronizacion.png',
                  label: 'Sincronizar Luces y Sirenas',
                  onTap: () {
                    controller.syncLightsWithSiren();
                    _showMessage(context, '🔄 Sincronización iniciada');
                  },
                ),

                const SizedBox(height: 20),

                _customTile(
                  context,
                  enabled: isConnected,
                  image: 'assets/img/botones/cambioHorn.png',
                  label: 'Cambio Horn',
                  onTap: () {
                    controller.changeHornTone();
                    _showMessage(context, '🎺 Tono Horn cambiado');
                  },
                ),

                const SizedBox(height: 20),

                _customTile(
                  context,
                  enabled: isConnected,
                  image: 'assets/img/botones/luces-aux.png',
                  label: 'Auxiliar / Luces',
                  onTap: () {
                    controller.switchAuxLights();
                    _showMessage(context, '💡 Modo Aux/Luces cambiado');
                  },
                ),
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
          _showMessage(context, '❗ Dispositivo no conectado');
        } else {
          onTap();
        }
      },
    );
  }
}
