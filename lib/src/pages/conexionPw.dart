import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/drawerMenuWidget.dart';
import '../../widgets/header_menu_widget.dart';
import '../Controller/ConfiguracionBluetoothController.dart';

class ConexionpwScreen extends StatelessWidget {
  const ConexionpwScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionBluetoothController(),
      child: const _ConexionpwScreen(),
    );
  }
}

class _ConexionpwScreen extends StatelessWidget {
  const _ConexionpwScreen({Key? key}) : super(key: key);

  Widget _actionButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required double width,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'PWSeriesFont',
            fontSize: 18,
            color:
                theme.colorScheme.onPrimary, // texto blanco o negro según fondo
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderMenuWidget(),
          ),
          Positioned(
            top: screenH * 0.18,
            left: 27,
            right: 27,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Conexión PW',
                    style: TextStyle(
                      fontFamily: 'PWSeriesFont',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(thickness: 2, color: theme.dividerColor),
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BTPW',
                            style: TextStyle(
                              fontFamily: 'PWSeriesFont',
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'EC:64:C9:41:C3:BA',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _actionButton(
                          context: context,
                          text: 'Olvidar PW',
                          width: screenW * 0.4,
                          onPressed: () {
                            // lógica olvidar
                          },
                        ),
                        const SizedBox(height: 12),
                        _actionButton(
                          context: context,
                          text: 'Desconectar',
                          width: screenW * 0.4,
                          onPressed: () {
                            // lógica desconectar
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
