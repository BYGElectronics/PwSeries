import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/TecladoPinWidget.dart';
import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../../widgets/header_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';

class ConfigAvanzadaScreen extends StatelessWidget {
  const ConfigAvanzadaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _ConfigAvanzadaScreen(),
    );
  }
}

class _ConfigAvanzadaScreen extends StatelessWidget {
  const _ConfigAvanzadaScreen({Key? key}) : super(key: key);

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
                    'Configuración Avanzada',
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

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/iconoConfigTeclado.png',
                    width: 50,
                    height: 50,
                  ),
                  title: Text(
                    'Configuración Teclado',
                    style: TextStyle(
                      fontSize: 21,
                      fontFamily: 'PWSeriesFont',
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'configTeclado');
                  },
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/iconoBtConexion.png',
                    width: 50,
                    height: 50,
                  ),
                  title: Text(
                    'Conexión Pw',
                    style: TextStyle(
                      fontSize: 21,
                      fontFamily: 'PWSeriesFont',
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'conexionPw');
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
