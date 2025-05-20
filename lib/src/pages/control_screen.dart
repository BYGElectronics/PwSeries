// lib/src/pages/control_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/widgets/header_menu_widget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/tecladoPwWidget.dart';
import '../Controller/idioma_controller.dart';

class ControlScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;
  final ControlController? controller;


  const ControlScreen({
    Key? key,
    this.connectedDevice,
    this.controller,
  }) : super(key: key);

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late final ControlController _controller;
  late VoidCallback _bondListener;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? ControlController();




    if (widget.connectedDevice != null) {
      // 1) Configuramos el dispositivo BLE para usarlo
      _controller.setDevice(widget.connectedDevice!);
      // 2) Registramos como “bond” para monitorizar el emparejamiento
      _controller.setDeviceBond(widget.connectedDevice!);

      // 3) Listener: si realmente pierde el emparejamiento, volvemos a configuración
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
      _controller.shouldSetup.addListener(_bondListener);

      // 4) Empezamos a pedir estado de batería periódicamente
      _controller.startBatteryStatusMonitoring();
      _controller.requestSystemStatus();
    }
  }

  @override
  void dispose() {
    // Limpiamos todos los listeners/timers
    _controller.shouldSetup.removeListener(_bondListener);
    _controller.stopBondMonitoring();
    _controller.stopBatteryStatusMonitoring();
    super.dispose();
  }

  /// Selecciona la imagen del botón según el idioma actual
  String _localizedButton(String name) {
    final code = Provider.of<IdiomaController>(context, listen: false)
        .locale
        .languageCode;
    const folder = "assets/images/Botones";
    switch (code) {
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

          // 2) Icono BLE On/Off según esté emparejado
          Positioned(
            top: screenH * 0.22,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isBleConnected,
              builder: (_, conectado, __) => Image.asset(
                conectado
                    ? "assets/img/iconos/iconoBtOn.png"
                    : "assets/img/iconos/iconoBtOff.png",
                width: 60,
                height: 60,
              ),
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

          // 4) Teclado PW (habilitado solo si sigue emparejado)
          Positioned(
            top: screenH * 0.42,
            child: TecladoPW(
              estaConectado: _controller.isBleConnected,
              controller: _controller,
              fondoWidth: fondoW,
              fondoHeight: fondoH,
            ),
          ),

          // 5) Botón Conectar / Desconectar dinámico
          Positioned(
            bottom: 75,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isBleConnected,
              builder: (_, conectado, __) => GestureDetector(
                onTap: () async {
                  if (conectado) {
                    // Solo corta la conexión BLE; sigue en esta pantalla
                    await _controller.disconnectDevice();
                  } else {
                    // Intenta conexión manual BLE
                    final ok = await _controller.conectarManualBLE(context);
                    if (ok && widget.connectedDevice != null) {
                      // Reiniciamos bond-monitor y batería tras reconectar
                      _controller.setDeviceBond(widget.connectedDevice!);
                      _controller.startBatteryStatusMonitoring();
                      _controller.requestSystemStatus();
                    }
                  }
                },
                child: Image.asset(
                  _localizedButton(conectado ? "Desconectar" : "Conectar"),
                  width: screenW * 0.75,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
