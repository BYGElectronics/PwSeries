import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pw/src/localization/app_localization.dart';
import '../Controller/control_controller.dart';

class ControlScreen extends StatefulWidget {
  final BluetoothDevice connectedDevice;

  const ControlScreen({super.key, required this.connectedDevice});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final ControlController _controller = ControlController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.setDevice(widget.connectedDevice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen del encabezado
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
          // Flecha para regresar
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Regresar a HomeScreen
              },
            ),
          ),

          // 📡 Mostrar el nombre del dispositivo conectado
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "${AppLocalizations.of(context)?.translate('connected_to') ?? 'Conectado a'}: ${widget.connectedDevice.platformName}",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),

          // 🛠 Botones de control
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 250),

                _controlButton(
                  AppLocalizations.of(context)?.translate('siren') ?? "Sirena",
                  _controller.activateSiren,
                  Colors.red,
                ),
                _controlButton(
                  AppLocalizations.of(context)?.translate('auxiliary') ??
                      "Auxiliar",
                  _controller.activateAux,
                  Colors.orange,
                ),
                _controlButton(
                  AppLocalizations.of(context)?.translate('horn') ?? "Horn",
                  _controller.activateHorn,
                  Colors.blue,
                ),
                _controlButton(
                  AppLocalizations.of(context)?.translate('wail') ?? "Wail",
                  _controller.activateWail,
                  Colors.purple,
                ),
                _controlButton(
                  AppLocalizations.of(context)?.translate('intercom') ??
                      "Intercom",
                  _controller.activateInter,
                  Colors.green,
                ),
                _controlButton(
                  AppLocalizations.of(context)?.translate('ptt') ?? "PTT",
                  _controller.activatePTT,
                  Colors.teal,
                ),
                _controlButton(
                  AppLocalizations.of(context)?.translate('system_status') ??
                      "Estado del Sistema",
                  _controller.requestSystemStatus,
                  Colors.blueGrey,
                ),

                const SizedBox(height: 30),

                // 🔌 Botón de desconectar
                ElevatedButton(
                  onPressed: () {
                    _controller.disconnectDevice();
                    Navigator.pop(context); // Regresar a la pantalla principal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.translate('disconnect') ??
                        "Desconectar",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// **Botón reutilizable**
  Widget _controlButton(String label, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(250, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
