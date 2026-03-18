// =============================================================================
// rutas_screen.dart — NAVEGACIÓN GPS CON MAPA INTERACTIVO
// =============================================================================
//
// Pantalla de navegación tipo Waze usando tecnologías 100% gratuitas:
//   - Mapa: OpenStreetMap con tiles de CartoDB Voyager (alta calidad visual).
//   - Geocodificación: Nominatim (búsqueda de direcciones y lugares).
//   - Cálculo de ruta: OSRM (Open Source Routing Machine).
//   - GPS: Plugin Geolocator para seguimiento en tiempo real.
//
// FLUJO DE USO:
//   1. IDLE: Se muestra el mapa centrado en la ubicación actual del usuario.
//      El usuario busca un destino en la barra de búsqueda.
//   2. ROUTE_READY: Se traza la ruta óptima (línea azul).
//      Se muestra distancia y tiempo estimado en el panel inferior.
//   3. NAVIGATING: El GPS sigue al usuario en tiempo real.
//      La ruta recorrida se marca en verde y se acumula distancia.
//   4. COMPLETED: Al llegar al destino (o finalizar manualmente), se
//      actualiza el kilometraje del vehículo en Supabase sumando los
//      km recorridos.
//
// MÉTODOS PRINCIPALES:
//   - [_obtenerUbicacion]: Solicita permisos GPS y obtiene la posición actual.
//   - [_buscarDestino]: Llama a la API de Nominatim para buscar lugares.
//   - [_trazarRuta]: Llama a la API de OSRM para calcular la ruta óptima.
//   - [_iniciarNavegacion]: Escucha el stream del GPS y trackea el recorrido.
//   - [_completarRuta]: Suma km recorridos al vehículo en Supabase.
//   - [_finalizarManual]: Permite al usuario terminar la ruta manualmente.
//   - [_cancelarRuta]: Resetea el estado y cancela la navegación.
//   - [_Iniciarrecodidolibre]: Si lo presionas, la app seguirá tu ubicación y sumará los kilómetros que recorras directamente al kilometraje de tu vehículo en la base de datos, sin necesidad de que pongas un destino específico. .

//
// WIDGETS AUXILIARES:
//   - [_InfoRow]: Fila de información en el diálogo de ruta completada.
//   - [_InfoChip]: Chip con ícono para distancia, tiempo y km recorridos.
//
// Parámetros requeridos:
//   - vehiculoId: ID del vehículo en Supabase para actualizar el kilometraje.
//   - kmsActuales: Kilometraje actual del vehículo antes de iniciar la ruta.
//
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/logic/vehicle_performance_logic.dart';
import '../../../core/services/sync_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'presentation/historial_rutas_screen.dart';

class RutasScreen extends StatefulWidget {
  final String vehiculoId;
  final int kmsActuales;

  const RutasScreen({
    super.key,
    required this.vehiculoId,
    required this.kmsActuales,
  });

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

enum _RouteState { idle, routeReady, navigating, completed, freeTracking }

class _RutasScreenState extends State<RutasScreen>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = SupabaseService().client;
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  // Estado
  _RouteState _state = _RouteState.idle;
  LatLng? _currentPos;
  LatLng? _destination;
  String _destinationName = '';
  List<LatLng> _routePoints = [];
  List<LatLng> _travelledPoints = [];
  double _routeDistanceKm = 0.0;
  double _routeDurationMin = 0.0;
  double _travelledDistanceKm = 0.0;
  DateTime? _navStartTime;

  // Datos Vehículo
  String _vehicleModel = '';
  bool _isCar = false;
  final String _originName = 'Ubicación Actual';

