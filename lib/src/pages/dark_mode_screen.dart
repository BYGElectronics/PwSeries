import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/localization/app_localization.dart';

class DarkModeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigController>(
      builder: (context, configController, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)?.translate('dark_mode') ??
                  "Modo Oscuro",
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // **Texto**
                Text(
                  AppLocalizations.of(context)?.translate('enable_dark_mode') ??
                      "Activar modo oscuro",
                  style: const TextStyle(fontSize: 18),
                ),

                // **Switch para activar/desactivar el modo oscuro**
                Switch(
                  value: configController.isDarkMode,
                  onChanged: (bool value) {
                    configController.toggleDarkMode();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
