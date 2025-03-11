import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pw/src/Controller/home_controller.dart';
import 'package:pw/src/Controller/config_controller.dart';
import 'package:pw/src/localization/app_localization.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  @override
  Widget build(BuildContext context) {
    final configController = Provider.of<ConfigController>(context);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white; // ✅ Se adapta al modo oscuro SOLO para textos

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 150,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/header.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.settings, size: 30, color: Colors.white), // ❌ No cambia con dark mode
              onPressed: () {
                Navigator.pushNamed(context, "config");
              },
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: GestureDetector(
              onTap: () {
                configController.toggleDarkMode(); // ✅ Usa el ConfigController para sincronizar el modo oscuro
              },
              child: Icon(
                configController.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                size: 30,
                color: Colors.white, // ❌ No cambia con dark mode
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 250),
              ValueListenableBuilder<String?>(
                valueListenable: _controller.connectedDeviceName,
                builder: (context, deviceName, child) {
                  return Text(
                    deviceName != null
                        ? "${AppLocalizations.of(context)?.translate('connected_to') ?? 'Conectado a'}: $deviceName"
                        : AppLocalizations.of(context)?.translate('detection_mode') ?? "Modo detección",
                    style: TextStyle(color: textColor), // ✅ Se adapta al modo oscuro SOLO para textos
                  );
                },
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isConnected,
                builder: (context, isConnected, child) {
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: isConnected ? null : () => _controller.enableBluetooth(),
                        child: Opacity(
                          opacity: isConnected ? 0.5 : 1,
                          child: Image.asset(
                            "assets/images/boton_bt.png",
                            width: 300,
                            height: 55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: isConnected ? null : () => _controller.searchDevices(),
                        child: Opacity(
                          opacity: isConnected ? 0.5 : 1,
                          child: Image.asset(
                            "assets/images/boton_buscar.png",
                            width: 300,
                            height: 55,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ValueListenableBuilder<List<ScanResult>>(
                  valueListenable: _controller.filteredDevices,
                  builder: (context, devices, child) {
                    if (devices.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context)?.translate('no_devices_found') ??
                              "No se encontraron dispositivos Pw",
                          style: TextStyle(color: textColor), // ✅ Se adapta al modo oscuro SOLO para textos
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index].device;
                        final bool isConnected =
                            _controller.connectedDeviceName.value == device.platformName;
                        return Card(
                          color: Colors.white10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: textColor.withOpacity(0.5)), // ✅ Se adapta al modo oscuro SOLO para textos
                          ),
                          elevation: 5,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.bluetooth,
                                  color: Colors.white, // ❌ No cambia con dark mode
                                  size: 30,
                                ),
                                title: Text(
                                  device.platformName.isNotEmpty
                                      ? device.platformName
                                      : AppLocalizations.of(context)?.translate('unknown_device') ??
                                      "Dispositivo Desconocido",
                                  style: TextStyle(fontSize: 18, color: textColor), // ✅ Se adapta al modo oscuro SOLO para textos
                                ),
                                subtitle: Text(
                                  device.remoteId.toString(),
                                  style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)), // ✅ Se adapta al modo oscuro SOLO para textos
                                ),
                              ),
                              if (!isConnected)
                                ElevatedButton(
                                  onPressed: () => _controller.connectToDevice(device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)?.translate('connect') ?? "Conectar",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ValueListenableBuilder<bool>(
                                valueListenable: _controller.isConnected,
                                builder: (context, isConnected, child) {
                                  if (isConnected) {
                                    return Column(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _controller.disconnectDevice(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)?.translate('disconnect') ?? "Desconectar",
                                            style: const TextStyle(color: Colors.white, fontSize: 16),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _controller.navigateToControl(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)?.translate('access_control') ??
                                                "Acceder al Control",
                                            style: const TextStyle(color: Colors.white, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox(); // No mostrar nada si no está conectado
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
