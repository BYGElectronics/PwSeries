import 'package:flutter/material.dart';

class TecladoPinWidget extends StatefulWidget {
  final Function(String) onPinComplete;

  const TecladoPinWidget({Key? key, required this.onPinComplete})
    : super(key: key);

  @override
  State<TecladoPinWidget> createState() => _TecladoPinWidgetState();
}

class _TecladoPinWidgetState extends State<TecladoPinWidget> {
  String pin = "";

  void agregarDigito(String digito) {
    if (pin.length < 6) {
      setState(() {
        pin += digito;
      });
    }
  }

  void borrarDigito() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  void confirmarPin() {
    if (pin.isNotEmpty) {
      widget.onPinComplete(pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 0.01),

        Text(
          '•' * pin.length,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 0.01),
        const Divider(thickness: 1, color: Colors.black),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(40),
            mainAxisSpacing: 10,
            crossAxisSpacing: 20,
            children: [
              for (var i = 1; i <= 9; i++) _buildTecla('$i'),
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
    if (valor == 'X') {
      rutaImagen = 'assets/img/tecladoPin/botonCancel.png';
    } else if (valor == 'V') {
      rutaImagen = 'assets/img/tecladoPin/botonCheck.png';
    } else {
      rutaImagen = 'assets/img/tecladoPin/boton-$valor.png';
    }

    return GestureDetector(
      onTap: () {
        if (esBorrar) {
          borrarDigito();
        } else if (esConfirmar) {
          confirmarPin();
        } else {
          agregarDigito(valor);
        }
      },
      child: Image.asset(rutaImagen, fit: BoxFit.contain),
    );
  }
}
