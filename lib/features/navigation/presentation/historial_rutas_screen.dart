import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  List<LatLng> _extractPoints(dynamic raw) {
    if (raw == null) return [];
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((p) {
            final lat = (p['lat'] as num?)?.toDouble() ?? 0.0;
            final lng = (p['lng'] as num?)?.toDouble() ?? 0.0;
            return LatLng(lat, lng);
          }).where((p) => p.latitude != 0.0 && p.longitude != 0.0).toList();
        }
      } else if (raw is List) {
        return raw.map((p) {
          if (p is Map) {
            final lat = (p['lat'] as num?)?.toDouble() ?? 0.0;
            final lng = (p['lng'] as num?)?.toDouble() ?? 0.0;
            return LatLng(lat, lng);
          }
          return null;
        }).whereType<LatLng>().where((p) => p.latitude != 0.0 && p.longitude != 0.0).toList();
      }
    } catch (e) {
      debugPrint('Error extrayendo puntos del historial: $e');
    }
    return [];
  }

  String _getMapTileUrl(bool isDark) {
    final stadiaKey = dotenv.isInitialized ? dotenv.get('STADIA_API_KEY', fallback: '') : '';
    final cartoKey = dotenv.isInitialized ? dotenv.get('CARTO_API_KEY', fallback: '') : '';
    
    if (stadiaKey.trim().isNotEmpty) {
      return isDark
          ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=${stadiaKey.trim()}'
          : 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}@2x.png?api_key=${stadiaKey.trim()}';
    }

    if (cartoKey.trim().isNotEmpty) {
      return isDark
          ? 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png?api_key=${cartoKey.trim()}'
          : 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png?api_key=${cartoKey.trim()}';
    }

    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
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
      ),
    );
  }

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

    final points = _extractPoints(route['via_puntos']);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Fecha y Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                  if (points.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF87).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_rounded, size: 12, color: Color(0xFF00FF87)),
                          SizedBox(width: 4),
                          Text(
                            'GPS Track',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FF87),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Previsualización interactiva del Mapa si hay puntos de ruta
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
                              // Resplandor
                              Polyline(
                                points: points,
                                strokeWidth: 6,
                                color: const Color(0xFF00FF87).withOpacity(0.4),
                              ),
                              // Línea sólida de neón
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
                                child: const Icon(
                                  Icons.radio_button_checked,
                                  color: Color(0xFF00FF87),
                                  size: 18,
                                ),
                              ),
                              Marker(
                                point: points.last,
                                width: 26,
                                height: 26,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
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
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_out_map_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Ver mapa completo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Información y Métricas del Trayecto
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

/// Modal interactivo de alta resolución para inspeccionar el mapa con la línea de la ruta
class _RouteDetailMapModal extends StatelessWidget {
  final Map<String, dynamic> route;
  final List<LatLng> points;
  final bool isDark;
  final String mapTileUrl;

  const _RouteDetailMapModal({
    required this.route,
    required this.points,
    required this.isDark,
    required this.mapTileUrl,
  });

  @override
  Widget build(BuildContext context) {
    final origen = route['origen_name'] ?? route['origen'] ?? 'Origen';
    final destino = route['destino_name'] ?? route['destino'] ?? 'Destino';
    final num? distRaw = route['distancia_km'] ?? route['distancia'];
    final kms = distRaw?.toDouble() ?? 0.0;
    final vMax = (route['velocidad_max'] as num?)?.toDouble() ?? 0.0;
    final vProm = (route['velocidad_prom'] as num?)?.toDouble() ?? 0.0;

    final center = points.isNotEmpty
        ? points[points.length ~/ 2]
        : const LatLng(4.60971, -74.08175);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        Text(
                          '$origen ➔ $destino',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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

            // Card Flotante Inferior de Estadísticas
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(18),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                      icon: Icons.route_outlined,
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
