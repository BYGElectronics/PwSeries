import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/control_controller.dart';
import 'package:pw/src/Controller/home_controller.dart';
import '../Controller/idioma_controller.dart';

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
  bool _isPWMode = true;
  bool _manualDisconnect = false;
  final ControlController _controller = ControlController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// **Función para obtener la imagen del botón según el idioma**
  String _getLocalizedButtonImage(String buttonName, String locale) {
    String folder = "assets/images/Botones"; // 📂 Carpeta base de imágenes

    switch (locale) {
      case "es": // Español
        return "$folder/Espanol/$buttonName.png";
      case "fr": // Francés
        return "$folder/Frances/${buttonName}_3.png";
      case "en": // Inglés
        return "$folder/Ingles/${buttonName}_1.png";
      case "pt": // Portugués
        return "$folder/Portugues/${buttonName}_2.png";
      default: // Español por defecto
        return "$folder/Espanol/$buttonName.png";
    }
  }

  /// **Monitoreo de la conexión BLE**
  void _monitorConnection() {
    _connectionSubscription = widget.connectedDevice.connectionState.listen((
      BluetoothConnectionState state,
    ) async {
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint("⚠️ Dispositivo PW desconectado.");

        if (!_manualDisconnect) {
          // ✅ Solo intenta reconectar si NO fue una desconexión manual
          debugPrint("🔄 Intentando reconectar...");
          bool reconnected = await _attemptReconnection();
          if (!reconnected) {
            _redirectToHome();
          }
        } else {
          debugPrint(
            "🛑 Desconectado manualmente. No se intentará reconectar.",
          );
        }
      }
    });
  }

  /// **Función para desconectar manualmente y regresar a Home**
  Future<void> _disconnectAndReturnHome() async {
    _manualDisconnect = true; // 🔴 Se marca como desconexión manual
    _controller.disconnectDevice(); // ❌ Sin `await` porque es `void`

    if (mounted) {
      Navigator.popUntil(
        context,
        ModalRoute.withName("home"),
      ); // ✅ Volver a la pantalla principal
    }
  }

  @override
  void initState() {
    super.initState();

    _controller.setDevice(widget.connectedDevice);
    _controller.startBatteryStatusMonitoring();

    _monitorConnection();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_animationController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.setDevice(widget.connectedDevice);
    });

    // Envía el protocolo de estado del sistema para verificar nivel de batería
    _controller.requestSystemStatus();
  }

  Widget _buildBatteryIcon() {
    String image;
    switch (_controller.batteryLevel) {
      case BatteryLevel.full:
        image = "assets/images/Estados/battery_full.png";
        break;
      case BatteryLevel.medium:
        image = "assets/images/Estados/battery_medium.png";
        break;
      case BatteryLevel.low:
        image = "assets/images/Estados/battery_low.png";
        break;
    }
    return Image.asset(image, width: 30, height: 30);
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _animationController.dispose();
    _controller.stopBatteryStatusMonitoring();
    super.dispose();
  }

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

  void _redirectToHome() {
    debugPrint("🔴 No se pudo reconectar. Regresando a Home y escaneando...");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.popUntil(context, ModalRoute.withName("home"));
      HomeController().searchDevices();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Dispositivo desconectado. Buscando nuevamente..."),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _toggleMode() {
    _animationController.forward().then((_) {
      final wasPWMode = _isPWMode;

      setState(() {
        _isPWMode = !_isPWMode;
      });

      _animationController.reverse();

      Future.delayed(const Duration(milliseconds: 4), () {
        if (wasPWMode) {
          debugPrint("⚙️ Navegando al teclado de configuración");
          Navigator.pushReplacementNamed(
            context,
            "/controlConfig",
            arguments: {
              "device": widget.connectedDevice,
              "controller": _controller,
            },
          );
        } else {
          debugPrint("🔵 Navegando al teclado principal (PW)");
          Navigator.pushReplacementNamed(
            context,
            "/control",
            arguments: {
              "device": widget.connectedDevice,
              "controller": _controller,
            },
          );
        }
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    final idiomaController = Provider.of<IdiomaController>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Ajuste dinámico del fondo según la pantalla
    double headerHeight = screenHeight * 0.16;
    double fondoWidth = screenWidth * 0.85;
    double fondoHeight = fondoWidth * 0.5;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            width: screenWidth,
            child: Container(
              height: headerHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/header.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 🔋 Aquí colocas la batería:
          Positioned(
            top: 40,
            right: 20,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Image.asset(
                  _controller.batteryImagePath,
                  width: 40,
                  height: 40,
                );
              },
            ),
          ),


          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: screenHeight * 0.34,
            child: Image.asset(
              "assets/images/Teclado/Principal/fondoPrincipal.png",
              width: fondoWidth,
              height: fondoHeight,
              fit: BoxFit.contain,
            ),
          ),

          Positioned(
            top: screenHeight * 0.36,
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
                        width: fondoWidth * 0.25,
                        height: fondoHeight * 0.35,
                      ),
                    ),
                    _buildButton(
                      "assets/images/Teclado/Principal/sirena.png",
                      _controller.activateSiren,
                      width: fondoWidth * 0.40,
                      height: fondoHeight * 0.4,
                    ),
                    _buildButton(
                      "assets/images/Teclado/Principal/intercomunicador.png",
                      _controller.activateInter,
                      width: fondoWidth * 0.25,
                      height: fondoHeight * 0.35,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTapDown: (_) => _controller.toggleHorn(),
                      onTapUp: (_) => _controller.toggleHorn(),
                      onTapCancel: () => _controller.toggleHorn(),
                      child: Image.asset(
                        "assets/images/Teclado/Principal/horn.png",
                        width: fondoWidth * 0.25,
                        height: fondoHeight * 0.35,
                      ),
                    ),
                    _buildButton(
                      "assets/images/Teclado/Principal/auxiliar.png",
                      _controller.activateAux,
                      width: fondoWidth * 0.35,
                      height: fondoHeight * 0.3,
                    ),
                    GestureDetector(
                      onTapDown: (_) => _controller.togglePTT(),
                      onTapUp: (_) => _controller.togglePTT(),
                      onTapCancel: () => _controller.togglePTT(),
                      child: Image.asset(
                        "assets/images/Teclado/Principal/ptt.png",
                        width: fondoWidth * 0.25,
                        height: fondoHeight * 0.35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 200,
            child: GestureDetector(
              onTap: _toggleMode,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  "assets/images/Teclado/Principal/pw:config.png", // 👈 Siempre este en el principal
                  width: screenWidth * 0.60,
                ),
              ),
            ),
          ),

          // Botón de Desconectar debajo del selector de teclado
          Positioned(
            bottom: 60, // 📌 Ajusta la posición según el diseño
            child: GestureDetector(
              onTap: () async => await _disconnectAndReturnHome(),
              child: Image.asset(
                _getLocalizedButtonImage(
                  "Desconectar",
                  idiomaController.locale.languageCode,
                ), // ✅ Usa la imagen en el idioma correcto
                width:
                    MediaQuery.of(context).size.width *
                    0.5, // 📏 Ajuste dinámico
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String assetPath,
    VoidCallback onPressed, {
    double width = 100,
    double height = 70,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
