import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/TecladoPinWidget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../../widgets/header_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';
import '../localization/app_localization.dart';
import 'package:pw/src/Controller/theme_controller.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _ThemeScreen(),
    );
  }
}

class _ThemeScreen extends StatelessWidget {
  const _ThemeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConfiguracionBluetoothController>(context);
    final themeController = Provider.of<ThemeController>(context);
    final localizer = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),
          Positioned(
            top: screenHeight * 0.18,
            left: 27,
            right: 27,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    localizer.translate('theme_title'),
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Divider(thickness: 2, color: Theme.of(context).dividerColor),
                const SizedBox(height: 15),

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/darkMode.png',
                    width: 50,
                    height: 50,
                  ),
                  title: Text(
                    localizer.translate('theme_dark'),
                    style: const TextStyle(
                      fontSize: 21,
                      fontFamily: 'Roboto-bold',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    themeController.setThemeMode(ThemeMode.dark);
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/configAvanzada');
                  },
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/lightMode.png',
                    width: 50,
                    height: 50,
                  ),
                  title: Text(
                    localizer.translate('theme_light'),
                    style: const TextStyle(
                      fontSize: 21,
                      fontFamily: 'Roboto-bold',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    themeController.setThemeMode(ThemeMode.light);
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/configAvanzada');
                  },
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/System.png',
                    width: 50,
                    height: 50,
                  ),
                  title: Text(
                    localizer.translate('theme_system'),
                    style: const TextStyle(
                      fontSize: 21,
                      fontFamily: 'Roboto-bold',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    themeController.setThemeMode(ThemeMode.system);
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/control');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
