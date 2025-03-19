import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/text_size_controller.dart';
import 'package:pw/src/localization/app_localization.dart';

class TextSizeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textSizeController = Provider.of<TextSizeController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('text_size') ??
              "Tamaño de Texto",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **Instrucción**
            Text(
              AppLocalizations.of(context)?.translate('adjust_text_size') ??
                  "Ajusta el tamaño del texto:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // **Slider para ajustar tamaño del texto**
            Slider(
              value: textSizeController.textScaleFactor,
              min: 0.8, // Tamaño mínimo
              max: 1.5, // Tamaño máximo
              divisions: 7, // Incrementos definidos
              label: "${(textSizeController.textScaleFactor * 100).toInt()}%",
              onChanged: (newSize) {
                textSizeController.cambiarTamanioTexto(newSize);
              },
            ),

            // **Vista previa del cambio**
            Center(
              child: Text(
                AppLocalizations.of(context)?.translate('preview_text') ??
                    "Texto de ejemplo",
                style: TextStyle(
                  fontSize: 18 * textSizeController.textScaleFactor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
