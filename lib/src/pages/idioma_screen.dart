import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/TecladoPinWidget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../../widgets/header_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';

class IdiomaScreen extends StatelessWidget {
  const IdiomaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _IdiomaScreen(),
    );
  }
}

class _IdiomaScreen extends StatelessWidget {
  const _IdiomaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConfiguracionBluetoothController>(context);
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: HeaderMenuWidget()),
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
                    'Idioma',
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Divider(thickness: 2, color: theme.dividerColor),
                const SizedBox(height: 15),

                _idiomaTile(
                  context,
                  image: 'assets/img/iconos/espanol.png',
                  label: 'Español',
                ),
                const SizedBox(height: 20),

                _idiomaTile(
                  context,
                  image: 'assets/img/iconos/frances.png',
                  label: 'Francés',
                ),
                const SizedBox(height: 20),

                _idiomaTile(
                  context,
                  image: 'assets/img/iconos/ingles.png',
                  label: 'Inglés',
                ),
                const SizedBox(height: 20),

                _idiomaTile(
                  context,
                  image: 'assets/img/iconos/portugues.png',
                  label: 'Portugués',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idiomaTile(BuildContext context, {required String image, required String label}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Image.asset(
        image,
        width: 50,
        height: 50,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 21,
          fontFamily: 'Roboto-bold',
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.pushNamed(context, 'configAvanzada');
      },
    );
  }
}
