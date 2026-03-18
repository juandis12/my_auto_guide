// =============================================================================
// rutas_screen.dart — NAVEGACIÓN GPS REFACTORIZADA (MODULAR)
// =============================================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
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
      final data = await supabase.from('vehiculos').select('modelo, marca').eq('id', widget.vehiculoId).single();
      final marca = (data['marca'] as String? ?? '').toUpperCase();
      final modelo = data['modelo'] ?? 'Vehículo';
      final isCar = marca == 'TOYOTA' || marca == 'MAZDA' || marca == 'CHEVROLET';
      
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
    _idlePositionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3),
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
    if (userId == null) return;

    final impact = TelemetryCalculator.estimateImpact(
      distanceKm: t.distanceKm, 
      avgSpeedKmH: t.averageSpeedKmH, 
      vehicleModel: _controller.vehicleModel, 
      isCar: _controller.isCar
    );

    try {
      await SyncService().saveRouteOfflineFirst(
        userId: userId,
        vehicleId: widget.vehiculoId,
        originName: 'Ubicación Actual',
        destinationName: _controller.destinationName,
        distanceKm: t.distanceKm,
        durationSeconds: t.startTime != null ? DateTime.now().difference(t.startTime!).inSeconds : 0,
        consumoGalones: impact['gallons']!,
        costoEstimado: impact['cost']!,
        velocidadMax: t.maxSpeedKmH,
        velocidadProm: t.averageSpeedKmH,
        viaPuntos: t.travelledPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      );
      await SyncService().updateVehicleKmsOfflineFirst(widget.vehiculoId, t.distanceKm.round());
    } catch (_) {}

    _controller.stopNavigation();
    setState(() => _showSuccessOverlay = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() => _showSuccessOverlay = false);

    _mostrarResumen(t.distanceKm, t.maxSpeedKmH, t.averageSpeedKmH, impact['gallons']!, impact['cost']!);
  }

  void _mostrarResumen(double kms, double maxV, double avgV, double gals, double cost) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¡Ruta completada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoRow(icon: Icons.straighten, label: 'Distancia', value: '${kms.toStringAsFixed(1)} km'),
            InfoRow(icon: Icons.speed, label: 'V. Máxima', value: '${maxV.toStringAsFixed(1)} km/h'),
            InfoRow(icon: Icons.av_timer, label: 'V. Promedio', value: '${avgV.toStringAsFixed(1)} km/h'),
            const Divider(),
            InfoRow(icon: Icons.local_gas_station, label: 'Consumo', value: '${gals.toStringAsFixed(2)} gal'),
            InfoRow(icon: Icons.payments, label: 'Costo', value: '\$${cost.toStringAsFixed(0)} COP'),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aceptar')),
        ],
      ),
    );
  }

  // ─── BUILD UI ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _controller.telemetry;
    final state = _controller.state;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(t),
          if (_showSuccessOverlay) const SuccessCheckmark(),
          _buildTopSearch(),
          _buildBottomPanel(t, state),
          if (_isLoadingRoute) const Center(child: CircularProgressIndicator()),
        ],
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
              : 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
        ),
        if (_controller.routePoints.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(points: _controller.routePoints, strokeWidth: 5, color: Colors.blue.withOpacity(0.6)),
          ]),
        if (t.travelledPoints.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(points: t.travelledPoints, strokeWidth: 7, color: Colors.green.withOpacity(0.8)),
          ]),
        MarkerLayer(markers: [
          if (_controller.destination != null)
            Marker(point: _controller.destination!, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
          Marker(point: t.currentPos!, child: const Icon(Icons.navigation, color: Colors.blue, size: 30)),
        ]),
      ],
    );
  }

  Widget _buildTopSearch() {
    return Positioned(
      top: 50, left: 16, right: 16,
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '¿A dónde vas?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.history), 
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialRutasScreen(vehiculoId: widget.vehiculoId))),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: _buscarDestino,
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
              height: 250,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(_searchResults[i].displayName),
                  onTap: () => _seleccionarDestino(_searchResults[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(NavigationTelemetry t, NavigationState state) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == NavigationState.navigating || state == NavigationState.freeTracking) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InfoChip(icon: Icons.speed, label: '${t.maxSpeedKmH.toStringAsFixed(0)} km/h', color: Colors.blue),
                  InfoChip(icon: Icons.straighten, label: '${t.distanceKm.toStringAsFixed(1)} km', color: Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _finalizarRuta,
                icon: const Icon(Icons.stop),
                label: const Text('FINALIZAR'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 50)),
              ),
            ] else if (state == NavigationState.routeReady) ...[
              Text(_controller.destinationName, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InfoChip(icon: Icons.straighten, label: '${_controller.routeDistanceKm.toStringAsFixed(1)} km', color: Colors.blue),
                  InfoChip(icon: Icons.timer, label: '${_controller.routeDurationMin.round()} min', color: Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _iniciarNav(),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('INICIAR NAVEGACIÓN'),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () => _iniciarNav(isFree: true),
                icon: const Icon(Icons.play_arrow),
                label: const Text('MODO LIBRE'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
