import 'dart:async';
import 'package:flutter/material.dart';

class SplashConexionDenegateScreen extends StatefulWidget {
  const SplashConexionDenegateScreen({Key? key}) : super(key: key);

  @override
  _SplashConexionDenegateScreenState createState() => _SplashConexionDenegateScreenState();
}

class _SplashConexionDenegateScreenState extends State<SplashConexionDenegateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/control');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo negro (puedes cambiarlo)
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🖼️ Imagen en lugar de ícono
              Image.asset(
                "assets/img/tecladoPin/botonCancel.png", // <- Aquí cambia el path de tu imagen
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red, size: 100);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Conexión Fallida',
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
