import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/logic/performance_guard.dart';
import '../../../core/logic/vehicle_ai_logic.dart';
import '../../marketplace/presentation/marketplace_talleres_screen.dart';
import '../../../core/services/report_service.dart';

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
  Map<String, dynamic> _aiInsights = {};
  List<Map<String, dynamic>> _upcomingIssues = [];
  String _vehicleModel = '';
  String _vehicleBrand = '';
  String _vehicleImage = '';
  bool _isCar = false;
  int _totalKms = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      // Usar historial combinado: Supabase remoto + rutas locales pendientes de sync
      final data = await SyncService().getCombinedRouteHistory(widget.vehiculoId);
      
      // Asignar inmediatamente la data offline-first al estado base
      if (mounted) {
        setState(() {
          _history = data;
        });
      }

      // Obtener info del vehículo para la IA y Reporte (Resistente a fallos de red)
      try {
        final vData = await SupabaseService().client
            .from('vehiculos')
            .select('marca, modelo, kms, image_path')
            .eq('id', widget.vehiculoId)
            .single();
        
        _vehicleBrand = (vData['marca'] as String? ?? '').toUpperCase();
        _vehicleModel = vData['modelo'] ?? 'Vehículo';
        _vehicleImage = vData['image_path'] ?? '';
        _totalKms = (vData['kms'] as num? ?? 0).toInt();
        _isCar = _vehicleBrand == 'TOYOTA' || _vehicleBrand == 'MAZDA' || _vehicleBrand == 'CHEVROLET';
      } catch (e) {
        debugPrint('Historial: Error obteniendo metadata del vehículo (Modo Offline o Timeout): $e');
        _vehicleBrand = 'Desconocido';
        _vehicleModel = 'Vehículo';
        _vehicleImage = '';
        _totalKms = 0;
        _isCar = false;
      }

      if (mounted) {
        setState(() {
          // Ya asignamos data antes, aquí calculamos insights con los fallbacks o reales

          _aiInsights = VehicleAILogic.analyzeJourneyPatterns(
            routeHistory: _history,
            modelName: _vehicleModel,
            isCar: _isCar,
          );
          _upcomingIssues = VehicleAILogic.predictUpcomingIssues(
            totalKms: _totalKms,
            intensity: _aiInsights['intensity'] ?? 'Baja',
          );
        });
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
            tooltip: 'Exportar Reporte PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () {
              ReportService.generateVehicleReport(
                brand: _vehicleBrand,
                model: _vehicleModel,
                vehicleImage: _vehicleImage,
                totalKms: _totalKms,
                routeHistory: _history,
                upcomingIssues: _upcomingIssues,
              );
            },
          ),
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
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildAIHeader(isDark),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
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
                          childCount: _history.length,
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildAIHeader(bool isDark) {
    if (_aiInsights.isEmpty) return const SizedBox.shrink();

    final careScore = (_aiInsights['careScore'] as num?)?.toDouble() ?? 100.0;
    final advice = _aiInsights['advice'] as String? ?? '';
    final intensity = _aiInsights['intensity'] as String? ?? 'Baja';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
            : [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Insights • My Auto Guide',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Uso: $intensity',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Care Score Gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: careScore / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  Text(
                    '${careScore.round()}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Salud del Trayecto',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advice,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_upcomingIssues.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Alertas Técnicas (IA)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ..._upcomingIssues.take(2).map((issue) => _buildIssueItem(issue)),
          ],
        ],
      ),
    );
  }

  Widget _buildIssueItem(Map<String, dynamic> issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[300], size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${issue['item']}: ${issue['reason']}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketplaceTalleresScreen()),
              );
            },
            child: const Text('Ver Taller', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    // Columnas unificadas: origen_name, destino_name, distancia_km, duracion_segundos, consumo_galones, costo_estimado, fecha
    final origen = route['origen_name'] ?? route['origen'] ?? 'Ubicación desconocida';
    final destino = route['destino_name'] ?? route['destino'] ?? 'Destino desconocido';
    
    // Soporte para nombres nuevos y antiguos
    final num? distRaw = route['distancia_km'] ?? route['distancia'];
    final num? fuelRaw = route['consumo_galones'] ?? route['consumo_estimado'];
    final num? costRaw = route['costo_estimado'];

    final kms = distRaw?.toDouble() ?? 0.0;
    final galones = fuelRaw?.toDouble() ?? 0.0;
    final costo = costRaw?.toDouble() ?? 0.0;
    final vMax = (route['velocidad_max'] as num?)?.toDouble() ?? 0.0;
    final vProm = (route['velocidad_prom'] as num?)?.toDouble() ?? 0.0;

    DateTime fecha;
    // Priorizar 'fecha' explícita, luego 'created_at' de Supabase
    final fechaRaw = route['fecha'] ?? route['created_at'];
    
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
                          value: kms > 0 ? '${kms.toStringAsFixed(1)} km' : '0.0 km',
                          label: 'Distancia',
                        ),
                        _Stat(
                          icon: Icons.speed,
                          value: '${vMax.toStringAsFixed(0)} km/h',
                          label: 'Vel. Máx',
                          color: Colors.redAccent,
                        ),
                        _Stat(
                          icon: Icons.av_timer,
                          value: '${vProm.toStringAsFixed(0)} km/h',
                          label: 'Vel. Prom',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(
                          icon: Icons.local_gas_station_rounded,
                          value: galones > 0
                              ? '${galones.toStringAsFixed(2)} gal'
                              : '0.00 gal',
                          label: 'Consumo',
                          color: Colors.orange,
                        ),
                        _Stat(
                          icon: Icons.payments_rounded,
                          value: costo > 0
                              ? '\$${(costo / 1000).toStringAsFixed(1)}k'
                              : '\$0k',
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
