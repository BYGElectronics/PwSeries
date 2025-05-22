import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/TecladoPinWidget.dart';
import '../../widgets/header_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';

class ConfiguracionBluetoothScreen extends StatelessWidget {
  const ConfiguracionBluetoothScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConfiguracionBluetoothController>(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _ConfiguracionBluetoothView(),
    );
  }
}

class _ConfiguracionBluetoothView extends StatelessWidget {
  const _ConfiguracionBluetoothView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConfiguracionBluetoothController>();
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: HeaderWidget()),
          Positioned(
            top: h * 0.18,
            left: 27,
            right: 27,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'DISPOSITIVOS DISPONIBLES',
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Divider(thickness: 2, color: theme.dividerColor),
                const SizedBox(height: 10),
                Expanded(
                  child: controller.dispositivosEncontrados.isEmpty
                      ? Center(
                    child: Text(
                      'Buscando dispositivos...',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: controller.dispositivosEncontrados.length,
                    itemBuilder: (_, i) {
                      final d = controller.dispositivosEncontrados[i];
                      final showPin = controller.selectedDevice?.address == d.address;
                      final isConnecting = controller.dispositivoConectando?.address == d.address;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: TextStyle(
                                      fontFamily: 'PWSeriesFont',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    d.address,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => controller.togglePinVisibility(d),
                                child: Image.asset(
                                  isConnecting
                                      ? 'assets/img/botones/conectando.png'
                                      : 'assets/img/botones/Conectar.png',
                                  width: 160,
                                  height: 50,
                                ),
                              ),
                            ],
                          ),
                          if (showPin) const SizedBox(height: 16),
                          if (showPin)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  controller.pinIngresado.replaceAll(RegExp(r'.'), '•'),
                                  style: TextStyle(
                                    fontSize: 30,
                                    letterSpacing: 8,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                SizedBox(
                                  height: 550,
                                  child: TecladoPinWidget(
                                    onPinComplete: (pin) {
                                      controller.pinIngresado = pin;
                                      controller.enviarPinYConectar(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
