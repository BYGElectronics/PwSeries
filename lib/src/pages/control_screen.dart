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
            setState(() {}); // Bloquea los botones visualmente

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
      setState(() {}); // Reactiva los botones
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Header
          Positioned(
            top: 0,
            width: screenWidth,
            height: screenHeight * 0.15,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/header.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Botón de regreso
          Positioned(
            top: screenHeight * 0.05,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Fondo del teclado
          Positioned(
            top: screenHeight * 0.26,
            width: screenWidth * 0.9,
            height: screenHeight * 0.35,
            child: Image.asset(
              "assets/images/Teclado/Principal/fondoPrincipal.png",
              fit: BoxFit.contain,
            ),
          ),

          // Botones sobre el fondo, más pegados
          Positioned(
            top: screenHeight * 0.35,
            width: screenWidth * 0.9,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTapDown: (_) => _controller.toggleWail(),
                      onTapUp: (_) => _controller.toggleWail(),
                      onTapCancel: () => _controller.toggleWail(),
                      child: _buildButton(
                          "assets/images/Teclado/Principal/wail.png",
                              () {},
                          screenWidth * 0.22),
                    ), SizedBox(width: screenWidth * 0),
                    SizedBox(width: screenWidth * 0), // Espaciado reducido
                    _buildButton("assets/images/Teclado/Principal/sirena.png",
                        _controller.activateSiren, screenWidth * 0.37),
                    SizedBox(width: screenWidth * 0.01),
                    _buildButton(
                        "assets/images/Teclado/Principal/intercomunicador.png",
                        _controller.activateInter,
                        screenWidth * 0.22),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01), // Espaciado reducido
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTapDown: (_) => _controller.toggleHorn(),
                      onTapUp: (_) => _controller.toggleHorn(),
                      onTapCancel: () => _controller.toggleHorn(),
                      child: _buildButton(
                          "assets/images/Teclado/Principal/horn.png",
                              () {},
                          screenWidth * 0.22),
                    ), SizedBox(width: screenWidth * 0.01),
                    _buildButton("assets/images/Teclado/Principal/auxiliar.png",
                        _controller.activateAux, screenWidth * 0.30),
                    SizedBox(width: screenWidth * 0.01),
                    GestureDetector(
                      onTapDown: (_) => _controller.togglePTT(),
                      onTapUp: (_) => _controller.togglePTT(),
                      onTapCancel: () => _controller.togglePTT(),
                      child: _buildButton(
                          "assets/images/Teclado/Principal/ptt.png",
                              () {},
                          screenWidth * 0.22),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mensaje de reconexión
          if (_isReconnecting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        "Reconectando...",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Función para construir botones con opacidad si está desconectado
  Widget _buildButton(String assetPath, VoidCallback onPressed, double size) {
    return GestureDetector(
      onTap: _isReconnecting ? null : onPressed,
      child: Opacity(
        opacity: _isReconnecting ? 0.5 : 1.0,
        child: SizedBox(
          width: size,
          height: size * 0.5,
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
