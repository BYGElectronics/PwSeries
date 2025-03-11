import 'package:flutter/material.dart';
import 'package:pw/src/Controller/idioma_controller.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/localization/app_localization.dart';

class IdiomaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final idiomaController = Provider.of<IdiomaController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('language') ?? 'Idioma',
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              AppLocalizations.of(context)?.translate('spanish') ??
                  "Español (Latinoamérica)",
            ),
            onTap: () {
              idiomaController.cambiarIdioma('es');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              AppLocalizations.of(context)?.translate('english') ??
                  "English (United States)",
            ),
            onTap: () {
              idiomaController.cambiarIdioma('en');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              AppLocalizations.of(context)?.translate('portuguese') ??
                  "Português (Brasil)",
            ),
            onTap: () {
              idiomaController.cambiarIdioma('pt');
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              AppLocalizations.of(context)?.translate('french') ??
                  "Français (France)",
            ),
            onTap: () {
              idiomaController.cambiarIdioma('fr');
              Navigator.pop(context);
            },
          ),

        ],
      ),
    );
  }
}
