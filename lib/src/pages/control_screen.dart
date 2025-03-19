import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/src/Controller/home_controller.dart';
import '../Controller/idioma_controller.dart';
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

class _ControlScreenState extends State<ControlScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  bool _isReconnecting = false;
  bool _isPWMode = true; // Estado inicial de la imagen
  final ControlController _controller = ControlController();
  final PttController _pttController = PttController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _monitorConnection();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.setDevice(widget.connectedDevice);
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _animationController.dispose();
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

  /// **Cambia la imagen y navega a la otra pantalla**
  void _toggleMode() {
    _animationController.forward().then((_) {
      setState(() {
        _isPWMode = !_isPWMode;
      });
      _animationController.reverse();

      // Redirigir a la pantalla correcta después del cambio de imagen
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isPWMode) {
          debugPrint("🔵 Navegando al teclado principal (PW)");
          // Aquí mantienes la pantalla actual
        } else {
          debugPrint("⚙️ Navegando al teclado de configuración");
          Navigator.pushNamed(context, "/configScreen"); // Cambia según ruta
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final idiomaController = Provider.of<IdiomaController>(context);
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Header
          Positioned(
            top: 0,
            width: MediaQuery.of(context).size.width,
            child: Container(
              height: 150,
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
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Fondo del teclado
          Positioned(
            top: MediaQuery.of(context).size.height * 0.34,
            child: Image.asset(
              "assets/images/Teclado/Principal/fondoPrincipal.png",
              width: MediaQuery.of(context).size.width * 0.9,
              fit: BoxFit.contain,
            ),
          ),

          // Botones sobre el fondo
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    GestureDetector(
                      onTapDown: (_) => _controller.toggleWail(),
                      onTapUp: (_) => _controller.toggleWail(),
                      onTapCancel: () => _controller.toggleWail(),
                      child: Image.asset(
                        "assets/images/Teclado/Principal/wail.png",
                        width: 90,
                        height: 65,
                    ),
                    ),

                    _buildButton("assets/images/Teclado/Principal/sirena.png",
                        _controller.activateSiren, width: 130, height: 70),
                    _buildButton("assets/images/Teclado/Principal/intercomunicador.png",
                        _controller.activateInter, width: 90, height: 65),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTapDown: (_) => _controller.toggleHorn(),
                      onTapUp: (_) => _controller.toggleHorn(),
                      onTapCancel: () => _controller.toggleHorn(),
                      child: Image.asset(
                        "assets/images/Teclado/Principal/horn.png",
                        width: 100,
                        height: 60,
                      ),
                    ),
                    _buildButton("assets/images/Teclado/Principal/auxiliar.png",
                        _controller.activateAux, width: 120, height: 80),
                    GestureDetector(
                      onTapDown: (_) => _controller.togglePTT(),
                      onTapUp: (_) => _controller.togglePTT(),
                      onTapCancel: () => _controller.togglePTT(),
                      child: Image.asset(
                        "assets/images/Teclado/Principal/ptt.png",
                        width: 100,
                        height: 60,
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),

          // Imagen de selección de modo (con animación)
          Positioned(
            bottom: 270,
            child: GestureDetector(
              onTap: _toggleMode,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  _isPWMode
                      ? "assets/images/Teclado/Principal/pw:config.png"
                      : "assets/images/Teclado/Config/config:pw.png",
                  width: MediaQuery.of(context).size.width * 0.71,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// **Función para construir botones con tamaños personalizados**
  Widget _buildButton(String assetPath, VoidCallback onPressed,
      {VoidCallback? onTap, double width = 100, double height = 70}) {
    return GestureDetector(
      onTap: _isReconnecting ? null : onPressed,
      onTapDown: _isReconnecting ? null : (_) => onTap?.call(),
      onTapUp: _isReconnecting ? null : (_) => onTap?.call(),
      onTapCancel: _isReconnecting ? null : () => onTap?.call(),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3), // Espacio entre botones
        width: width,
        height: height,
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }


}
