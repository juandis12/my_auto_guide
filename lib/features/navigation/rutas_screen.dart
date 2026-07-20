// =============================================================================
// rutas_screen.dart — NAVEGACIÓN GPS REFACTORIZADA (MODULAR)
// =============================================================================
import 'dart:async';
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
import 'domain/models/navigation_telemetry.dart';
import 'logic/telemetry_calculator.dart';
import 'presentation/controllers/navigation_controller.dart';
import 'presentation/widgets/navigation_widgets.dart';
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

class _RutasScreenState extends State<RutasScreen> with TickerProviderStateMixin {
  final SupabaseClient supabase = SupabaseService().client;
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  late NavigationController _controller;
  bool _isLoadingRoute = false;
  bool _showSuccessOverlay = false;
  String? _vehicleImagePath;
  
  List<NominatimPlace> _searchResults = [];
  bool _isSearching = false;
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
  }

  void _onControllerStateUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateUpdate);
    _idlePositionSubscription?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── LÓGICA DE CARGA ────────────────────────────────────
  
  Future<void> _cargarInfoVehiculo() async {
    try {
      final data = await supabase.from('vehiculos').select('modelo, marca, image_path').eq('id', widget.vehiculoId).single();
      final marca = (data['marca'] as String? ?? '').toUpperCase();
      final modelo = data['modelo'] ?? 'Vehículo';
      final isCar = marca == 'TOYOTA' || marca == 'MAZDA' || marca == 'CHEVROLET';
      
      setState(() {
        _vehicleImagePath = data['image_path'] as String?;
      });
      
      _controller = NavigationController(
        vehicleId: widget.vehiculoId,
        vehicleModel: modelo,
        isCar: isCar,
      );
      _controller.addListener(_onControllerStateUpdate);
    } catch (_) {}
  }

  Future<void> _obtenerUbicacionInicial() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) await Geolocator.requestPermission();
    
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final latLng = LatLng(pos.latitude, pos.longitude);
    _controller.updateCurrentPosition(latLng);
    _mapCtrl.move(latLng, 15);
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

  // ─── ACCIONES DE BÚSQUEDA Y RUTA ────────────────────────
  
  Future<void> _buscarDestino(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      _searchResults = await NavigationService().searchDestination(query);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _seleccionarDestino(NominatimPlace place) {
    _controller.setRouteReady(
      destination: LatLng(place.lat, place.lon),
      destinationName: place.displayName,
      points: [], 
      distanceKm: 0.0,
      durationMin: 0.0,
    );
    _searchCtrl.text = _controller.destinationName;
    _searchResults = [];
    _trazarRuta();
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
      );
      _mapCtrl.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints([curPos, dest]), padding: const EdgeInsets.all(60)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  // ─── CONTROL DE NAVEGACIÓN ──────────────────────────────
  
  void _iniciarNav({bool isFree = false}) async {
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
    
    if (!(await service.isRunning())) {
      await service.startService();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    
    _controller.startNavigation(isFree: isFree);
  }

  Future<void> _finalizarRuta() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    
    final t = _controller.telemetry;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se encontró sesión de usuario activa para guardar el trayecto.')),
        );
      }
      _controller.stopNavigation();
      return;
    }

    final durationSec = t.startTime != null ? DateTime.now().difference(t.startTime!).inSeconds : 0;
    
    debugPrint('Guardando trayecto: Distancia: ${t.distanceKm} km, Duración: $durationSec s');

    final impact = TelemetryCalculator.estimateImpact(
      distanceKm: t.distanceKm, 
      avgSpeedKmH: t.averageSpeedKmH, 
      vehicleModel: _controller.vehicleModel, 
      isCar: _controller.isCar
    );

    if (t.distanceKm > 0.05) {
      try {
        await SyncService().saveRouteOfflineFirst(
          userId: userId,
          vehicleId: widget.vehiculoId,
          originName: 'Ubicación Actual',
          destinationName: _controller.destinationName,
          distanceKm: t.distanceKm,
          durationSeconds: durationSec,
          consumoGalones: impact['gallons']!,
          costoEstimado: impact['cost']!,
          velocidadMax: t.maxSpeedKmH,
          velocidadProm: t.averageSpeedKmH,
          viaPuntos: t.travelledPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        );
        
        await SyncService().updateVehicleKmsOfflineFirst(widget.vehiculoId, t.distanceKm.round());
      } catch (e) {
        debugPrint('Error al guardar trayecto localmente: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el trayecto localmente: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recorrido demasiado corto o sin cambios de ubicación. No se guardó.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    _controller.stopNavigation();
    setState(() => _showSuccessOverlay = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() => _showSuccessOverlay = false);
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
        // Mostrar diálogo de confirmación para salir y finalizar la ruta
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
                  Navigator.pop(ctx, false); // Cierra diálogo
                  await _finalizarRuta();    // Finaliza y guarda
                  if (mounted) Navigator.pop(context); // Sale de la pantalla
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
        body: Stack(
          children: [
            _buildMap(t),
            if (_showSuccessOverlay) const SuccessCheckmark(),
            _buildTopSearch(),
            _buildBottomPanel(t, state),
            if (_isLoadingRoute) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(NavigationTelemetry t) {
    if (t.currentPos == null) return const Center(child: CircularProgressIndicator());
    
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(initialCenter: t.currentPos!, initialZoom: 15),
      children: [
        TileLayer(
          urlTemplate: Theme.of(context).brightness == Brightness.dark
              ? 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png'
              : 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', // Google Maps standard tiles
          userAgentPackageName: 'com.example.my_auto_guide',
        ),
        if (_controller.routePoints.isNotEmpty)
          PolylineLayer(polylines: [
            // Línea externa de neón (sombra de ruta)
            Polyline(
              points: _controller.routePoints,
              strokeWidth: 8,
              color: Colors.blue.withOpacity(0.3),
            ),
            // Línea interna de ruta (núcleo brillante)
            Polyline(
              points: _controller.routePoints,
              strokeWidth: 4,
              color: const Color(0xFF00C6FF),
            ),
          ]),
        if (t.travelledPoints.isNotEmpty)
          PolylineLayer(polylines: [
            // Línea externa de neón para puntos recorridos
            Polyline(
              points: t.travelledPoints,
              strokeWidth: 9,
              color: Colors.green.withOpacity(0.3),
            ),
            // Línea interna brillante para puntos recorridos
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
              width: 45,
              height: 45,
              child: const Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 40,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 3),
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
      ],
    );
  }

  Widget _buildTopSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: 50, left: 16, right: 16,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.65),
                   borderRadius: BorderRadius.circular(20),
                   border: Border.all(
                     color: isDark ? Colors.white10 : Colors.white.withOpacity(0.3),
                     width: 1.5,
                   ),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.05),
                       blurRadius: 10,
                       offset: const Offset(0, 4),
                     )
                   ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: '¿A dónde vas?',
                    hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black54),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.history, color: isDark ? Colors.white70 : Colors.black54), 
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialRutasScreen(vehiculoId: widget.vehiculoId))),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: _buscarDestino,
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 250,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(
                        _searchResults[i].displayName,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.55) : Colors.white.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state == NavigationState.navigating || state == NavigationState.freeTracking) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoChip(
                        icon: Icons.speed,
                        label: '${t.maxSpeedKmH.toStringAsFixed(0)} km/h',
                        color: Colors.blueAccent,
                      ),
                      InfoChip(
                        icon: Icons.straighten,
                        label: '${t.distanceKm.toStringAsFixed(1)} km',
                        color: Colors.greenAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _finalizarRuta,
                    icon: const Icon(Icons.stop),
                    label: const Text('FINALIZAR VIAJE'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.85),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ] else if (state == NavigationState.routeReady) ...[
                  Text(
                    _controller.destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoChip(
                        icon: Icons.straighten,
                        label: '${_controller.routeDistanceKm.toStringAsFixed(1)} km',
                        color: Colors.blueAccent,
                      ),
                      InfoChip(
                        icon: Icons.timer,
                        label: '${_controller.routeDurationMin.round()} min',
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => _iniciarNav(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF035880),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('INICIAR NAVEGACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: () => _iniciarNav(isFree: true),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('RECORRIDO LIBRE', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF035880),
                      minimumSize: const Size(double.infinity, 54),
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
