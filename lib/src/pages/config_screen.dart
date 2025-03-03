import 'package:flutter/material.dart';
import 'package:pw/src/Controller/config_controller.dart';

class ConfigScreen extends StatelessWidget {
  final ConfigController controller;

  const ConfigScreen({super.key, required this.controller});

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 160),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Ajustes",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              // Opciones de configuración
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text("Idioma"),
                      onTap: controller.changeLanguage,
                    ),
                    ListTile(
                      leading: const Icon(Icons.text_fields),
                      title: const Text("Tamaño de texto"),
                      onTap: controller.changeTextSize,
                    ),
                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text("Modo claro/oscuro"),
                      onTap: controller.toggleDarkMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
