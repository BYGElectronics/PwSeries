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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Header con botón hamburguesa
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),

          // Contenido principal
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
                    AppLocalizations.of(context)?.translate('text_size') ?? 'Tamaño de Texto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PWSeriesFont',
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  Divider(thickness: 2, color: theme.dividerColor),

                  const SizedBox(height: 30),

                  // Instrucción centrada
                  Text(
                    AppLocalizations.of(context)?.translate('adjust_text_size') ?? 'Ajusta el tamaño del texto:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18 * textSizeController.textScaleFactor,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Text(
                        'a -',
                        style: TextStyle(
                          fontSize: 17 * textSizeController.textScaleFactor,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            activeTrackColor: theme.colorScheme.primary,
                            inactiveTrackColor: theme.dividerColor,
                            thumbColor: theme.colorScheme.primary,
                            overlayColor: theme.colorScheme.primary.withAlpha(50),
                          ),
                          child: Slider(
                            value: textSizeController.textScaleFactor,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label: '${(textSizeController.textScaleFactor * 100).toInt()}%',
                            onChanged: (newSize) =>
                                textSizeController.cambiarTamanioTexto(newSize),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'A +',
                        style: TextStyle(
                          fontSize: 32 * textSizeController.textScaleFactor,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Vista previa
                  Text(
                    AppLocalizations.of(context)?.translate('preview_text') ?? 'Texto de ejemplo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18 * textSizeController.textScaleFactor,
                      color: theme.textTheme.bodyMedium?.color,
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
