import 'package:flutter/material.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/localization/app_localization.dart';

import 'text_size_screen.dart';
import 'idioma_screen.dart';
import 'dark_mode_screen.dart';


class ConfigScreen extends StatelessWidget {
  final ConfigController controller;

  const ConfigScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opcionesConfiguracion = [
      {
        'icon': Icons.language,
        'label': 'language',
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => IdiomaScreen()),
            ),
      },
      {
        'icon': Icons.text_fields,
        'label': 'text_size',
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TextSizeScreen()),
            ),
      },
      {
        'icon': Icons.dark_mode,
        'label': 'dark_mode',
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DarkModeScreen()),
            ),
      },


    ];



    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/header.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 160),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)?.translate('settings') ??
                      "Ajustes",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),



              Expanded(
                child: ListView.builder(
                  itemCount: opcionesConfiguracion.length,
                  itemBuilder: (context, index) {
                    final item = opcionesConfiguracion[index];
                    return ListTile(
                      leading: Icon(item['icon']),
                      title: Text(
                        AppLocalizations.of(
                              context,
                            )?.translate(item['label']) ??
                            item['label'],
                      ),
                      onTap: item['action'],
                    );
                  },
                ),
              ),

            ],
          ),
        ],

      ),

    );



  }

}
