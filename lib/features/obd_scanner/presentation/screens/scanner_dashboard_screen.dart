import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/ai_bot_service.dart';
import '../providers/scanner_provider.dart';
import 'widgets/bluetooth_device_list.dart';

class ScannerDashboardScreen extends StatefulWidget {
  const ScannerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ScannerDashboardScreen> createState() => _ScannerDashboardScreenState();
}

class _ScannerDashboardScreenState extends State<ScannerDashboardScreen> {
  
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Pedir permisos obligatorios para BLE en Android 12+
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScannerProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Diagnóstico Inteligente (OBD2)'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Consumer<ScannerProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Estado de Conexión
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _getStatusColor(provider.state),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getStatusIcon(provider.state),
                          color: _getStatusColor(provider.state),
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getStatusText(provider.state),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón Principal de Escaneo
                  if (provider.state == ScannerState.disconnected || provider.state == ScannerState.error)
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.startScanning();
                        _showDeviceListBottomSheet(context, provider);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
                      label: const Text('Buscar Escáner', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),

                  if (provider.state == ScannerState.connected)
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.disconnect();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
                      label: const Text('Desconectar', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),

                  const SizedBox(height: 20),
                  
                  // UI de Datos en Vivo
                  if (provider.state == ScannerState.connected)
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Datos en Vivo", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMetricCard("RPM", provider.liveMetrics['RPM']?['value']?.toString() ?? "---", "rpm"),
                              _buildMetricCard("Velocidad", provider.liveMetrics['Speed']?['value']?.toString() ?? "---", "km/h"),
                              _buildMetricCard("Temp", provider.liveMetrics['CoolantTemp']?['value']?.toString() ?? "---", "°C"),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text("Códigos de Error (DTC)", style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          provider.currentDtcs.isEmpty
                            ? const Text("No hay códigos de falla detectados.", style: TextStyle(color: Colors.greenAccent))
                            : Wrap(
                                spacing: 10,
                                children: provider.currentDtcs.map((dtc) => Chip(
                                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                                  label: Text(dtc, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                )).toList(),
                              ),
                          
                          const Spacer(),
                          
                          // Botón de Diagnóstico con IA
                          ElevatedButton.icon(
                            onPressed: provider.currentDtcs.isEmpty ? null : () {
                               // Aquí llamaremos al Gemini AI Service
                               _diagnoseWithAI(context, provider.currentDtcs);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                              backgroundColor: Colors.purpleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.auto_awesome, color: Colors.white),
                            label: const Text('Explicar con IA', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                    
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 5),
              Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  void _diagnoseWithAI(BuildContext context, List<String> dtcs) async {
    // 1. Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purpleAccent),
            SizedBox(width: 10),
            Text('Analizando...', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.purpleAccent),
            SizedBox(height: 20),
            Text(
              "Consultando a la IA mecánica de My Auto Guide...",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
    );

    // 2. Construir el prompt para la IA
    final prompt = "Actúa como un mecánico experto automotriz de My Auto Guide. El escáner OBD2 acaba de detectar los siguientes códigos de error: ${dtcs.join(', ')}. "
                   "Por favor, explícale al conductor en español muy sencillo y directo: 1) Qué significa cada código. 2) Qué tan grave es (¿es seguro seguir manejando?). 3) Posibles soluciones o repuestos necesarios.";

    // 3. Llamar al servicio
    final response = await AIBotService().sendMessage(prompt);

    // 4. Cerrar diálogo de carga y mostrar resultado
    if (context.mounted) {
      Navigator.pop(context); // Cierra el loader

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.build, color: Colors.purpleAccent),
              SizedBox(width: 10),
              Text('Diagnóstico IA', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              response,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            )
          ],
        )
      );
    }
  }

  void _showDeviceListBottomSheet(BuildContext context, ScannerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BluetoothDeviceListWidget(provider: provider);
      },
    );
  }

  Color _getStatusColor(ScannerState state) {
    switch (state) {
      case ScannerState.disconnected: return Colors.grey;
      case ScannerState.scanning: return Colors.blue;
      case ScannerState.connecting: return Colors.orange;
      case ScannerState.connected: return Colors.green;
      case ScannerState.error: return Colors.red;
    }
  }

  IconData _getStatusIcon(ScannerState state) {
    switch (state) {
      case ScannerState.disconnected: return Icons.bluetooth_disabled;
      case ScannerState.scanning: return Icons.bluetooth_searching;
      case ScannerState.connecting: return Icons.bluetooth_connected;
      case ScannerState.connected: return Icons.directions_car;
      case ScannerState.error: return Icons.error_outline;
    }
  }

  String _getStatusText(ScannerState state) {
    switch (state) {
      case ScannerState.disconnected: return "Escáner Desconectado";
      case ScannerState.scanning: return "Buscando Escáner (Ej: ScanMate)...";
      case ScannerState.connecting: return "Conectando al Escáner...";
      case ScannerState.connected: return "Conectado al Vehículo";
      case ScannerState.error: return "Error de Conexión";
    }
  }
}
