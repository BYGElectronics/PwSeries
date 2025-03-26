import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/control_controller.dart';
import '../Controller/idioma_controller.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ControlConfigScreen extends StatefulWidget {
  final BluetoothDevice connectedDevice;
  final ControlController controller;

  const ControlConfigScreen({
    Key? key,
    required this.connectedDevice,
    required this.controller,
  }) : super(key: key);

  @override
  State<ControlConfigScreen> createState() => _ControlConfigScreenState();
}

class _ControlConfigScreenState extends State<ControlConfigScreen>
    with SingleTickerProviderStateMixin {
  late final BluetoothDevice _device;
  late final ControlController _controller;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isPWMode = false;
  bool _manualDisconnect = false;

  @override
  void initState() {
    super.initState();
    _device = widget.connectedDevice;
    _controller = widget.controller;

    _controller.setDevice(_device);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_animationController);
  }

  String _getLocalizedButtonImage(String buttonName, String locale) {
    String folder = "assets/images/Botones";
    switch (locale) {
      case "es":
        return "$folder/Espanol/$buttonName.png";
      case "fr":
        return "$folder/Frances/${buttonName}_3.png";
      case "en":
        return "$folder/Ingles/${buttonName}_1.png";
      case "pt":
        return "$folder/Portugues/${buttonName}_2.png";
      default:
        return "$folder/Espanol/$buttonName.png";
    }
  }

  void _toggleMode() {
    _animationController.forward().then((_) {
      setState(() {
        // Aquí podrías volver al modo principal si lo deseas
      });
      _animationController.reverse();
    });
  }

  Future<void> _disconnectAndReturnHome() async {
    widget.controller.disconnectDevice();
    if (mounted) {
      Navigator.popUntil(context, ModalRoute.withName("home"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final idiomaController = Provider.of<IdiomaController>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Inicializa los tamaños
    double headerHeight = screenHeight * 0.16;
    double fondoWidth = screenWidth * 0.85;
    double fondoHeight = fondoWidth * 0.5;
    double buttonWidth = fondoWidth * 0.38;
    double buttonHeight = fondoHeight * 0.35;
    double buttonSpacing = screenHeight * 0.02;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🔹 Header
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

          // 🔙 Botón Regresar
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 🧱 Fondo
          Positioned(
            top: screenHeight * 0.34,
            child: Image.asset(
              "assets/images/Teclado/Config/fondoConfig.png",
              width: fondoWidth,
              height: fondoHeight,
              fit: BoxFit.contain,
            ),
          ),

          // 🔘 Botones
          Positioned(
            top: screenHeight * 0.36,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(
                      "assets/images/Teclado/Config/cambioLuces:Aux.png",
                      buttonWidth,
                      buttonHeight,
                      () {
                        if (_controller.connectedDevice != null) {
                          _controller.switchAuxLights();
                        }
                      },
                    ),
                    _buildButton(
                      "assets/images/Teclado/Config/sincLucesyAux.png",
                      buttonWidth,
                      buttonHeight,
                      () {
                        if (_controller.connectedDevice != null) {
                          _controller.syncLightsWithSiren();
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: buttonSpacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(
                      "assets/images/Teclado/Config/cambioHorn.png",
                      buttonWidth,
                      buttonHeight,
                      () {
                        if (_controller.connectedDevice != null) {
                          _controller.changeHornTone();
                        }
                      },
                    ),
                    _buildButton(
                      "assets/images/Teclado/Config/Autoajuste.png",
                      buttonWidth,
                      buttonHeight,
                      () {
                        if (_controller.connectedDevice != null) {
                          _controller.autoAdjustPA();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 200,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // 👈 Regresa al teclado principal
              },
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  "assets/images/Teclado/Config/config:pw.png",
                  width: screenWidth * 0.60,
                ),
              ),
            ),
          ),

          // Botón de Desconectar debajo del selector de teclado
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

  /// Constructor de botones personalizados
  Widget _buildButton(
    String assetPath,
    double width,
    double height,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: width,
        height: height,
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
