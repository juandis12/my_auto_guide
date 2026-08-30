import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/logic/performance_guard.dart';
import '../../../core/logic/vehicle_ai_logic.dart';
import '../../../core/services/report_service.dart';
import '../../marketplace/presentation/marketplace_talleres_screen.dart';
import '../../../core/utils/formatters.dart';

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
  List<WeeklyRouteBucket> _weeklyBuckets = [];
  int _selectedWeekIndex = 0; // 0: Semana en curso / más reciente
  bool _showAllHistory = false;

  Map<String, dynamic> _aiInsights = {};
  List<Map<String, dynamic>> _upcomingIssues = [];
  String _vehicleModel = '';
  String _vehicleBrand = '';
  String _vehiclePlate = '';
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
      // 1. Obtener historial combinado (Supabase + Local SQLite)
      final data = await SyncService().getCombinedRouteHistory(widget.vehiculoId);
      
      // 2. Obtener metadatos del vehículo
      try {
        final vData = await SupabaseService().client
            .from('vehiculos')
            .select('marca, modelo, placa, kms, kilometraje, image_path, foto_url, has_360_view, images_360_urls')
            .eq('id', widget.vehiculoId)
            .single();
        
        _vehicleBrand = (vData['marca'] as String? ?? '').toUpperCase();
        _vehicleModel = vData['modelo'] ?? 'Vehículo';
        _vehiclePlate = vData['placa'] ?? '';
        
        // Priorizar la primera foto del visor 360 si existe; de lo contrario usar foto_url / image_path
        final images360 = (vData['images_360_urls'] is List) 
            ? List<String>.from(vData['images_360_urls']) 
            : <String>[];
        if (images360.isNotEmpty) {
          _vehicleImage = images360.first;
        } else {
          _vehicleImage = vData['image_path'] ?? vData['foto_url'] ?? '';
        }

        final kmsVal = vData['kms'] ?? vData['kilometraje'];
        _totalKms = (kmsVal as num? ?? 0).toInt();
        _isCar = _vehicleBrand.contains('TOYOTA') || _vehicleBrand.contains('MAZDA') || _vehicleBrand.contains('CHEVROLET');
      } catch (e) {
        debugPrint('Historial: Error metadata vehículo: $e');
        _vehicleBrand = 'Vehículo';
        _vehicleModel = '';
        _vehiclePlate = '';
        _vehicleImage = '';
        _totalKms = 0;
        _isCar = false;
      }

      final buckets = VehicleAILogic.groupRoutesByWeek(data);
      
      if (mounted) {
        setState(() {
          _history = data;
          _weeklyBuckets = buckets;
          _selectedWeekIndex = 0;

          // AI Insights para el conjunto activo
          final activeRoutes = _showAllHistory 
              ? _history 
              : (_weeklyBuckets.isNotEmpty ? _weeklyBuckets[_selectedWeekIndex].routes : _history);

          _aiInsights = VehicleAILogic.analyzeJourneyPatterns(
            routeHistory: activeRoutes,
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

  void _onWeekSelected(int index) {
    setState(() {
      _showAllHistory = false;
      _selectedWeekIndex = index;
      final activeRoutes = _weeklyBuckets[index].routes;
      _aiInsights = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: activeRoutes,
        modelName: _vehicleModel,
        isCar: _isCar,
      );
    });
  }

  void _toggleAllHistory() {
    setState(() {
      _showAllHistory = true;
      _aiInsights = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: _history,
        modelName: _vehicleModel,
        isCar: _isCar,
      );
    });
  }

  void _exportPdfReport() {
    final activeRoutes = _showAllHistory 
        ? _history 
        : (_weeklyBuckets.isNotEmpty ? _weeklyBuckets[_selectedWeekIndex].routes : _history);
    
    DateTime? wStart;
    DateTime? wEnd;
    if (!_showAllHistory && _weeklyBuckets.isNotEmpty) {
      wStart = _weeklyBuckets[_selectedWeekIndex].weekStart;
      wEnd = _weeklyBuckets[_selectedWeekIndex].weekEnd;
    }

    ReportService.generateVehicleReport(
      brand: _vehicleBrand,
      model: _vehicleModel,
      plate: _vehiclePlate,
      weekStart: wStart,
      weekEnd: wEnd,
      vehicleImage: _vehicleImage,
      totalKms: _totalKms,
      routeHistory: activeRoutes,
      upcomingIssues: _upcomingIssues,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeRoutes = _showAllHistory
        ? _history
        : (_weeklyBuckets.isNotEmpty ? _weeklyBuckets[_selectedWeekIndex].routes : <Map<String, dynamic>>[]);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial de Viajes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_vehiclePlate.isNotEmpty)
              Text(
                'Placa: $_vehiclePlate • $_vehicleBrand $_vehicleModel',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Exportar Reporte Semanal en PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0A84FF)),
            onPressed: _exportPdfReport,
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Selector Semanal con corte de domingos
                SliverToBoxAdapter(
                  child: _buildWeekSelector(isDark),
                ),

                // Resumen de Métricas Semanales / Globales
                SliverToBoxAdapter(
                  child: _buildWeeklySummaryCard(isDark),
                ),

                // Diagnóstico de IA Insights 100% en español
                SliverToBoxAdapter(
                  child: _buildAIHeader(isDark),
                ),

                // Lista de Rutas
                if (activeRoutes.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = activeRoutes[index];
                          return _RouteCard(
                            route: item,
                            isDark: isDark,
                            onSelectForMainMap: () {
                              if (widget.onRouteSelected != null) {
                                widget.onRouteSelected!(item);
                              }
                              Navigator.of(context).pop(item);
                            },
                          );
                        },
                        childCount: activeRoutes.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 30),
                ),
              ],
            ),
    );
  }

  Widget _buildWeekSelector(bool isDark) {
    if (_weeklyBuckets.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...List.generate(_weeklyBuckets.length, (i) {
            final bucket = _weeklyBuckets[i];
            final isSelected = !_showAllHistory && _selectedWeekIndex == i;
            final isCurrentWeek = i == 0;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  isCurrentWeek ? 'Esta Semana (${bucket.label})' : bucket.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF035880),
                backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                onSelected: (_) => _onWeekSelected(i),
              ),
            );
          }),
          ChoiceChip(
            label: Text(
              'Todo el Historial (${_history.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _showAllHistory ? FontWeight.bold : FontWeight.normal,
                color: _showAllHistory ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            selected: _showAllHistory,
            selectedColor: const Color(0xFF035880),
            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            onSelected: (_) => _toggleAllHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(bool isDark) {
    double dist = 0.0;
    double fuel = 0.0;
    double cost = 0.0;
    int count = 0;
    String periodTitle = 'Semana en Curso';

    if (_showAllHistory) {
      periodTitle = 'Histórico Consolidado Completo';
      for (var r in _history) {
        dist += (r['distancia_km'] ?? r['distancia'] ?? 0.0) as num;
        fuel += (r['consumo_galones'] ?? r['consumo_estimado'] ?? 0.0) as num;
        cost += (r['costo_estimado'] ?? 0.0) as num;
      }
      count = _history.length;
    } else if (_weeklyBuckets.isNotEmpty) {
      final b = _weeklyBuckets[_selectedWeekIndex];
      periodTitle = _selectedWeekIndex == 0 ? 'Semana en Curso (Corte Domingo)' : b.label;
      dist = b.totalDistanceKm;
      fuel = b.totalGallons;
      cost = b.totalCostCop;
      count = b.routes.length;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF00C6FF)),
                  const SizedBox(width: 6),
                  Text(
                    periodTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count trayectos',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00C6FF)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                icon: Icons.straighten_rounded,
                value: '${dist.toStringAsFixed(1)} km',
                label: 'Distancia',
                color: const Color(0xFF00C6FF),
              ),
              _Stat(
                icon: Icons.local_gas_station_rounded,
                value: '${fuel.toStringAsFixed(2)} gal',
                label: 'Consumo',
                color: Colors.orangeAccent,
              ),
              _Stat(
                icon: Icons.payments_rounded,
                value: '\$${AppFormat.thousands(cost)}',
                label: 'Gasto COP',
                color: const Color(0xFF00FF87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 60, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text(
            'Sin trayectos registrados en esta semana',
            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'El contador se reinicia a 0 cada domingo a medianoche.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAIHeader(bool isDark) {
    if (_aiInsights.isEmpty) return const SizedBox.shrink();

    final careScore = (_aiInsights['careScore'] as num?)?.toDouble() ?? 100.0;
    final advice = _aiInsights['advice'] as String? ?? 'Operación en parámetros normales.';
    final intensity = _aiInsights['intensity'] as String? ?? 'Baja';
    final healthStatus = _aiInsights['healthStatus'] as String? ?? 'Óptima';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF10284E), const Color(0xFF193D70)]
            : [const Color(0xFF035880), const Color(0xFF023E5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF035880).withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF00FF87), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'IA INSIGHTS • MY AUTO GUIDE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Uso: $intensity',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Gauge de Salud / Care Score
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: careScore / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(
                        careScore >= 80 ? const Color(0xFF00FF87) : (careScore >= 60 ? Colors.orangeAccent : Colors.redAccent),
                      ),
                    ),
                  ),
                  Text(
                    '${careScore.round()}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salud del Activo: $healthStatus',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advice,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_upcomingIssues.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),
            const Text(
              'Alertas Técnicas Preventivas',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 6),
            ..._upcomingIssues.take(2).map((issue) => _buildIssueItem(issue)),
          ],
        ],
      ),
    );
  }

  Widget _buildIssueItem(Map<String, dynamic> issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[300], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${issue['item']}: ${issue['reason']}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketplaceTalleresScreen()),
              );
            },
            child: const Text('Taller', style: TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final bool isDark;
  final VoidCallback onSelectForMainMap;

  const _RouteCard({
    required this.route,
    required this.isDark,
    required this.onSelectForMainMap,
  });

  List<LatLng> _extractPoints(dynamic raw) {
    if (raw == null) return [];
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        return _extractPoints(decoded);
      }
      if (raw is List) {
        final List<LatLng> list = [];
        for (var p in raw) {
          if (p is Map) {
            final lat = (p['lat'] ?? p['latitude'] as num?)?.toDouble() ?? 0.0;
            final lng = (p['lng'] ?? p['longitude'] as num?)?.toDouble() ?? 0.0;
            if (lat != 0.0 && lng != 0.0) list.add(LatLng(lat, lng));
          } else if (p is List && p.length >= 2) {
            // GeoJSON coordinates are [lng, lat]
            final lng = (p[0] as num).toDouble();
            final lat = (p[1] as num).toDouble();
            if (lat != 0.0 && lng != 0.0) list.add(LatLng(lat, lng));
          }
        }
        return list;
      }
    } catch (e) {
      debugPrint('Error extrayendo puntos de ruta: $e');
    }
    return [];
  }

  String _getMapTileUrl(bool isDark) {
    final stadiaKey = dotenv.isInitialized ? dotenv.get('STADIA_API_KEY', fallback: '') : '';
    
    if (stadiaKey.trim().isNotEmpty && !stadiaKey.contains('your_')) {
      return isDark
          ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=${stadiaKey.trim()}'
          : 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}@2x.png?api_key=${stadiaKey.trim()}';
    }

    // CartoDB Voyager / Dark Matter (Open standard CDN sin marca de agua)
    return isDark
        ? 'https://a.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png'
        : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  void _openDetailMap(BuildContext context, List<LatLng> points) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RouteDetailMapModal(
        route: route,
        points: points,
        isDark: isDark,
        mapTileUrl: _getMapTileUrl(isDark),
        onSelectForMainMap: () {
          Navigator.pop(ctx);
          onSelectForMainMap();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final origen = route['origen_name'] ?? route['origen'] ?? 'Ubicación Actual';
    final destino = route['destino_name'] ?? route['destino'] ?? 'Destino';
    final num? distRaw = route['distancia_km'] ?? route['distancia'];
    final num? fuelRaw = route['consumo_galones'] ?? route['consumo_estimado'];
    final num? costRaw = route['costo_estimado'];

    final kms = distRaw?.toDouble() ?? 0.0;
    final galones = fuelRaw?.toDouble() ?? 0.0;
    final costo = costRaw?.toDouble() ?? 0.0;
    final vMax = (route['velocidad_max'] as num?)?.toDouble() ?? 0.0;
    final vProm = (route['velocidad_prom'] as num?)?.toDouble() ?? 0.0;

    final points = _extractPoints(route['via_puntos'] ?? route['viaPuntos']);

    DateTime fecha;
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
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          if (!PerformanceGuard().isLowEnd)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Fecha y Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF035880).withOpacity(0.25) : const Color(0xFF035880).withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF00C6FF)),
                      const SizedBox(width: 8),
                      Text(
                        '${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (points.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF87).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.polyline_rounded, size: 11, color: Color(0xFF00FF87)),
                              SizedBox(width: 4),
                              Text('Ruta GPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00FF87))),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onSelectForMainMap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF035880),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.map_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Ver en Mapa', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Previsualización interactiva del Mapa si hay puntos
            if (points.isNotEmpty)
              GestureDetector(
                onTap: () => _openDetailMap(context, points),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      AbsorbPointer(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: points[points.length ~/ 2],
                            initialZoom: 13,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: _getMapTileUrl(isDark),
                              userAgentPackageName: 'com.myautoguide.app',
                            ),
                            PolylineLayer(polylines: [
                              Polyline(
                                points: points,
                                strokeWidth: 6,
                                color: const Color(0xFF00FF87).withOpacity(0.4),
                              ),
                              Polyline(
                                points: points,
                                strokeWidth: 3.5,
                                color: const Color(0xFF00FF87),
                              ),
                            ]),
                            MarkerLayer(markers: [
                              Marker(
                                point: points.first,
                                width: 22,
                                height: 22,
                                child: const Icon(Icons.radio_button_checked, color: Color(0xFF00FF87), size: 16),
                              ),
                              Marker(
                                point: points.last,
                                width: 26,
                                height: 26,
                                child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 22),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen_rounded, size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Ampliar ruta', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Información y Métricas del Trayecto
            InkWell(
              onTap: () => points.isNotEmpty ? _openDetailMap(context, points) : onSelectForMainMap(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _LocationRow(icon: Icons.circle_outlined, text: origen, color: Colors.grey),
                    const Padding(
                      padding: EdgeInsets.only(left: 11),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DashedLineConnector(),
                      ),
                    ),
                    _LocationRow(icon: Icons.location_on, text: destino, color: Colors.redAccent),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Stat(
                          icon: Icons.straighten_rounded,
                          value: '${kms.toStringAsFixed(1)} km',
                          label: 'Distancia',
                          color: const Color(0xFF00C6FF),
                        ),
                        _Stat(
                          icon: Icons.speed_rounded,
                          value: '${vMax.toStringAsFixed(0)} km/h',
                          label: 'Vel. Máx',
                          color: Colors.redAccent,
                        ),
                        _Stat(
                          icon: Icons.av_timer_rounded,
                          value: '${vProm.toStringAsFixed(0)} km/h',
                          label: 'Vel. Prom',
                          color: Colors.blueAccent,
                        ),
                        _Stat(
                          icon: Icons.local_gas_station_rounded,
                          value: '${galones.toStringAsFixed(2)} gal',
                          label: 'Consumo',
                          color: Colors.orangeAccent,
                        ),
                        _Stat(
                          icon: Icons.payments_rounded,
                          value: '\$${AppFormat.thousands(costo)}',
                          label: 'Gasto',
                          color: const Color(0xFF00FF87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal interactivo de alta resolución para inspeccionar el mapa con la línea de la ruta
class _RouteDetailMapModal extends StatelessWidget {
  final Map<String, dynamic> route;
  final List<LatLng> points;
  final bool isDark;
  final String mapTileUrl;
  final VoidCallback onSelectForMainMap;

  const _RouteDetailMapModal({
    required this.route,
    required this.points,
    required this.isDark,
    required this.mapTileUrl,
    required this.onSelectForMainMap,
  });

  @override
  Widget build(BuildContext context) {
    final origen = route['origen_name'] ?? route['origen'] ?? 'Origen';
    final destino = route['destino_name'] ?? route['destino'] ?? 'Destino';
    final num? distRaw = route['distancia_km'] ?? route['distancia'];
    final kms = distRaw?.toDouble() ?? 0.0;
    final vMax = (route['velocidad_max'] as num?)?.toDouble() ?? 0.0;
    final vProm = (route['velocidad_prom'] as num?)?.toDouble() ?? 0.0;
    final cost = (route['costo_estimado'] as num?)?.toDouble() ?? 0.0;

    final center = points.isNotEmpty
        ? points[points.length ~/ 2]
        : const LatLng(4.60971, -74.08175);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14171F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: [
            // Mapa interactivo
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                initialCameraFit: points.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(50),
                      )
                    : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: mapTileUrl,
                  userAgentPackageName: 'com.myautoguide.app',
                ),
                if (points.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 9,
                      color: const Color(0xFF00FF87).withOpacity(0.35),
                    ),
                    Polyline(
                      points: points,
                      strokeWidth: 5,
                      color: const Color(0xFF00FF87),
                    ),
                  ]),
                if (points.isNotEmpty)
                  MarkerLayer(markers: [
                    Marker(
                      point: points.first,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF87),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                      ),
                    ),
                    Marker(
                      point: points.last,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 38,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
                      ),
                    ),
                  ]),
              ],
            ),

            // Barra Superior Flotante con Botón de Cierre
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1C1C1E) : Colors.white).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.route, color: Color(0xFF00FF87), size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '$origen ➔ $destino',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1C1C1E) : Colors.white).withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            // Card Flotante Inferior de Estadísticas con botón de Trazar en Mapa
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF14171F) : Colors.white).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(
                          icon: Icons.straighten_rounded,
                          value: '${kms.toStringAsFixed(1)} km',
                          label: 'Distancia',
                          color: const Color(0xFF00C6FF),
                        ),
                        _Stat(
                          icon: Icons.av_timer_rounded,
                          value: '${vProm.toStringAsFixed(0)} km/h',
                          label: 'Vel. Promedio',
                          color: const Color(0xFF00FF87),
                        ),
                        _Stat(
                          icon: Icons.speed_rounded,
                          value: '${vMax.toStringAsFixed(0)} km/h',
                          label: 'Vel. Máxima',
                          color: const Color(0xFFFF3B30),
                        ),
                        _Stat(
                          icon: Icons.payments_rounded,
                          value: '\$${AppFormat.thousands(cost)}',
                          label: 'Gasto COP',
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onSelectForMainMap,
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text('CARGAR Y VER EN MAPA PRINCIPAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF035880),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
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
  const _LocationRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 18, color: color ?? (isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white38 : Colors.black45)),
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
          height: 2.5,
          margin: const EdgeInsets.symmetric(vertical: 1.2),
          color: Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }
}
