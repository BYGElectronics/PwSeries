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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
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
                    style: const TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(thickness: 2, color: Colors.black),
                const SizedBox(height: 15),

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/espanol.png',
                    width: 50,
                    height: 50,
                  ),
                  title: const Text(
                    'Español',
                    style: TextStyle(fontSize: 21, fontFamily: 'Roboto-bold', fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'configAvanzada');
                  },
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/frances.png',
                    width: 50,
                    height: 50,
                  ),
                  title: const Text(
                    'Frances',
                    style: TextStyle(fontSize: 21, fontFamily: 'Roboto-bold', fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'configAvanzada');
                  },
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/ingles.png',
                    width: 50,
                    height: 50,
                  ),
                  title: const Text(
                    'Inglés',
                    style: TextStyle(fontSize: 21, fontFamily: 'Roboto-bold', fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'configAvanzada');
                  },
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Image.asset(
                    'assets/img/iconos/portugues.png',
                    width: 50,
                    height: 50,
                  ),
                  title: const Text(
                    'Portugues',
                    style: TextStyle(fontSize: 21, fontFamily: 'Roboto-bold', fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, 'configAvanzada');
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
