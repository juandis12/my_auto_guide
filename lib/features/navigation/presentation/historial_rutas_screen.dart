import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/logic/performance_guard.dart';

class HistorialRutasScreen extends StatefulWidget {
  final String vehiculoId;
  final void Function(Map<String, dynamic> route)? onRouteSelected;

  const HistorialRutasScreen({
    super.key,
    required this.vehiculoId,
    this.onRouteSelected,
  });

  @override
  State<HistorialRutasScreen> createState() => _HistorialRutasScreenState();
}

class _HistorialRutasScreenState extends State<HistorialRutasScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getRouteHistory(widget.vehiculoId);
      if (mounted) {
        setState(() => _history = data);
      }
    } catch (e) {
      debugPrint('Error cargando historial: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        final selectedRoute = _history[index];
                        if (widget.onRouteSelected != null) {
                          widget.onRouteSelected!(selectedRoute);
                        }
                        Navigator.of(context).pop(selectedRoute);
                      },
                      child: _RouteCard(
                        route: _history[index],
                        isDark: isDark,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined,
              size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes trayectos guardados',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final bool isDark;

  const _RouteCard({required this.route, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Columnas: origen_name, destino_name, distancia_km, duracion_segundos, consumo_galones, costo_estimado, fecha
    final origen = route['origen_name'] ?? 'Ubicación desconocida';
    final destino = route['destino_name'] ?? 'Destino desconocido';
    final hasKms = route['distancia_km'] != null;
    final hasGalones = route['consumo_galones'] != null;
    final hasCosto = route['costo_estimado'] != null;

    final kms = hasKms ? (route['distancia_km'] as num).toDouble() : 0.0;
    final galones =
        hasGalones ? (route['consumo_galones'] as num).toDouble() : 0.0;
    final costo = hasCosto ? (route['costo_estimado'] as num).toDouble() : 0.0;

    DateTime fecha;
    final fechaRaw = route['fecha'];
    if (fechaRaw is String) {
      fecha = DateTime.tryParse(fechaRaw)?.toLocal() ?? DateTime.now();
    } else if (fechaRaw is DateTime) {
      fecha = fechaRaw.toLocal();
    } else {
      fecha = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          if (!PerformanceGuard().isLowEnd)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header: Fecha
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.05),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  Text(
                    '${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.blue[200] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            // Trayecto
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _LocationRow(
                      icon: Icons.circle_outlined,
                      text: origen,
                      color: Colors.grey),
                  const Padding(
                    padding: EdgeInsets.only(left: 11),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: DashedLineConnector(),
                    ),
                  ),
                  _LocationRow(
                      icon: Icons.location_on,
                      text: destino,
                      color: Colors.redAccent),
                  const Divider(height: 24),
                  // Métrica
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Stat(
                        icon: Icons.route_outlined,
                        value: hasKms ? '${kms.toStringAsFixed(1)} km' : 'N/A',
                        label: 'Distancia',
                      ),
                      _Stat(
                        icon: Icons.local_gas_station_rounded,
                        value: hasGalones
                            ? '${galones.toStringAsFixed(2)} gal'
                            : 'N/A',
                        label: 'Consumo',
                        color: Colors.orange,
                      ),
                      _Stat(
                        icon: Icons.payments_rounded,
                        value: hasCosto
                            ? '\$${(costo / 1000).toStringAsFixed(1)}k'
                            : 'N/A',
                        label: 'Gasto',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _LocationRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color? color;
  const _Stat(
      {required this.icon,
      required this.value,
      required this.label,
      this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon,
            size: 20,
            color: color ?? (isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
      ],
    );
  }
}

class DashedLineConnector extends StatelessWidget {
  const DashedLineConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          width: 1.5,
          height: 3,
          margin: const EdgeInsets.symmetric(vertical: 1.5),
          color: Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }
}
