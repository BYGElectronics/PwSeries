import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pw/src/Controller/home_controller.dart';
import 'package:pw/src/pages/control_screen.dart';

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
              icon: const Icon(Icons.settings, size: 30, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, "config");
              },
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: GestureDetector(
              onTap: widget.toggleTheme,
              child: Icon(
                widget.themeMode == ThemeMode.dark
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
                size: 30,
                color: Colors.white,
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
                        ? "Conectado a: $deviceName"
                        : "Modo detección",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Activando Bluetooth...")),
                  );
                  await _controller.enableBluetooth();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/boton_bt.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(width: 300, height: 55),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Buscando dispositivos Bluetooth...")),
                  );
                  await _controller.searchDevices();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/boton_buscar.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(width: 300, height: 55),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ValueListenableBuilder<List<ScanResult>>(
                  valueListenable: _controller.filteredDevices,
                  builder: (context, devices, child) {
                    if (devices.isEmpty) {
                      return const Center(
                        child: Text("No se encontraron dispositivos Pw"),
                      );
                    }
                    return ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index].device;
                        return Column(
                          children: [
                            _buildDeviceCard(device),
                          ],
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

  Widget _buildDeviceCard(BluetoothDevice device) {
    bool isConnected = _controller.connectedDeviceName.value == device.platformName;
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.white54),
      ),
      elevation: 5,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bluetooth, color: Colors.white, size: 30),
            title: Text(
              device.platformName.isNotEmpty ? device.platformName : "Dispositivo Desconocido",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              device.remoteId.toString(),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
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
              child: const Text("Conectar", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          if (isConnected) ...[
            ElevatedButton(
              onPressed: () => _controller.disconnectDevice(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Desconectar", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ControlScreen(connectedDevice: device),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Acceder al Control", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }
}
