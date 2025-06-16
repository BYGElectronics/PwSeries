// lib/src/pages/control_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/widgets/header_menu_widget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/tecladoPwWidget.dart';
import '../Controller/estatus.dart';
import '../Controller/idioma_controller.dart';

class ControlScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;
  final ControlController? controller;

  const ControlScreen({Key? key, this.connectedDevice, this.controller})
    : super(key: key);

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late final ControlController _controller;
  VoidCallback? _bondListener; // Ahora nullable

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ControlController();

    // 1) Arrancamos el sondeo cada 1 segundo
    context.read<EstadoSistemaController>().startPolling(
      const Duration(seconds: 1),
    );

    if (widget.connectedDevice != null) {
      // 2) Configuramos BLE
      _controller.setDevice(widget.connectedDevice!);
      _controller.setDeviceBond(widget.connectedDevice!);

      // 3) Listener: si pierde bond, volvemos a configuración
      _bondListener = () {
        if (_controller.shouldSetup.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              'configuracionBluetooth',
              (_) => false,
            );
          });
        }
      };
      _controller.shouldSetup.addListener(_bondListener!);

      // 4) Comenzamos a pedir estado de batería periódicamente
      _controller.startBatteryStatusMonitoring();
      _controller.requestSystemStatus();
    }
  }

  @override
  void dispose() {
    if (_bondListener != null) {
      _controller.shouldSetup.removeListener(_bondListener!);
      _bondListener = null;
    }
    _controller.stopBondMonitoring();
    _controller.stopBatteryStatusMonitoring();
    super.dispose();
  }

  /// Dado el “name” del botón (sin extensión) y el código de idioma,
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
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final fondoW = screenW * 0.85;
    final fondoH = fondoW * 0.5;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1) Header con botón de menú
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),

          // 2) Icono BLE On/Off
          Positioned(
            top: screenH * 0.22,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isBleConnected,
              builder: (_, conectado, __) {
                return Image.asset(
                  conectado
                      ? "assets/img/iconos/iconoBtOn.png"
                      : "assets/img/iconos/iconoBtOff.png",
                  width: 60,
                  height: 60,
                );
              },
            ),
          ),

          // 3) Fondo del teclado
          Positioned(
            top: screenH * 0.40,
            child: Image.asset(
              "assets/img/teclado/fondoPrincipal.png",
              width: fondoW,
              height: fondoH,
              fit: BoxFit.contain,
            ),
          ),

          // 4) Teclado PW (habilitado solo si BLE sigue emparejado)
          Positioned(
            top: screenH * 0.42,
            child: TecladoPW(
              estaConectado: _controller.isBleConnected,
              controller: _controller,
              fondoWidth: fondoW,
              fondoHeight: fondoH,
            ),
          ),

          // 5) Botón Conectar / Desconectar dinámico, dependiente del idioma
          Positioned(
            bottom: 75,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isBleConnected,
              builder: (_, conectado, __) {
                // Envolver la sección de la imagen en Consumer<IdiomaController>
                return Consumer<IdiomaController>(
                  builder: (context, idiomaController, _) {
                    final code = idiomaController.locale.languageCode;
                    // Elegimos el nombre base de la imagen (sin extensión ni sufijo de idioma):
                    final nombre = conectado ? "Desconectar" : "Conectar";
                    final assetPath = _localizedButton(nombre, code);

                    return GestureDetector(
                      onTap: () async {
                        if (conectado) {
                          // Desconectamos BLE
                          await _controller.disconnectDevice();
                        } else {
                          // Intentamos conectar manual
                          final ok = await _controller.conectarManualBLE(
                            context,
                          );
                          if (ok && widget.connectedDevice != null) {
                            _controller.setDeviceBond(widget.connectedDevice!);
                            _controller.startBatteryStatusMonitoring();
                            _controller.requestSystemStatus();
                          }
                        }
                      },
                      child: Image.asset(assetPath, width: screenW * 0.75),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
