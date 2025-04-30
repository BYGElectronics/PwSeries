// lib/src/pages/config_teclado_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../Controller/control_controller.dart';

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
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ControlController>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // Comprueba si hay conexión BLE establecida
    final bool isConnected = controller.connectedDevice != null;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
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
                const Center(
                  child: Text(
                    'Configuración Teclado',
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(thickness: 2, color: Colors.black),
                const SizedBox(height: 15),

                // Autoajuste PA
                ListTile(
                  leading: Image.asset('assets/img/botones/PA.png', width: 80, height: 80),
                  title: const Text(
                    'Autoajuste PA',
                    style: TextStyle(fontSize: 21, fontFamily: 'Roboto-bold'),
                  ),
                  enabled: isConnected,
                  onTap: () {
                    if (!isConnected) {
                      _showMessage(context, '❗ Dispositivo no conectado');
                      return;
                    }
                    controller.autoAdjustPA();
                    _showMessage(context, '⏳ Autoajuste PA iniciado');
                  },
                ),
                const SizedBox(height: 20),

                // Sincronización luces y sirenas
                ListTile(
                  leading: Image.asset('assets/img/botones/sincronizacion.png', width: 80, height: 80),
                  title: const Text(
                    'Sincronizar Luces y Sirenas',
                    style: TextStyle(fontSize: 21, fontFamily: 'Roboto-bold'),
                  ),
                  enabled: isConnected,
                  onTap: () {
                    if (!isConnected) {
                      _showMessage(context, '❗ Dispositivo no conectado');
                      return;
                    }
                    controller.syncLightsWithSiren();
                    _showMessage(context, '🔄 Sincronización iniciada');
                  },
                ),
                const SizedBox(height: 20),

                // Cambio de tono Horn
                ListTile(
                  leading: Image.asset('assets/img/botones/cambioHorn.png', width: 80, height: 80),
                  title: const Text(
                    'Cambio Horn',
                    style: TextStyle(fontSize: 21, fontFamily: 'Roboto-bold'),
                  ),
                  enabled: isConnected,
                  onTap: () {
                    if (!isConnected) {
                      _showMessage(context, '❗ Dispositivo no conectado');
                      return;
                    }
                    controller.changeHornTone();
                    _showMessage(context, '🎺 Tono Horn cambiado');
                  },
                ),
                const SizedBox(height: 20),

                // Auxiliar / Luces
                ListTile(
                  leading: Image.asset('assets/img/botones/luces-aux.png', width: 80, height: 80),
                  title: const Text(
                    'Auxiliar / Luces',
                    style: TextStyle(fontSize: 21, fontFamily: 'Roboto-bold'),
                  ),
                  enabled: isConnected,
                  onTap: () {
                    if (!isConnected) {
                      _showMessage(context, '❗ Dispositivo no conectado');
                      return;
                    }
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
}
