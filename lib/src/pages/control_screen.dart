import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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

          // 📡 Mostrar el nombre del dispositivo conectado
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Conectado a: ${widget.connectedDevice.platformName}",
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

                // 🔊 Botón Sirena
                _controlButton("Sirena", _controller.activateSiren, Colors.red),

                // 🔦 Botón Auxiliar
                _controlButton(
                    "Auxiliar", _controller.activateAux, Colors.orange),

                // 📢 Botón Horn
                _controlButton("Horn", _controller.activateHorn, Colors.blue),

                // 🔊 Botón Wail
                _controlButton("Wail", _controller.activateWail, Colors.purple),

                // 🎤 Botón Intercom
                _controlButton(
                    "Intercom", _controller.activateInter, Colors.green),

                // 🎙 Botón PTT
                _controlButton("PTT", _controller.activatePTT, Colors.teal),

                const SizedBox(height: 20),

                // 🔄 Solicitar estado del sistema
                _controlButton("Estado del Sistema",
                    _controller.requestSystemStatus, Colors.blueGrey),

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
                  child: const Text("Desconectar",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
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
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}
