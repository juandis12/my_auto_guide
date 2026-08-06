// =============================================================================
// bitacora_tanqueo_screen.dart — PANTALLA BITÁCORA DE TANQUEO Y RENDIMIENTO
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/services/fuel_tracker_service.dart';
import '../domain/models/fuel_log_model.dart';
import '../../../shared/widgets/liquid_glass_fab.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../core/utils/formatters.dart';

class BitacoraTanqueoScreen extends StatefulWidget {
  final String vehiculoId;
  final String marcaModelo;
  final double currentKms;

  const BitacoraTanqueoScreen({
    super.key,
    required this.vehiculoId,
    required this.marcaModelo,
    required this.currentKms,
  });

  @override
  State<BitacoraTanqueoScreen> createState() => _BitacoraTanqueoScreenState();
}

class _BitacoraTanqueoScreenState extends State<BitacoraTanqueoScreen> {
  final _service = FuelTrackerService();
  List<FuelLogModel> _logs = [];
  bool _isLoading = true;

  Map<String, double> _metrics = {
    'kmPerGallon': 0.0,
    'costPerKm': 0.0,
    'totalSpent': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _service.getLogs(widget.vehiculoId);
    final metrics = _service.calculateMetrics(list);

    if (mounted) {
      setState(() {
        _logs = list;
        _metrics = metrics;
        _isLoading = false;
      });
    }
  }

  void _abrirDialogoAgregar() {
    final kmsCtrl = TextEditingController(text: widget.currentKms > 0 ? widget.currentKms.round().toString() : '');
    final montoCtrl = TextEditingController();
    final galonesCtrl = TextEditingController();
    final precioCtrl = TextEditingController(text: '15500'); // Precio promedio por galón

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '⛽ Registrar Tanqueo',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildInput('Kilometraje Actual (Km)', kmsCtrl, TextInputType.number, Icons.speed),
              const SizedBox(height: 12),
              _buildInput('Monto Total Pagado (COP)', montoCtrl, TextInputType.number, Icons.attach_money),
              const SizedBox(height: 12),
              _buildInput('Galones Cargados', galonesCtrl, const TextInputType.numberWithOptions(decimal: true), Icons.local_gas_station),
              const SizedBox(height: 20),
              Center(
                child: LiquidGlassButton(
                  label: 'Guardar Tanqueo',
                  onTap: () async {
                    final kms = double.tryParse(kmsCtrl.text) ?? 0.0;
                    final monto = double.tryParse(montoCtrl.text) ?? 0.0;
                    final galones = double.tryParse(galonesCtrl.text) ?? 0.0;
                    final precio = double.tryParse(precioCtrl.text) ?? 15500.0;

                    if (kms <= 0 || monto <= 0 || galones <= 0) {
                      AppSnackBar.show(context,
                          'Ingresa valores válidos de kilometraje, monto y galones.');
                      return;
                    }

                    final newLog = FuelLogModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      vehiculoId: widget.vehiculoId,
                      fecha: DateTime.now(),
                      kmsActuales: kms,
                      montoCop: monto,
                      galones: galones,
                      precioPorGalon: precio,
                    );

                    Navigator.pop(ctx);
                    await _service.addLog(newLog);
                    _loadData();
                  },
                  width: 200,
                  height: 46,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, TextInputType type, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Bitácora de Tanqueo - ${widget.marcaModelo}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogoAgregar,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nuevo Tanqueo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TARJETAS DE MÉTRICAS PRINCIPALES
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Rendimiento',
                          value: '${_metrics['kmPerGallon']!.toStringAsFixed(1)} Km/Gal',
                          subtitle: 'Eficiencia promedio',
                          icon: Icons.speed_rounded,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Costo por Km',
                          value: AppFormat.currency(_metrics['costPerKm']!),
                          subtitle: 'COP por cada Km',
                          icon: Icons.monetization_on_rounded,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    title: 'Gasto Total en Gasolina',
                    value: AppFormat.currency(_metrics['totalSpent']!),
                    subtitle: 'Acumulado registrado',
                    icon: Icons.local_gas_station_rounded,
                    color: Colors.blueAccent,
                    isWide: true,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Historial de Cargas',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_logs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '⛽ No hay tanqueos registrados aún.\nToca el botón "+" para agregar tu primera carga de combustible.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _logs.length,
                      itemBuilder: (ctx, idx) {
                        final item = _logs[idx];
                        final fechaStr = AppFormat.date(item.fecha);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.local_gas_station_rounded, color: Colors.blueAccent, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.kmsActuales.round()} Km',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        '$fechaStr • ${item.galones.toStringAsFixed(1)} Gal',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                AppFormat.currency(item.montoCop),
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isWide ? 18 : 16)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
