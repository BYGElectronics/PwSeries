// lib/src/pages/pin_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../Controller/ConfiguracionBluetoothController.dart';
import '../../widgets/header_widget.dart';
import '../../widgets/TecladoPinWidget.dart';
import 'control_screen.dart';

class PinEntryScreen extends StatefulWidget {
  final DeviceData device;
  const PinEntryScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  int _attempts = 0;
  final int _maxAttempts = 5;
  String _previewPin = '';
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ConfiguracionBluetoothController>();
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Header fijo arriba
          const Positioned(
            top: 0, left: 0, right: 0,
            child: HeaderWidget(),
          ),

          // Contenido bajo el header
          Positioned.fill(
            top: h * 0.12,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              child: Column(
                children: [
                  SizedBox(height: h * 0.12),
                  Text(
                    'PIN para ${widget.device.name}',
                    style: TextStyle(
                      fontFamily: 'Roboto-bold',
                      fontSize: w * 0.054,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: h * 0.02),

                  // Vista previa + toggle visibilidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _obscure ? '•' * _previewPin.length : _previewPin,
                        style: TextStyle(
                          fontSize: w * 0.08,
                          letterSpacing: w * 0.02,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                          size: w * 0.06,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                  SizedBox(height: h * 0.02),

                  // Teclado PIN personalizado
                  Expanded(
                    child: TecladoPinWidget(
                      onPinChange: (pin) => setState(() => _previewPin = pin),
                      onPinComplete: (pin) async {
                        // 1) Validar longitud y máscara
                        if (pin != ctrl.pinMask) {
                          _attempts++;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _attempts >= _maxAttempts
                                    ? 'Demasiados intentos. Regresa más tarde.'
                                    : 'PIN incorrecto',
                              ),
                            ),
                          );
                          if (_attempts >= _maxAttempts) {
                            Navigator.pop(context);
                          }
                          return;
                        }

                        // 2) PIN correcto: configurar controller
                        ctrl.selectedDevice = widget.device;
                        ctrl.pinIngresado = pin;

                        // 3) Intentar emparejar y conectar (muestra errores en SnackBar)
                        await ctrl.enviarPinYConectar(context);

                        // 4) Comprobar emparejamiento real
                        final bonded =
                        await FlutterBluetoothSerial.instance.getBondedDevices();
                        final paired = bonded.any(
                                (d) => d.address == widget.device.address);

                        if (paired) {
                          // 5a) Si está emparejado, navegar al ControlScreen
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ControlScreen(),
                            ),
                          );
                        } else {
                          // 5b) Si no se empareja, mostrar mensaje y quedarnos aquí
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                              Text('No se pudo emparejar el dispositivo.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
