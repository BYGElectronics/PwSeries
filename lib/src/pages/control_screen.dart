// lib/src/pages/control_screen.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../Controller/bluetooth_helper.dart'; // o 'package:pw/src/utils/bluetooth_helper.dart' si lo tienes ahí
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

class _ControlScreenState extends State<ControlScreen>
    with WidgetsBindingObserver {
  late final ControlController _controller;
  VoidCallback? _bondListener;
  bool _resumeAuto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = widget.controller ?? ControlController();
    context.read<EstadoSistemaController>().startPolling(
      const Duration(seconds: 1),
    );

    if (widget.connectedDevice != null) {
      _controller.setDevice(widget.connectedDevice!);
      _controller.setDeviceBond(widget.connectedDevice!);

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
      _controller.startBatteryStatusMonitoring();
      _controller.requestSystemStatus();
    }

    // Al primer frame, auto–conectar A2DP
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnectA2dp();
      _resumeAuto = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (_bondListener != null) {
      _controller.shouldSetup.removeListener(_bondListener!);
      _bondListener = null;
    }
    _controller.stopBondMonitoring();
    _controller.stopBatteryStatusMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Cuando la app va a background o inactivo, desconecta TODO
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _disconnectAll();
    }

    // Al volver al foreground, reintenta A2DP
    if (state == AppLifecycleState.resumed && _resumeAuto) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoConnectA2dp());
    }
  }

  /// Desconecta BLE y Classic A2DP de forma no bloqueante
  void _disconnectAll() {
    // Desconectar BLE
    _controller.disconnectDevice();
    print('🔌 BLE desconectado al background/swipe');

    // Desconectar Classic A2DP
    BluetoothHelper.disconnectBluetoothAudio();
    print('🔌 A2DP clásico desconectado al background/swipe');
  }

  /// Intenta conectar A2DP al dispositivo "BTPW"
  void _autoConnectA2dp() {
    BluetoothHelper.connectBluetoothAudio().then((ok) {
      print('🔊 A2DP auto–conectado: $ok');
      if (!ok && Platform.isAndroid) {
        AndroidIntent(action: 'android.settings.BLUETOOTH_SETTINGS').launch();
      }
    });
  }

  String _localizedButton(String name, String code) {
    const folder = "assets/images/Botones";
    switch (code) {
      case 'es':
        return "$folder/Espanol/$name.png";
      case 'en':
        return "$folder/Ingles/${name}_1.png";
      case 'pt':
        return "$folder/Portugues/${name}_2.png";
      case 'fr':
        return "$folder/Frances/${name}_3.png";
      default:
        return "$folder/Espanol/$name.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final fw = w * 0.85;
    final fh = fw * 0.5;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),
          Positioned(
            top: h * 0.22,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isBleConnected,
              builder:
                  (_, bleConnected, __) => Image.asset(
                    bleConnected
                        ? "assets/img/iconos/iconoBtOn.png"
                        : "assets/img/iconos/iconoBtOff.png",
                    width: 60,
                    height: 60,
                  ),
            ),
          ),
          Positioned(
            top: h * 0.40,
            child: Image.asset(
              "assets/img/teclado/fondoPrincipal.png",
              width: fw,
              height: fh,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: h * 0.42,
            child: TecladoPW(
              estaConectado: _controller.isBleConnected,
              controller: _controller,
              fondoWidth: fw,
              fondoHeight: fh,
            ),
          ),
          Positioned(
            bottom: 75,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isBleConnected,
              builder:
                  (_, bleConnected, __) => Consumer<IdiomaController>(
                    builder: (context, idioma, _) {
                      final code = idioma.locale.languageCode;
                      final name = bleConnected ? "Desconectar" : "Conectar";
                      final assetPath = _localizedButton(name, code);
                      return GestureDetector(
                        onTap: () {
                          if (bleConnected) {
                            // Desconectar BLE
                            _controller.disconnectDevice();
                            // Desconectar A2DP clásico
                            BluetoothHelper.disconnectBluetoothAudio().then((
                              ok,
                            ) {
                              print(
                                '🔊 A2DP clásico desconectado por botón: $ok',
                              );
                            });
                          } else {
                            // Plan A: conectar BLE
                            _controller.conectarManualBLE(context).then((
                              okBle,
                            ) {
                              if (okBle && widget.connectedDevice != null) {
                                _controller.setDeviceBond(
                                  widget.connectedDevice!,
                                );
                                _controller.startBatteryStatusMonitoring();
                                _controller.requestSystemStatus();
                              } else {
                                // Plan B: conectar A2DP clásico
                                BluetoothHelper.connectBluetoothAudio().then((
                                  okClassic,
                                ) {
                                  print(
                                    '🔊 A2DP clásico conectado por botón: $okClassic',
                                  );
                                  if (!okClassic && Platform.isAndroid) {
                                    AndroidIntent(
                                      action:
                                          'android.settings.BLUETOOTH_SETTINGS',
                                    ).launch();
                                  }
                                });
                              }
                            });
                          }
                        },
                        child: Image.asset(assetPath, width: w * 0.75),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}