  // Búsqueda
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Tracking
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;
  bool _isLoadingRoute = false;
  bool _showSuccessOverlay = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _checkActiveService();
    _cargarInfoVehiculo();
  }

  Future<void> _checkActiveService() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      // Reconectar al stream de actualizaciones
      _serviceSubscription?.cancel();
      _serviceSubscription = service.on('update').listen((event) {
        if (!mounted) return;
        final double lat = (event?['lat'] as num?)?.toDouble() ?? 0.0;
        final double lng = (event?['lng'] as num?)?.toDouble() ?? 0.0;
        final double distanceKm = (event?['distance'] as num?)?.toDouble() ?? 0.0;
        
        if (lat == 0.0 && lng == 0.0) return; // Ignorar coordenas nulas del GPS

        setState(() {
          _currentPos = LatLng(lat, lng);
          _travelledDistanceKm = distanceKm;
          if (_travelledPoints.isEmpty || _travelledPoints.last != _currentPos) {
             _travelledPoints.add(_currentPos!);
          }
          
          // Prevención de Out of Memory (OOM) en viajes muy largos
          if (_travelledPoints.length > 5000) {
            _travelledPoints.removeAt(0);
          }

          _state = _RouteState.freeTracking; // Asumimos modo libre por ahora si reconecta
        });
      });
    }
  }

  Future<void> _cargarInfoVehiculo() async {
    try {
      final data = await supabase
          .from('vehiculos')
          .select('modelo, marca')
          .eq('id', widget.vehiculoId)
          .single();
      setState(() {
        final marca = (data['marca'] as String? ?? '').toUpperCase();
        _vehicleModel = data['modelo'] ?? 'Moto Genérica';
        // Determinar si es carro basado en la marca (Toyota, Mazda, Chevrolet son carros en este catálogo)
        _isCar = marca == 'TOYOTA' || marca == 'MAZDA' || marca == 'CHEVROLET';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── UBICACIÓN ──────────────────────────────────────────
  Future<void> _obtenerUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa el GPS para usar Rutas')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado')),
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permiso de ubicación denegado permanentemente'),
        ),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() {
      _currentPos = LatLng(pos.latitude, pos.longitude);
    });
    _mapCtrl.move(_currentPos!, 15);
  }

  // ─── BÚSQUEDA DE DESTINO (Nominatim) ───────────────────
  Future<void> _buscarDestino(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&addressdetails=1',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'MyAutoGuide/1.0',
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          _searchResults = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception('El servidor de mapas no respondió (Code: ${res.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar dirección: Valida tu conexión a Internet o intenta nuevamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _seleccionarDestino(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    setState(() {
      _destination = LatLng(lat, lon);
      _destinationName = place['display_name'] ?? 'Destino';
      _searchResults = [];
      _searchCtrl.text = _destinationName.length > 50
          ? '${_destinationName.substring(0, 50)}...'
          : _destinationName;
    });
    _trazarRuta();
  }

  // ─── TRAZAR RUTA (OSRM) ────────────────────────────────
  Future<void> _trazarRuta() async {
    if (_currentPos == null || _destination == null) return;
    setState(() => _isLoadingRoute = true);
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_currentPos!.longitude},${_currentPos!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          throw Exception('No se encontró una ruta válida hacia este destino.');
        }

        final route = data['routes'][0];
        final coords = route['geometry']['coordinates'] as List;
        final distMeters = (route['distance'] as num).toDouble();
        final durSeconds = (route['duration'] as num).toDouble();

        final points = coords
            .map((c) =>
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        setState(() {
          _routePoints = points;
          _routeDistanceKm = distMeters / 1000;
          _routeDurationMin = durSeconds / 60;
          _state = _RouteState.routeReady;
          _isLoadingRoute = false;
        });

        // Ajustar mapa para ver toda la ruta
        final bounds = LatLngBounds.fromPoints([_currentPos!, _destination!]);
        _mapCtrl.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al trazar ruta: $e')),
        );
      }
    }
  }

  // ─── HISTORIAL / RECENT ROUTES (UX Mejorada) ─────────────────────────
  Future<void> _openRouteHistory() async {
    final selected = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => HistorialRutasScreen(vehiculoId: widget.vehiculoId),
      ),
    );
    if (selected != null) {
      final destino = (selected['destino_name'] as String?) ?? '';
      if (destino.isNotEmpty) {
        await _goToDestinationName(destino);
      }
    }
  }

  Future<void> _goToDestinationName(String name) async {
    if (name.isEmpty) return;

    // Mostrar en la barra de búsqueda y trazar ruta automáticamente
    _searchCtrl.text = name;
    await _buscarDestino(name);

    if (_searchResults.isNotEmpty) {
      _seleccionarDestino(_searchResults.first);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontró la ubicación para "$name"')),
        );
      }
    }
  }

  // ─── INICIAR NAVEGACIÓN ─────────────────────────────────
  void _iniciarNavegacion({bool isFree = false}) async {
    // 1. Verificar permisos de notificaciones (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. Verificar permisos de localización SIEMPRE (Requerido para background en algunos dispositivos)
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }

    final service = FlutterBackgroundService();
    
    // Guardar ID del vehículo activo para el servicio
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_nav_vehicle_id', widget.vehiculoId);
    
    try {
      if (!(await service.isRunning())) {
        await service.startService();
        // Give service a moment to boot up before subscribing to its streams
        await Future.delayed(const Duration(milliseconds: 800));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar servicio de fondo: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _state = isFree ? _RouteState.freeTracking : _RouteState.navigating;
      _travelledPoints = [_currentPos!];
      _travelledDistanceKm = 0.0;
      _navStartTime = DateTime.now();
      if (isFree) {
        _destination = null;
        _destinationName = 'Recorrido Libre';
        _routePoints = [];
      }
    });

    if (isFree) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modo Libre Iniciado: Rastreo GPS activado')),
        );
    }

    // Escuchar actualizaciones del servicio de fondo
    _serviceSubscription?.cancel();
    _serviceSubscription = service.on('update').listen((event) {
      if (!mounted) return;
      
      final double lat = (event?['lat'] as num?)?.toDouble() ?? 0.0;
      final double lng = (event?['lng'] as num?)?.toDouble() ?? 0.0;
      final double distanceKm = (event?['distance'] as num?)?.toDouble() ?? 0.0;
      
      if (lat == 0.0 && lng == 0.0) return; // Rechazar coordenadas inválidas
      
      final newPos = LatLng(lat, lng);

      setState(() {
        _currentPos = newPos;
        _travelledPoints.add(newPos);
        
        // Límite de puntos para evitar Crash por OOM (Out Of Memory)
        if (_travelledPoints.length > 5000) {
          _travelledPoints.removeAt(0);
        }

        _travelledDistanceKm = distanceKm;
      });

      // Centrar mapa
      _mapCtrl.move(newPos, _mapCtrl.camera.zoom);

      // Verificar llegada
      if (_destination != null) {
        const distanceCalc = Distance();
        final distToEnd = distanceCalc.as(LengthUnit.Meter, newPos, _destination!);
        if (distToEnd < 50) {
          _completarRuta();
        }
      }
    });
  }

  // ─── COMPLETAR RUTA ─────────────────────────────────────
  Future<void> _completarRuta() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    final kmsRecorridos = _travelledDistanceKm;

    // Obtener userId
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('Error: Usuario no autenticado');
      return;
    }

    // Calcular duración
    final durationSec = _navStartTime != null
        ? DateTime.now().difference(_navStartTime!).inSeconds
        : 0;

    // Calcular consumo y costo
    final galones = VehiclePerformanceLogic.estimateFuelConsumption(
        kmsRecorridos, _vehicleModel,
        isCar: _isCar);
    final costo = VehiclePerformanceLogic.estimateFuelCost(galones);

    // Usar SyncService para guardar offline-first
    try {
      // Guardar ruta offline-first
      await SyncService().saveRouteOfflineFirst(
        userId: userId,
        vehicleId: widget.vehiculoId,
        originName: _originName,
        destinationName: _destinationName,
        distanceKm: kmsRecorridos,
        durationSeconds: durationSec,
        consumoGalones: galones,
        costoEstimado: costo,
      );

      // Actualizar KMS offline-first
      await SyncService().updateVehicleKmsOfflineFirst(
          widget.vehiculoId, kmsRecorridos.round());

      debugPrint('Ruta guardada exitosamente (offline-first)');
    } catch (e) {
      debugPrint('Error guardando ruta offline: $e');
      // Aun si falla, mostrar el diálogo de éxito ya que se guardó localmente
    }

    setState(() {
      _state = _RouteState.completed;
      _showSuccessOverlay = true;
    });

    // Pequeño delay para la animación de éxito antes del diálogo
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() => _showSuccessOverlay = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              '¡Ruta completada!',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(
              icon: Icons.straighten,
              label: 'Distancia recorrida',
              value: '${kmsRecorridos.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.speed,
              label: 'Kilómetros recorridos',
              value: '${kmsRecorridos.round()} km',
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.local_gas_station,
              label: 'Consumo estimado',
              value: '${galones.toStringAsFixed(2)} gal',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.payments,
              label: 'Costo estimado',
              value: '\$${costo.toStringAsFixed(0)} COP',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // Volver a inicio
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // ─── FINALIZAR MANUALMENTE ──────────────────────────────
  Future<void> _finalizarManual() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar ruta'),
        content: Text(
          '¿Deseas finalizar la ruta?\n'
          'Has recorrido ${_travelledDistanceKm.toStringAsFixed(1)} km.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _completarRuta();
    }
  }

  // ─── CANCELAR ───────────────────────────────────────────
  void _cancelarRuta() {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    setState(() {
      _state = _RouteState.idle;
      _destination = null;
      _destinationName = '';
      _routePoints = [];
      _travelledPoints = [];
      _routeDistanceKm = 0.0;
      _routeDurationMin = 0.0;
      _travelledDistanceKm = 0.0;
      _searchCtrl.clear();
    });
  }

  // ─── INICIAR RECORRIDO LIBRE ────────────────────────────
  void _iniciarRecorridoLibre() {
    if (_currentPos == null) return;
    _iniciarNavegacion(isFree: true);
  }

  // ─── BUILD ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // === MAPA ===
          _currentPos == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Obteniendo ubicación...'),
                    ],
                  ),
                )
              : FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _currentPos!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: Theme.of(context).brightness ==
                              Brightness.dark
                          ? 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png'
                          : 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                      userAgentPackageName: 'com.example.my_auto_guide',
                      tileDisplay: const TileDisplay
                          .fadeIn(), // Mejora visual y de performance
                    ),
                    // Ruta trazada
                    if (_routePoints.isNotEmpty)
                      RepaintBoundary(
                        child: PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5,
                              color: Colors.blue.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                    // Recorrido en navegación
                    if (_travelledPoints.length > 1)
                      RepaintBoundary(
                        child: PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _travelledPoints,
                              strokeWidth: 6,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    // Marcadores
                    RepaintBoundary(
                      child: MarkerLayer(
                        markers: [
                          // Posición actual
                          Marker(
                            point: _currentPos!,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          // Destino
                          if (_destination != null)
                            Marker(
                              point: _destination!,
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

          // === BARRA SUPERIOR ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    // Botón volver + barra búsqueda
                    Row(
                      children: [
                        Material(
                          elevation: 4,
                          shape: const CircleBorder(),
                          color: Theme.of(context).cardColor,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.arrow_back,
                                size: 22,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón rápido para ver historial y repetir rutas
                        Material(
                          elevation: 4,
                          shape: const CircleBorder(),
                          color: Theme.of(context).cardColor,
                          child: IconButton(
                            icon: const Icon(Icons.history),
                            tooltip: 'Historial de rutas',
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                            onPressed: _openRouteHistory,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_state == _RouteState.idle ||
                            _state == _RouteState.routeReady)
                          Expanded(
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(30),
                              color: Theme.of(context).cardColor,
                              child: TextField(
                                controller: _searchCtrl,
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Buscar destino...',
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.blueGrey,
                                  ),
                                  suffixIcon: _isSearching
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : _searchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white70
                                                  : Colors.blueGrey,
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(
                                                    () => _searchResults = []);
                                              },
                                            )
                                          : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged: (v) => _buscarDestino(v),
                              ),
                            ),
                          ),
                        if (_state == _RouteState.navigating ||
                            _state == _RouteState.freeTracking)
                          Expanded(
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(30),
                              color: _state == _RouteState.freeTracking
                                  ? Colors.blueGrey.shade700
                                  : Colors.green.shade600,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                        _state == _RouteState.freeTracking
                                            ? Icons.sensors
                                            : Icons.navigation,
                                        color: Colors.white,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _state == _RouteState.freeTracking
                                            ? 'Modo Libre • ${_travelledDistanceKm.toStringAsFixed(1)} km'
                                            : 'Navegando • ${_travelledDistanceKm.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Resultados de búsqueda
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4, left: 48),
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 48),
                          itemBuilder: (ctx, i) {
                            final place = _searchResults[i];
                            final name = place['display_name'] ?? '';
                            return ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on,
                                    color: Colors.blue, size: 18),
                              ),
                              title: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              onTap: () => _seleccionarDestino(place),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // === LOADING RUTA ===
          if (_isLoadingRoute)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Trazando ruta óptima...'),
                    ],
                  ),
                ),
              ),
            ),

          // === PANEL INFERIOR ===
          if (_state == _RouteState.idle ||
              _state == _RouteState.routeReady ||
              _state == _RouteState.navigating ||
              _state == _RouteState.freeTracking)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barra decorativa
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Estado Idle: Botón Modo Libre
                      if (_state == _RouteState.idle)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _iniciarRecorridoLibre,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Iniciar Recorrido Libre'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blueGrey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      // Destino (solo si no es Modo Libre)
                      if (_state != _RouteState.idle &&
                          _state != _RouteState.freeTracking)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.flag,
                                  color: Colors.redAccent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _destinationName.length > 60
                                    ? '${_destinationName.substring(0, 60)}...'
                                    : _destinationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      // Título Modo Libre
                      if (_state == _RouteState.freeTracking)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.sensors,
                                  color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Seguimiento de Kilometraje Libre',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_state != _RouteState.idle)
                        const SizedBox(height: 14),
                      // Info ruta
                      if (_state != _RouteState.idle)
                        Row(
                          children: [
                            if (_state != _RouteState.freeTracking)
                              _InfoChip(
                                icon: Icons.straighten,
                                label:
                                    '${_routeDistanceKm.toStringAsFixed(1)} km',
                                color: Colors.blue,
                              ),
                            if (_state != _RouteState.freeTracking)
                              const SizedBox(width: 12),
                            if (_state != _RouteState.freeTracking)
                              _InfoChip(
                                icon: Icons.access_time,
                                label: '${_routeDurationMin.round()} min',
                                color: Colors.orange,
                              ),
                            if (_state == _RouteState.navigating ||
                                _state == _RouteState.freeTracking) ...[
                              if (_state != _RouteState.freeTracking)
                                const SizedBox(width: 12),
                              _InfoChip(
                                icon: _state == _RouteState.freeTracking
                                    ? Icons.add_road
                                    : Icons.directions_bike,
                                label:
                                    '${_travelledDistanceKm.toStringAsFixed(1)} km',
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                      if (_state != _RouteState.idle)
                        const SizedBox(height: 16),
                      // Botones
                      if (_state == _RouteState.routeReady)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelarRuta,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () => _iniciarNavegacion(),
                                icon: const Icon(Icons.navigation),
                                label: const Text('Iniciar ruta'),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.green.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_state == _RouteState.navigating ||
                          _state == _RouteState.freeTracking)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _finalizarManual,
                            icon: const Icon(Icons.stop_circle),
                            label: const Text('Finalizar recorrido'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // === BOTÓN MI UBICACIÓN ===
          if ((_state != _RouteState.navigating &&
                  _state != _RouteState.freeTracking) &&
              _currentPos != null)
            Positioned(
              right: 16,
              bottom: _state == _RouteState.routeReady ? 220 : 24,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'myLocation',
                backgroundColor: Theme.of(context).cardColor,
                onPressed: () {
                  if (_currentPos != null) {
                    _mapCtrl.move(_currentPos!, 16);
                  }
                },
                child: Icon(Icons.my_location,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blueAccent
                        : Colors.blue),
              ),
            ),

          // OVERLAY DE ÉXITO ANIMADO (Micro-animación Premium)
          if (_showSuccessOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const _SuccessCheckmark(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── WIDGETS AUXILIARES ───────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blueAccent
                : Colors.blueGrey,
            size: 20),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
            )),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ─── WIDGET DE ÉXITO ANIMADO ─────────────────────────────
class _SuccessCheckmark extends StatefulWidget {
  const _SuccessCheckmark();

  @override
  State<_SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<_SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _check;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _check = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: AnimatedBuilder(
            animation: _check,
            builder: (context, child) {
              return CustomPaint(
                painter: _CheckPainter(_check.value),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = ui.Path();
    path.moveTo(size.width * 0.28, size.height * 0.52);
    path.lineTo(size.width * 0.45, size.height * 0.7);
    path.lineTo(size.width * 0.72, size.height * 0.38);

    final pathMetrics = path.computeMetrics();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
