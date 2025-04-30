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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header
          const Positioned(top: 0, left: 0, right: 0, child: HeaderWidget()),

          // Contenido
          Positioned(
            top: h * 0.18,
            left: 27,
            right: 27,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Center(
                  child: Text(
                    'DISPOSITIVOS DISPONIBLES',
                    style: const TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(thickness: 2, color: Colors.black),
                const SizedBox(height: 10),

                // Lista o loading
                Expanded(
                  child: controller.dispositivosEncontrados.isEmpty
                      ? const Center(
                    child: Text(
                      'Buscando dispositivos...',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                              // Nombre + MAC
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: const TextStyle(
                                      fontFamily: 'PWSeriesFont',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    d.address,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),

                              // Botón conectar / conectando
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

                          // Espacio antes del PIN
                          if (showPin) const SizedBox(height: 16),

                          // Teclado + PIN
                          if (showPin)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Muestra el PIN enmascarado
                                Text(
                                  controller.pinIngresado.replaceAll(RegExp(r'.'), '•'),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    letterSpacing: 8,
                                  ),
                                ),
                                const SizedBox(height: 1),

                                // Tu widget de teclado numérico
                                SizedBox(
                                  height: 550, // ajusta según tu diseño
                                  child: TecladoPinWidget(
                                    onPinComplete: (pin) {
                                      // Asigno el pin al controller y disparo el flujo
                                      controller.pinIngresado = pin;
                                      controller.enviarPinYConectar(context);
                                    },                                  ),
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
