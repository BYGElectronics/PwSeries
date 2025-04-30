// lib/src/pages/text_size_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/text_size_controller.dart';
import 'package:pw/src/localization/app_localization.dart';
import 'package:pw/widgets/header_menu_widget.dart';

import '../../widgets/drawerMenuWidget.dart';

class TextSizeScreen extends StatelessWidget {
  const TextSizeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textSizeController = Provider.of<TextSizeController>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // 1) Header con botón hamburguesa
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),

          // 2) Contenido principal desplazado hacia abajo
          Positioned(
            top: screenHeight * 0.18,
            left: 16,
            right: 16,
            bottom: 0,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Título centrado
                  Text(
                    AppLocalizations.of(context)?.translate('text_size') ??
                        'Tamaño de Texto',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PWSeriesFont',
                    ),
                  ),
                  const Divider(thickness: 2, color: Colors.black),
                  const SizedBox(height: 30),
                  // Barra de ajuste con 'a', slider y 'A'

                  // Instrucción centrada
                  Text(
                    AppLocalizations.of(
                          context,
                        )?.translate('adjust_text_size') ??
                        'Ajusta el tamaño del texto:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18 * textSizeController.textScaleFactor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Text(
                        'a -',
                        style: TextStyle(
                          fontSize: 17 * textSizeController.textScaleFactor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            activeTrackColor: Colors.black,
                            inactiveTrackColor: Colors.black,
                            thumbColor: Colors.black,
                            overlayColor: Colors.black.withAlpha(38),
                          ),
                          child: Slider(
                            value: textSizeController.textScaleFactor,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label:
                                '${(textSizeController.textScaleFactor * 100).toInt()}%',
                            onChanged:
                                (newSize) => textSizeController
                                    .cambiarTamanioTexto(newSize),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'A +',
                        style: TextStyle(
                          fontSize: 32 * textSizeController.textScaleFactor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Vista previa centrada
                  Text(
                    AppLocalizations.of(context)?.translate('preview_text') ??
                        'Texto de ejemplo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18 * textSizeController.textScaleFactor,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
