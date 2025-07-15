import 'package:flutter/material.dart';

class TecladoPinWidget extends StatefulWidget {
  final ValueChanged<String>? onPinChange;
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
    return LayoutBuilder(builder: (context, constraints) {
      final double availableHeight = constraints.maxHeight;
      final double buttonSize = availableHeight / 6; // Ajuste responsivo vertical

      final List<String> teclas = [
        '1', '2', '3',
        '4', '5', '6',
        '7', '8', '9',
        'X', '0', 'V',
      ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            '•' * _pin.length,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1, color: Colors.black),
          const SizedBox(height: 10),
          SizedBox(
            height: buttonSize * 5 + 20,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 49),
              itemCount: teclas.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 22,
                mainAxisSpacing: 15,
              ),
              itemBuilder: (context, index) {
                final valor = teclas[index];
                return _buildTecla(
                  valor,
                  size: buttonSize,
                  esBorrar: valor == 'X',
                  esConfirmar: valor == 'V',
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTecla(
      String valor, {
        required double size,
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
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Image.asset(rutaImagen, fit: BoxFit.contain),
      ),
    );
  }
}
