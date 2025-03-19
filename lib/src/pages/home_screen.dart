// **Importaciones necesarias**
import 'package:flutter/material.dart'; // Importa la librería de Flutter para construir la UI
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Manejo de Bluetooth BLE
import 'package:provider/provider.dart'; // Proveedor de estado para manejar la lógica de configuración
import 'package:pw/src/Controller/home_controller.dart'; // Controlador principal de la pantalla de inicio
import 'package:pw/src/Controller/config_controller.dart'; // Controlador de configuración
import 'package:pw/src/localization/app_localization.dart';

import '../Controller/idioma_controller.dart'; // Manejo de internacionalización (traducción)

// **Clase principal que representa la pantalla de inicio**
//
// Esta pantalla permite activar y buscar dispositivos Bluetooth,
// cambiar el modo de tema (oscuro/claro) y acceder a la configuración.
class HomeScreen extends StatefulWidget {
  // **Parámetro para alternar el modo de tema (oscuro/claro)**
  final VoidCallback toggleTheme;

  // **Parámetro para conocer el estado actual del tema**
  final ThemeMode themeMode;

  // **Constructor de la clase HomeScreen**
  //
  // Requiere dos parámetros:
  // - `toggleTheme`: Función para cambiar el tema.
  // - `themeMode`: Indica el tema actual del sistema.
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

  /// **Función para obtener la imagen del botón según el idioma**
  String _getLocalizedButtonImage(String buttonName, String locale) {
    String folder = "assets/images/Botones"; // Carpeta base de las imágenes

    switch (locale) {
      case "es":
        return "$folder/Espanol/$buttonName.png"; // Español
      case "fr":
        return "$folder/Frances/${buttonName}_3.png"; // Francés
      case "en":
        return "$folder/Ingles/${buttonName}_1.png"; // Inglés
      case "pt":
        return "$folder/Portugues/${buttonName}_2.png"; // Portugués
      default:
        return "$folder/Espanol/$buttonName.png"; // Español por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    final configController = Provider.of<ConfigController>(context);
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.white; // ✅ Se adapta al modo oscuro SOLO para textos
    final idiomaController = Provider.of<IdiomaController>(context);

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
              icon: const Icon(
                Icons.settings,
                size: 30,
                color: Colors.white,
              ), // ❌ No cambia con dark mode
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
                configController
                    .toggleDarkMode(); // ✅ Usa el ConfigController para sincronizar el modo oscuro
              },
              child: Icon(
                configController.isDarkMode
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
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
                        : AppLocalizations.of(
                              context,
                            )?.translate('detection_mode') ??
                            "Modo detección",
                    style: TextStyle(
                      color: textColor,
                    ), // ✅ Se adapta al modo oscuro SOLO para textos
                  );
                },
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isConnected,
                builder: (context, isConnected, child) {
                  return Column(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.isConnected,
                        builder: (context, isConnected, child) {
                          return GestureDetector(
                            onTap:
                                isConnected
                                    ? null
                                    : () => _controller.enableBluetooth(),
                            child: Opacity(
                              opacity: isConnected ? 0.5 : 1,
                              child: Image.asset(
                                _getLocalizedButtonImage(
                                  "Activar",
                                  idiomaController.locale.languageCode,
                                ), // ✅ Usa la imagen en el idioma correcto
                                width: 300,
                                height: 65,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.isConnected,
                        builder: (context, isConnected, child) {
                          return GestureDetector(
                            onTap:
                                isConnected
                                    ? null
                                    : () => _controller.searchDevices(),
                            child: Opacity(
                              opacity: isConnected ? 0.5 : 1,
                              child: Image.asset(
                                _getLocalizedButtonImage(
                                  "Buscar",
                                  idiomaController.locale.languageCode,
                                ), // ✅ Usa la imagen en el idioma correcto
                                width: 300,
                                height: 65,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),

              // 🔹 Línea separadora
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                ), // Espaciado de los lados
                child: Divider(
                  color:
                      configController.isDarkMode
                          ? Colors.white38
                          : Colors.black38, // 🔹 Color adaptable al modo
                  thickness: 2, // Grosor de la línea
                ),
              ),
              const SizedBox(height: 5),

              Expanded(
                child: ValueListenableBuilder<List<ScanResult>>(
                  valueListenable: _controller.filteredDevices,
                  builder: (context, devices, child) {
                    if (devices.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(
                                context,
                              )?.translate('no_devices_found') ??
                              "No se encontraron dispositivos Pw",
                          style: TextStyle(color: textColor),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index].device;

                        return ValueListenableBuilder<bool>(
                          valueListenable: _controller.isConnected,
                          builder: (context, isConnected, child) {
                            final bool isThisDeviceConnected =
                                _controller.connectedDeviceName.value ==
                                    device.platformName &&
                                isConnected;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 🔹 Información del dispositivo a la izquierda
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.bluetooth,
                                        color:
                                            Colors
                                                .blueAccent, // Icono de Bluetooth
                                        size: 35,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ), // Espacio entre icono y texto
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.platformName.isNotEmpty
                                                ? device.platformName
                                                : AppLocalizations.of(
                                                      context,
                                                    )?.translate(
                                                      'unknown_device',
                                                    ) ??
                                                    "Dispositivo Desconocido",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  configController.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            device.remoteId.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  configController.isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // 🔹 Botones (se actualizan automáticamente)
                                  Column(
                                    children: [
                                      isThisDeviceConnected
                                          ? Column(
                                            children: [
                                              // **Botón Desconectar**
                                              GestureDetector(
                                                onTap: () async {
                                                  await _controller
                                                      .disconnectDevice();
                                                  setState(
                                                    () {},
                                                  ); // 🔄 Refresca la interfaz automáticamente
                                                },
                                                child: Image.asset(
                                                  _getLocalizedButtonImage(
                                                    "Desconectar",
                                                    idiomaController
                                                        .locale
                                                        .languageCode,
                                                  ),
                                                  width: 150,
                                                ),
                                              ),
                                              const SizedBox(height: 10),

                                              // **Botón Teclado PW**
                                              GestureDetector(
                                                onTap:
                                                    () => _controller
                                                        .navigateToControl(
                                                          context,
                                                        ),
                                                child: Image.asset(
                                                  _getLocalizedButtonImage(
                                                    "Teclado",
                                                    idiomaController
                                                        .locale
                                                        .languageCode,
                                                  ),
                                                  width: 160,
                                                ),
                                              ),
                                            ],
                                          )
                                          : GestureDetector(
                                            onTap: () async {
                                              await _controller.connectToDevice(
                                                device,
                                              );
                                              setState(
                                                () {},
                                              ); // 🔄 Refresca la interfaz automáticamente
                                            },
                                            child: Image.asset(
                                              _getLocalizedButtonImage(
                                                "Conectar",
                                                idiomaController
                                                    .locale
                                                    .languageCode,
                                              ),
                                              width: 150,
                                            ),
                                          ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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
