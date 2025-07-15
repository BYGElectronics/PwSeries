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
      child: const _ConfiguracionBluetoothView(), // Puedes dejar el const aquí
    );
  }
}

class _ConfiguracionBluetoothView extends StatelessWidget {
  const _ConfiguracionBluetoothView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definimos ancho y alto aquí, dentro del build
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final controller = context.watch<ConfiguracionBluetoothController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Cabecera fija
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(),
          ), //HEADER
          // Contenido responsive
          Positioned(
            top: h * 0.18,
            left: w * 0.05,
            right: w * 0.05,
            bottom: h * 0.05,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'DISPOSITIVOS DISPONIBLES',
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: w * 0.054,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Divider(thickness: 2, color: theme.dividerColor),
                SizedBox(height: h * 0.01),
                Expanded(
                  child:
                  controller.dispositivosEncontrados.isEmpty
                      ? Center(
                    child: Text(
                      'Buscando dispositivos...',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  )
                      : ListView(
                    // Si hay un dispositivo seleccionado, sólo lo mostramos,
                    // si no, mostramos todo el listado.
                    children:
                    controller.dispositivosEncontrados
                        .where(
                          (d) =>
                      controller.selectedDevice == null ||
                          controller.selectedDevice!.address ==
                              d.address,
                    )
                        .map((d) {
                      final showPin =
                          controller.selectedDevice?.address ==
                              d.address;
                      final isConnecting =
                          controller
                              .dispositivoConectando
                              ?.address ==
                              d.address;

                      return Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: TextStyle(
                                      fontFamily:
                                      'PWSeriesFont',
                                      fontSize: w * 0.05,
                                      fontWeight:
                                      FontWeight.bold,
                                      color:
                                      theme
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                  SizedBox(height: h * 0.001),
                                  Text(
                                    d.address,
                                    style: theme
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      fontSize: w * 0.035,
                                      color:
                                      theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap:
                                    () => controller
                                    .togglePinVisibility(d),
                                child: Image.asset(
                                  isConnecting
                                      ? 'assets/images/Botones/Espanol/Conectando.png'
                                      : 'assets/images/Botones/Espanol/Conectar.png',
                                  width: w * 0.4,
                                  height: h * 0.04,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                          if (showPin)
                            SizedBox(height: h * 0.05),
                          if (showPin)
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                Text(
                                  controller.pinIngresado
                                      .replaceAll(
                                    RegExp(r'.'),
                                    '•',
                                  ),
                                  style: TextStyle(
                                    fontSize: w * 0.08,
                                    letterSpacing: w * 0.01,
                                    color:
                                    theme
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                ),
                                SizedBox(height: h * 0.001),
                                SizedBox(
                                  height: h * 0.70,
                                  child: TecladoPinWidget(
                                    onPinComplete: (pin) {
                                      controller.pinIngresado =
                                          pin;
                                      controller
                                          .enviarPinYConectar(
                                        context,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    })
                        .toList(),
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