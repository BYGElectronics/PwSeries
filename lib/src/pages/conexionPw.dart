// lib/src/pages/conexionpw_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';

import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';

class ConexionpwScreen extends StatelessWidget {
  const ConexionpwScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConfiguracionBluetoothController>(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _ConexionpwScreen(),
    );
  }
}

class _ConexionpwScreen extends StatelessWidget {
  const _ConexionpwScreen({Key? key}) : super(key: key);

  Widget _actionButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required double width,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'PWSeriesFont',
            fontSize: 18,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Forzamos textScaleFactor = 1.0
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            // 1) Header fijo
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HeaderMenuWidget(),
            ),

            // 2) Cuerpo dinámico
            Positioned(
              top: mq.size.height * 0.18,
              left: 27,
              right: 27,
              bottom: 0,
              child: Consumer<ConfiguracionBluetoothController>(
                builder: (context, config, _) {
                  final dispositivos = config.dispositivosEncontrados;

                  // 2.1) Cabecera común
                  final header = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Conexión PW',
                          style: TextStyle(
                            fontFamily: 'PWSeriesFont',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        thickness: 2,
                        color: Theme.of(context).dividerColor,
                      ),
                      const SizedBox(height: 15),
                    ],
                  );

                  // 2.2) Contenido: sin dispositivos
                  if (dispositivos.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header,
                        const SizedBox(height: 50),
                        Center(
                          child: Text(
                            'No hay ningún dispositivo emparejado',
                            style: TextStyle(
                              fontFamily: 'PWSeriesFont',
                              fontSize: 18,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    );
                  }

                  // 2.3) Contenido: sí hay al menos uno, tomamos el primero
                  final device = dispositivos.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre y MAC
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name,
                                  style: TextStyle(
                                    fontFamily: 'PWSeriesFont',
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  device.address,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Botón Olvidar PW
                          _actionButton(
                            context: context,
                            text: 'Olvidar PW',
                            width: mq.size.width * 0.4,
                            onPressed: () async {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/home',
                                (route) => false,
                              );

                              final removed = await FlutterBluetoothSerial
                                  .instance
                                  .removeDeviceBondWithAddress(device.address);
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
