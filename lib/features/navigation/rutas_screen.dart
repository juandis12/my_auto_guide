// =============================================================================
// rutas_screen.dart — NAVEGACIÓN GPS PROFESIONAL & INTELIGENTE (GOOGLE MAPS STYLE)
// =============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/voice_navigation_service.dart';
import 'domain/models/navigation_telemetry.dart';
import 'logic/telemetry_calculator.dart';
import 'presentation/controllers/navigation_controller.dart';
import 'presentation/widgets/navigation_widgets.dart';
import 'presentation/historial_rutas_screen.dart';
import '../../shared/widgets/app_snack_bar.dart';
import '../../../core/services/camera_radar_service.dart';
import '../../../core/services/waze_community_alerts_service.dart';
import 'presentation/widgets/waze_report_sheet.dart';

class RutasScreen extends StatefulWidget {
  final String vehiculoId;
  final int kmsActuales;
  final Map<String, dynamic>? initialRoute;

  const RutasScreen({
    super.key,
    required this.vehiculoId,
    required this.kmsActuales,
    this.initialRoute,
  });

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> with TickerProviderStateMixin {
  final SupabaseClient supabase = SupabaseService().client;
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late NavigationController _controller;
  bool _isLoadingRoute = false;
  String? _vehicleImagePath;
  String _vehiclePlate = '';
  
  List<NominatimPlace> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  StreamSubscription<Position>? _idlePositionSubscription;

  @override
  void initState() {
    super.initState();
    _controller = NavigationController(
      vehicleId: widget.vehiculoId,
      vehicleModel: 'Vehículo',
      isCar: false,
    );
    _controller.addListener(_onControllerStateUpdate);
    _obtenerUbicacionInicial();
    _iniciarSeguimientoIdle();
    _cargarInfoVehiculo();
    CameraRadarService().startRadar();
    WazeCommunityAlertsService().initRealtimeAlerts();

    if (widget.initialRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarRutaDesdeHistorial(widget.initialRoute!);
      });
    }
  }

  void _onControllerStateUpdate() {
    if (mounted) {
      // Si la navegación finalizó por auto-arribo al destino (< 40m)
      if (_controller.state == NavigationState.completed) {
        _finalizarRuta();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    CameraRadarService().stopRadar();
    _controller.removeListener(_onControllerStateUpdate);
    _idlePositionSubscription?.cancel();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─── LÓGICA DE CARGA ────────────────────────────────────
  
  Future<void> _cargarInfoVehiculo() async {
    try {
      final data = await supabase.from('vehiculos').select('modelo, marca, placa, image_path').eq('id', widget.vehiculoId).single();
      final marca = (data['marca'] as String? ?? '').toUpperCase();
      final modelo = data['modelo'] ?? 'Vehículo';
      final placa = data['placa'] ?? '';
      final isCar = marca.contains('TOYOTA') || marca.contains('MAZDA') || marca.contains('CHEVROLET');
      
      if (mounted) {
        setState(() {
          _vehicleImagePath = data['image_path'] as String?;
          _vehiclePlate = placa;
        });
      }
      
      _controller.updateVehicleInfo(model: modelo, isCar: isCar);
    } catch (_) {}
  }

  Future<void> _obtenerUbicacionInicial() async {
    // 1. Obtener la última posición conocida en caché del dispositivo (instantánea en 0ms)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final lastLatLng = LatLng(lastKnown.latitude, lastKnown.longitude);
        _controller.updateCurrentPosition(lastLatLng);
        _mapCtrl.move(lastLatLng, 15);
      }
    } catch (_) {}

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
        return;
      }
    }
    
    // 2. Obtener posición precisa satelital con timeout para no bloquear el renderizado
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _controller.updateCurrentPosition(latLng);
      _mapCtrl.move(latLng, 16);
    } catch (e) {
      debugPrint('Aviso: GPS satelital inicializando en segundo plano: $e');
    }
  }

  void _iniciarSeguimientoIdle() {
    _idlePositionSubscription?.cancel();
    late LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3);
    }

    _idlePositionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      _controller.updateCurrentPosition(latLng, speedMs: position.speed);
    });
  }

  // ─── ACCIONES DE BÚSQUEDA Y MAPA TÁCTIL ─────────────────
  
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _buscarDestino(query);
    });
  }

  Future<void> _buscarDestino(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      _searchResults = await NavigationService().searchDestination(query);
    } catch (_) {
      // Ignorar errores silenciosos en autocompletado
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _seleccionarDestino(NominatimPlace place) {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    _controller.setRouteReady(
      destination: LatLng(place.lat, place.lon),
      destinationName: place.displayName,
      points: [], 
      distanceKm: 0.0,
      durationMin: 0.0,
    );
    _searchCtrl.text = _controller.destinationName;
    setState(() {
      _searchResults = [];
    });
    _trazarRuta();
  }

  /// Manejo táctil del mapa: Toque o Long Press para seleccionar punto de destino
  void _onMapTappedOrLongPressed(LatLng point) async {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchResults = [];
    });

    // Si está en navegación activa, un toque no cambia el destino directamente
    if (_controller.state == NavigationState.navigating || _controller.state == NavigationState.freeTracking) {
      return;
    }

    final curPos = _controller.telemetry.currentPos;
    if (curPos == null) {
      AppSnackBar.show(context, 'Esperando señal GPS...');
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      // 1. Geocodificación inversa para nombre amigable
      final placeName = await NavigationService().reverseGeocode(point);
      _searchCtrl.text = placeName;

      // 2. Calcular ruta vial con OSRM
      final route = await NavigationService().calculateRoute(curPos, point);

      _controller.setRouteReady(
        destination: point,
        destinationName: placeName,
        points: route.points,
        distanceKm: route.distanceKm,
        durationMin: route.durationMin,
        steps: route.steps,
      );

      _mapCtrl.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([curPos, point]),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 90),
        ),
      );
    } catch (e) {
      if (mounted) AppSnackBar.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _trazarRuta() async {
    final curPos = _controller.telemetry.currentPos;
    final dest = _controller.destination;
    if (curPos == null || dest == null) return;
    
    setState(() => _isLoadingRoute = true);
    try {
      final route = await NavigationService().calculateRoute(curPos, dest);
      _controller.setRouteReady(
        destination: dest,
        destinationName: _controller.destinationName,
        points: route.points,
        distanceKm: route.distanceKm,
        durationMin: route.durationMin,
        steps: route.steps,
      );
      _mapCtrl.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([curPos, dest]),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 90),
        ),
      );
    } catch (e) {
      if (mounted) AppSnackBar.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  /// Carga y visualiza en el mapa una ruta seleccionada del historial
  void _cargarRutaDesdeHistorial(Map<String, dynamic> route) async {
    final destName = route['destino_name'] ?? route['destino'] ?? 'Destino Histórico';
    final double dist = ((route['distancia_km'] ?? route['distancia'] ?? 0.0) as num).toDouble();
    final double? vMax = (route['velocidad_max'] as num?)?.toDouble();
    final double? vProm = (route['velocidad_prom'] as num?)?.toDouble();

    List<LatLng> points = [];
    final rawPoints = route['via_puntos'] ?? route['viaPuntos'];
    if (rawPoints != null) {
      try {
        dynamic decoded = rawPoints;
        if (rawPoints is String) decoded = jsonDecode(rawPoints);
        if (decoded is List) {
          for (var p in decoded) {
            if (p is Map) {
              final lat = (p['lat'] ?? p['latitude'] as num?)?.toDouble() ?? 0.0;
              final lng = (p['lng'] ?? p['longitude'] as num?)?.toDouble() ?? 0.0;
              if (lat != 0.0 && lng != 0.0) points.add(LatLng(lat, lng));
            } else if (p is List && p.length >= 2) {
              final lng = (p[0] as num).toDouble();
              final lat = (p[1] as num).toDouble();
              if (lat != 0.0 && lng != 0.0) points.add(LatLng(lat, lng));
            }
          }
        }
      } catch (e) {
        debugPrint('Error parseando puntos históricos: $e');
      }
    }

    if (points.isNotEmpty) {
      _controller.loadHistoricalRoute(
        destinationName: destName,
        points: points,
        distanceKm: dist,
        maxSpeedKmH: vMax,
        avgSpeedKmH: vProm,
      );
      _mapCtrl.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
        ),
      );
      if (mounted) {
        AppSnackBar.show(context, 'Ruta histórica trazada en el mapa.', backgroundColor: const Color(0xFF035880));
      }
    } else {
      final destLat = (route['destino_lat'] as num?)?.toDouble();
      final destLng = (route['destino_lng'] as num?)?.toDouble();
      if (destLat != null && destLng != null && destLat != 0.0 && destLng != 0.0) {
        _searchCtrl.text = destName;
        _onMapTappedOrLongPressed(LatLng(destLat, destLng));
      } else {
        _searchCtrl.text = destName;
        _buscarDestino(destName);
      }
    }
  }

  // ─── CONTROL DE NAVEGACIÓN ──────────────────────────────
  
  void _iniciarNav({bool isFree = false}) async {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    if (await Permission.locationAlways.isDenied) await Permission.locationAlways.request();

    // Solicitar exención de ahorro de batería para evitar que Android suspenda el tracking
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_nav_vehicle_id', widget.vehiculoId);
    await prefs.setString('supabase_url', dotenv.get('SUPABASE_URL'));
    await prefs.setString('supabase_key', dotenv.get('SUPABASE_ANON_KEY'));
    await prefs.setBool('is_navigating', true);
    
    if (!(await service.isRunning())) {
      await service.startService();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    
    _controller.startNavigation(isFree: isFree);

    // Centrar mapa en la ubicación del usuario
    final curPos = _controller.telemetry.currentPos;
    if (curPos != null) {
      _mapCtrl.move(curPos, 16.5);
    }
  }

  Future<void> _finalizarRuta({bool skipSummaryModal = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_navigating', false);

      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
      }
    } catch (e) {
      debugPrint('Error deteniendo background service: $e');
    }
    
    final t = _controller.telemetry;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: No se encontró sesión de usuario activa para guardar el trayecto.');
      }
      _controller.stopNavigation();
      return;
    }

    final durationSec = t.startTime != null ? DateTime.now().difference(t.startTime!).inSeconds : 0;
    
    // Calcular velocidad promedio cinemática exacta
    final double calculatedAvgSpeed = TelemetryCalculator.calculateKinematicAverageSpeed(
      distanceKm: t.distanceKm,
      durationSeconds: durationSec,
      fallbackSpeedKmH: t.averageSpeedKmH,
    );

    final impact = TelemetryCalculator.estimateImpact(
      distanceKm: t.distanceKm, 
      avgSpeedKmH: calculatedAvgSpeed, 
      vehicleModel: _controller.vehicleModel, 
      isCar: _controller.isCar
    );

    final int kmsToAdd = (t.distanceKm >= 0.1)
        ? (t.distanceKm < 1.0 ? 1 : t.distanceKm.round())
        : 0;

    final String destName = (_controller.destinationName.trim().isNotEmpty)
        ? _controller.destinationName
        : 'Recorrido Libre';

    if (t.distanceKm >= 0.01) {
      // Guardar de forma asíncrona segura sin congelar el hilo principal
      unawaited(() async {
        try {
          await SyncService().saveRouteOfflineFirst(
            userId: userId,
            vehicleId: widget.vehiculoId,
            originName: 'Ubicación Actual',
            destinationName: destName,
            distanceKm: t.distanceKm,
            durationSeconds: durationSec,
            consumoGalones: impact['gallons']!,
            costoEstimado: impact['cost']!,
            velocidadMax: t.maxSpeedKmH,
            velocidadProm: calculatedAvgSpeed,
            viaPuntos: t.travelledPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
          );
          
          if (kmsToAdd > 0) {
            await SyncService().updateVehicleKmsOfflineFirst(widget.vehiculoId, kmsToAdd);
          }
        } catch (e) {
          debugPrint('Error al guardar trayecto localmente: $e');
        }
      }());
    } else {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Recorrido demasiado corto. No se registraron cambios significativos.',
          backgroundColor: Colors.orange,
        );
      }
    }

    _controller.stopNavigation();

    // Mostrar modal con el resumen visual del recorrido y limpiar polilínea al cerrar
    if (mounted && !skipSummaryModal) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => TripSummarySheet(
          distanceKm: t.distanceKm,
          durationSeconds: durationSec,
          avgSpeedKmH: calculatedAvgSpeed,
          maxSpeedKmH: t.maxSpeedKmH,
          fuelGallons: impact['gallons'] ?? 0.0,
          estimatedCost: impact['cost'] ?? 0.0,
          destinationName: destName,
          onDismiss: () => Navigator.pop(ctx),
        ),
      );
    }

    _controller.clearRouteAndReset();
  }

  void _recenterMap() {
    final curPos = _controller.telemetry.currentPos;
    if (curPos != null) {
      _mapCtrl.move(curPos, 16.5);
    }
  }

  // ─── BUILD UI ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _controller.telemetry;
    final state = _controller.state;

    return PopScope(
      canPop: state != NavigationState.navigating && state != NavigationState.freeTracking,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ruta en curso'),
            content: const Text('¿Deseas finalizar y guardar el recorrido actual antes de salir?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salir sin guardar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx, false);
                  await _finalizarRuta();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Guardar y Salir'),
              ),
            ],
          ),
        );
        if (ok == true && mounted) {
          _controller.stopNavigation();
          final service = FlutterBackgroundService();
          service.invoke('stopService');
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () {
            _searchFocusNode.unfocus();
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              _buildMap(t),
              _buildTopSearch(),
              
              // Banner Turn-by-Turn durante Navegación
              if (state == NavigationState.navigating && _controller.currentStep != null)
                _buildTurnByTurnBanner(_controller.currentStep!),

              // Alertas de Fotomulta y Radar
              StreamBuilder<RadarAlertState>(
                stream: CameraRadarService().alertStream,
                builder: (context, snapshot) {
                  final alert = snapshot.data ?? RadarAlertState.clear();
                  final isSpeeding = alert.isSpeeding;
                  final isNear = alert.isNearCamera;

                  return Stack(
                    children: [
                      Positioned(
                        top: 0, left: 0, right: 0,
                        height: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSpeeding
                                ? Colors.redAccent
                                : (isNear ? Colors.orangeAccent : const Color(0xFF00FF87)),
                            boxShadow: [
                              BoxShadow(
                                color: isSpeeding
                                    ? Colors.red.withOpacity(0.8)
                                    : (isNear ? Colors.orange.withOpacity(0.8) : const Color(0xFF00FF87).withOpacity(0.5)),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      ),
                      if (isNear && alert.nearestCamera != null)
                        Positioned(
                          top: 110, left: 20, right: 20,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSpeeding
                                      ? const Color(0xFFFF3B30).withOpacity(0.85)
                                      : const Color(0xFF1C1C1E).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSpeeding ? Colors.redAccent : Colors.orangeAccent.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      color: isSpeeding ? Colors.white : Colors.orangeAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '📷 FOTOMULTA a ${alert.distanceMeters.round()}m (${alert.nearestCamera!.city})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Límite: ${alert.nearestCamera!.speedLimitKmH.round()} km/h | Actual: ${alert.currentSpeedKmH.round()} km/h',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Botones Flotantes Laterales (Reportes Waze y Recentrar)
              Positioned(
                right: 16,
                bottom: (state == NavigationState.navigating || state == NavigationState.routeReady) ? 220 : 160,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'btn_voice_nav',
                      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                      onPressed: () {
                        setState(() {
                          VoiceNavigationService().toggleMute();
                        });
                        AppSnackBar.show(
                          context,
                          VoiceNavigationService().isMuted ? 'Guía por voz desactivada' : 'Guía por voz activada',
                          backgroundColor: VoiceNavigationService().isMuted ? Colors.grey[800]! : const Color(0xFF00FF87),
                        );
                      },
                      child: Icon(
                        VoiceNavigationService().isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: VoiceNavigationService().isMuted ? Colors.white54 : const Color(0xFF00FF87),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'btn_recenter_map',
                      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                      onPressed: _recenterMap,
                      child: const Icon(Icons.my_location_rounded, color: Color(0xFF00FF87), size: 20),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'btn_waze_report',
                      backgroundColor: const Color(0xFF0A84FF),
                      onPressed: () {
                        final pos = t.currentPos;
                        if (pos != null) {
                          WazeReportSheet.show(context, lat: pos.latitude, lng: pos.longitude);
                        }
                      },
                      child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              _buildBottomPanel(t, state),
              if (_isLoadingRoute)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMapTileUrl(bool isDark) {
    final stadiaKey = dotenv.isInitialized ? dotenv.get('STADIA_API_KEY', fallback: '') : '';
    
    if (stadiaKey.trim().isNotEmpty && !stadiaKey.contains('your_')) {
      return isDark
          ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=${stadiaKey.trim()}'
          : 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}@2x.png?api_key=${stadiaKey.trim()}';
    }

    // CartoDB Voyager / Dark Matter con subdominios paralelos para máxima velocidad
    return isDark
        ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  Widget _buildMap(NavigationTelemetry t) {
    final centerPos = t.currentPos ?? const LatLng(4.6097, -74.0817);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: centerPos,
        initialZoom: 15,
        onTap: (tapPosition, point) => _onMapTappedOrLongPressed(point),
        onLongPress: (tapPosition, point) => _onMapTappedOrLongPressed(point),
      ),
      children: [
        TileLayer(
          urlTemplate: _getMapTileUrl(isDark),
          subdomains: const ['a', 'b', 'c', 'd'],
          maxZoom: 19,
          keepBuffer: 5,
          panBuffer: 2,
          userAgentPackageName: 'com.myautoguide.app',
        ),
        if (_controller.routePoints.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(
              points: _controller.routePoints,
              strokeWidth: 8,
              color: Colors.blue.withOpacity(0.35),
            ),
            Polyline(
              points: _controller.routePoints,
              strokeWidth: 4.5,
              color: const Color(0xFF00C6FF),
            ),
          ]),
        if (t.travelledPoints.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(
              points: t.travelledPoints,
              strokeWidth: 9,
              color: Colors.green.withOpacity(0.35),
            ),
            Polyline(
              points: t.travelledPoints,
              strokeWidth: 5,
              color: const Color(0xFF00FF87),
            ),
          ]),
        MarkerLayer(markers: [
          if (_controller.destination != null)
            Marker(
              point: _controller.destination!,
              width: 48,
              height: 48,
              child: const Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 44,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          Marker(
            point: t.currentPos!,
            width: 45,
            height: 45,
            child: PulsingLocationMarker(imagePath: _vehicleImagePath),
          ),
        ]),
        StreamBuilder<List<WazeIncidentReport>>(
          stream: WazeCommunityAlertsService().incidentsStream,
          initialData: WazeCommunityAlertsService().currentIncidents,
          builder: (context, snapshot) {
            final alerts = snapshot.data ?? [];
            final markers = alerts.map((a) {
              IconData iconData = Icons.warning_rounded;
              Color iconColor = Colors.orange;

              switch (a.type) {
                case WazeIncidentType.police:
                  iconData = Icons.local_police_rounded;
                  iconColor = const Color(0xFF0A84FF);
                  break;
                case WazeIncidentType.radar:
                  iconData = Icons.camera_alt_rounded;
                  iconColor = const Color(0xFFFF9500);
                  break;
                case WazeIncidentType.accident:
                  iconData = Icons.car_crash_rounded;
                  iconColor = const Color(0xFFFF3B30);
                  break;
                case WazeIncidentType.construction:
                  iconData = Icons.construction_rounded;
                  iconColor = const Color(0xFFFFCC00);
                  break;
                case WazeIncidentType.flooding:
                  iconData = Icons.water_drop_rounded;
                  iconColor = const Color(0xFF30D158);
                  break;
              }

              return Marker(
                point: LatLng(a.latitude, a.longitude),
                width: 38,
                height: 38,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(a.title),
                        content: const Text('Reportado por la comunidad. ¿Sigue ahí el incidente?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              WazeCommunityAlertsService().voteIncident(id: a.id, isStillThere: false);
                              Navigator.pop(ctx);
                              AppSnackBar.show(context, 'Gracias por confirmar.');
                            },
                            child: const Text('No / Se retiró', style: TextStyle(color: Colors.red)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              WazeCommunityAlertsService().voteIncident(id: a.id, isStillThere: true);
                              Navigator.pop(ctx);
                              AppSnackBar.show(context, '¡Gracias por confirmar!', backgroundColor: Colors.green);
                            },
                            child: const Text('Sí, sigue ahí'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                ),
              );
            }).toList();

            return MarkerLayer(markers: markers);
          },
        ),
      ],
    );
  }

  Widget _buildTurnByTurnBanner(NavigationStep step) {
    return Positioned(
      top: 110,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF035880).withOpacity(0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF87),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.turn_right_rounded, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        step.instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (step.distanceMeters > 0)
                        Text(
                          'En aprox. ${step.distanceMeters.round()} metros',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: 50, left: 16, right: 16,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.88) : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    _searchFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    _buscarDestino(value);
                  },
                  onTapOutside: (_) => _searchFocusNode.unfocus(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: '¿A dónde vas? (Toca o mantén en el mapa)',
                    hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black54),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _controller.clearRouteAndReset();
                              setState(() => _searchResults = []);
                            },
                          ),
                        IconButton(
                          tooltip: 'Historial de Rutas',
                          icon: Icon(Icons.history_rounded, color: isDark ? Colors.white70 : Colors.black54), 
                          onPressed: () async {
                            _searchFocusNode.unfocus();
                            FocusScope.of(context).unfocus();
                            final selected = await Navigator.push<Map<String, dynamic>>(
                              context, 
                              MaterialPageRoute(builder: (_) => HistorialRutasScreen(vehiculoId: widget.vehiculoId)),
                            );
                            if (selected != null) {
                              _cargarRutaDesdeHistorial(selected);
                            }
                          },
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: (val) {
                    _searchFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    if (val.trim().isNotEmpty) {
                      _buscarDestino(val.trim());
                    }
                  },
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 250,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.92) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                    itemBuilder: (ctx, i) => ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: Color(0xFF00C6FF), size: 20),
                      title: Text(
                        _searchResults[i].displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => _seleccionarDestino(_searchResults[i]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(NavigationTelemetry t, NavigationState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14171F).withOpacity(0.92) : Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── 1. MODO NAVEGANDO O RECORRIDO LIBRE ─────────
                if (state == NavigationState.navigating || state == NavigationState.freeTracking) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoChip(
                        icon: Icons.speed_rounded,
                        label: '${t.maxSpeedKmH.toStringAsFixed(0)} km/h máx',
                        color: const Color(0xFF00C6FF),
                      ),
                      InfoChip(
                        icon: Icons.straighten_rounded,
                        label: '${t.distanceKm.toStringAsFixed(2)} km',
                        color: const Color(0xFF00FF87),
                      ),
                      InfoChip(
                        icon: Icons.av_timer_rounded,
                        label: '${t.averageSpeedKmH.toStringAsFixed(0)} km/h prom',
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _finalizarRuta,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('FINALIZAR VIAJE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.9),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ] 
                // ─── 2. MODO CÓMO LLEGAR (RUTA LISTA) ─────────────
                else if (state == NavigationState.routeReady) ...[
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.destinationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => _controller.clearRouteAndReset(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoChip(
                        icon: Icons.straighten_rounded,
                        label: '${_controller.routeDistanceKm.toStringAsFixed(1)} km',
                        color: const Color(0xFF00C6FF),
                      ),
                      InfoChip(
                        icon: Icons.timer_outlined,
                        label: '${_controller.routeDurationMin.round()} min',
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _iniciarNav(),
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text('INICIAR NAVEGACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF035880),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
                // ─── 3. MODO VISUALIZACIÓN DE RUTA HISTÓRICA ───────
                else if (state == NavigationState.viewingHistory) ...[
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Color(0xFF00FF87), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.destinationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => _controller.clearRouteAndReset(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoChip(
                        icon: Icons.straighten_rounded,
                        label: '${_controller.routeDistanceKm.toStringAsFixed(1)} km',
                        color: const Color(0xFF00C6FF),
                      ),
                      InfoChip(
                        icon: Icons.speed_rounded,
                        label: '${_controller.telemetry.maxSpeedKmH.toStringAsFixed(0)} km/h',
                        color: const Color(0xFFFF3B30),
                      ),
                      InfoChip(
                        icon: Icons.av_timer_rounded,
                        label: '${_controller.telemetry.averageSpeedKmH.toStringAsFixed(0)} km/h',
                        color: const Color(0xFF00FF87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _controller.clearRouteAndReset(),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('CERRAR VISTA DE RUTA', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF035880),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ]
                // ─── 4. MODO LIVE IDLE DE ESPERA ───────────────────
                else ...[
                  FilledButton.icon(
                    onPressed: () => _iniciarNav(isFree: true),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('INICIAR RECORRIDO LIBRE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF035880),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PulsingLocationMarker extends StatefulWidget {
  final String? imagePath;
  const PulsingLocationMarker({super.key, this.imagePath});
  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44 * _animCtrl.value,
              height: 44 * _animCtrl.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C6FF).withOpacity(1.0 - _animCtrl.value),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF00C6FF), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: ClipOval(
                child: widget.imagePath != null && widget.imagePath!.isNotEmpty
                    ? Image.asset(
                        widget.imagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.motorcycle,
                          size: 18,
                          color: Color(0xFF00C6FF),
                        ),
                      )
                    : const Icon(
                        Icons.motorcycle,
                        size: 18,
                        color: Color(0xFF00C6FF),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
