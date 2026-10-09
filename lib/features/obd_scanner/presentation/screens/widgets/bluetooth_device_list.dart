import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scanner_provider.dart';

class BluetoothDeviceListWidget extends StatelessWidget {
  final ScannerProvider provider;

  const BluetoothDeviceListWidget({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<ScannerProvider>(
        builder: (context, scanProvider, _) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dispositivos Encontrados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (scanProvider.state == ScannerState.scanning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                      )
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Selecciona tu escáner (Ej: ScanMate, OBDII, THINKCAR)',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const Divider(color: Colors.grey),
                Expanded(
                  child: scanProvider.devices.isEmpty
                      ? const Center(
                          child: Text(
                            "No se encontraron dispositivos cercanos.\nAsegúrate de que el escáner esté conectado al carro y encendido.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: scanProvider.devices.length,
                          itemBuilder: (context, index) {
                            final deviceResult = scanProvider.devices[index];
                            final device = deviceResult.device;
                            
                            return ListTile(
                              leading: const Icon(Icons.bluetooth, color: Colors.white),
                              title: Text(
                                device.platformName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                device.remoteId.toString(),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                ),
                                onPressed: () {
                                  Navigator.pop(context); // Cerrar bottom sheet
                                  scanProvider.connectToDevice(device);
                                },
                                child: const Text('Conectar', style: TextStyle(color: Colors.white)),
                              ),
                            );
                          },
                        ),
                ),
                if (scanProvider.state == ScannerState.scanning)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        scanProvider.stopScanning();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar Búsqueda', style: TextStyle(color: Colors.red)),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}
