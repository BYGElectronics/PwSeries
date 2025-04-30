// lib/src/pages/splashScreenConfirmation.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pw/src/Controller/control_controller.dart';

class SplashConexionScreen extends StatefulWidget {
  final BluetoothDevice device;
  final ControlController controller;

  const SplashConexionScreen({
    Key? key,
    required this.device,
    required this.controller,
  }) : super(key: key);

  @override
  _SplashConexionScreenState createState() => _SplashConexionScreenState();
}

class _SplashConexionScreenState extends State<SplashConexionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/control',
        arguments: {
          'device':     widget.device,
          'controller': widget.controller,
        },
      );
    });

  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/img/tecladoPin/botonCheck.png",
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.error, color: Colors.red, size: 100),
              ),
              const SizedBox(height: 20),
              const Text(
                'Conexión Exitosa',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PWSeriesFont',
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
