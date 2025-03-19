import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/src/Controller/home_controller.dart';

import '../Controller/ptt_controller.dart';

class ControlScreen extends StatefulWidget {
  final BluetoothDevice connectedDevice;
  final ControlController controller;

  const ControlScreen({
    Key? key,
    required this.connectedDevice,
    required this.controller,
  }) : super(key: key);

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  bool _isReconnecting = false;
  final ControlController _controller = ControlController();
  final PttController _pttController = PttController();

  @override
  void initState() {
    super.initState();
    _monitorConnection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.setDevice(widget.connectedDevice);
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  /// **Monitoreo de la conexión BLE**
  void _monitorConnection() {
    _connectionSubscription = widget.connectedDevice.connectionState.listen(
          (BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint("⚠️ Dispositivo PW desconectado.");

          if (!_isReconnecting) {
            _isReconnecting = true;
            bool reconnected = await _attemptReconnection();

            if (!reconnected) {
              _redirectToHome();
            }
          }
        }
      },
    );
  }

  /// **Intentar reconectar automáticamente**
  Future<bool> _attemptReconnection() async {
    debugPrint("🔄 Intentando reconectar al dispositivo...");

    try {
      await widget.connectedDevice.connect();
      debugPrint("✅ Reconectado exitosamente.");
      _isReconnecting = false;
      return true;
    } catch (e) {
      debugPrint("❌ Falló la reconexión: $e");
      return false;
    }
  }

  /// **Redirigir a la pantalla principal y hacer un escaneo**
  void _redirectToHome() {
    debugPrint("🔴 No se pudo reconectar. Regresando a Home y escaneando...");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.popUntil(context, ModalRoute.withName("home"));
      HomeController().searchDevices();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Dispositivo desconectado. Buscando nuevamente..."),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 150,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/header.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Fondo ajustado
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.97,
              height: MediaQuery.of(context).size.height * 0.3,
              child: Image.asset(
                "assets/images/Teclado/Principal/fondoPrincipal.png",
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Botones sobre el fondo
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    "assets/images/Teclado/Principal/wail.png",
                        () => _controller.toggleWail(),
                    width: 100,
                    height: 70,
                  ),
                  _buildButton(
                    "assets/images/Teclado/Principal/sirena.png",
                        () => _controller.activateSiren(),
                    width: 150,
                    height: 70,
                  ),
                  _buildButton(
                    "assets/images/Teclado/Principal/intercomunicador.png",
                        () => _controller.activateInter(),
                    width: 100,
                    height: 70,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTapDown: (_) => _controller.toggleHorn(),
                    onTapUp: (_) => _controller.toggleHorn(),
                    onTapCancel: () => _controller.toggleHorn(),
                    child: _buildButton(
                      "assets/images/Teclado/Principal/horn.png",
                          () {},
                      width: 100,
                      height: 70,
                    ),
                  ),
                  _buildButton(
                    "assets/images/Teclado/Principal/auxiliar.png",
                        () => _controller.activateAux(),
                    width: 120,
                    height: 70,
                  ),
                  GestureDetector(
                    onTapDown: (_) => _controller.togglePTT(),
                    onTapUp: (_) => _controller.togglePTT(),
                    onTapCancel: () => _controller.togglePTT(),
                    child: _buildButton(
                      "assets/images/Teclado/Principal/ptt.png",
                          () {},
                      width: 100,
                      height: 70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Función para construir botones con tamaño personalizado
  Widget _buildButton(
      String assetPath,
      VoidCallback onPressed, {
        double width = 100,
        double height = 80,
      }) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
