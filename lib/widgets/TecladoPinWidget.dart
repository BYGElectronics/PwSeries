import 'package:flutter/material.dart';

/// Widget de teclado PIN con imágenes para cada tecla.
/// Notifica cambios parciales con [onPinChange] y la finalización con [onPinComplete].
class TecladoPinWidget extends StatefulWidget {
  /// Llamado cada vez que cambia el PIN (se añade o borra un dígito).
  final ValueChanged<String>? onPinChange;

  /// Llamado cuando se pulsa la tecla “✓” con el PIN completo.
  final ValueChanged<String> onPinComplete;

  const TecladoPinWidget({
    Key? key,
    required this.onPinComplete,
    this.onPinChange,
  }) : super(key: key);

  @override
  State<TecladoPinWidget> createState() => _TecladoPinWidgetState();
}

class _TecladoPinWidgetState extends State<TecladoPinWidget> {
  String _pin = '';

  static const _maxLength = 6;

  void _agregarDigito(String digito) {
    if (_pin.length < _maxLength) {
      setState(() => _pin += digito);
      widget.onPinChange?.call(_pin);
    }
  }

  void _borrarDigito() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
      widget.onPinChange?.call(_pin);
    }
  }

  void _confirmarPin() {
    if (_pin.isNotEmpty) {
      widget.onPinComplete(_pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Preview interno (opcional)
        Text(
          '•' * _pin.length,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),
        const Divider(thickness: 1, color: Colors.black),

        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(40),
            mainAxisSpacing: 10,
            crossAxisSpacing: 20,
            children: [
              for (var i = 1; i <= 9; i++)
                _buildTecla('$i'),
              _buildTecla('X', esBorrar: true),
              _buildTecla('0'),
              _buildTecla('V', esConfirmar: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTecla(
      String valor, {
        bool esBorrar = false,
        bool esConfirmar = false,
      }) {
    String rutaImagen;
    if (esBorrar) {
      rutaImagen = 'assets/img/tecladoPin/botonCancel.png';
    } else if (esConfirmar) {
      rutaImagen = 'assets/img/tecladoPin/botonCheck.png';
    } else {
      rutaImagen = 'assets/img/tecladoPin/boton-$valor.png';
    }

    return GestureDetector(
      onTap: () {
        if (esBorrar) {
          _borrarDigito();
        } else if (esConfirmar) {
          _confirmarPin();
        } else {
          _agregarDigito(valor);
        }
      },
      child: Image.asset(rutaImagen, fit: BoxFit.contain),
    );
  }
}
