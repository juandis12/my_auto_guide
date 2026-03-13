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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

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

  // Búsqueda
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Tracking
  StreamSubscription<Position>? _posStream;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _posStream?.cancel();
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
      }
    } catch (_) {
      // silencioso
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

  // ─── INICIAR NAVEGACIÓN ─────────────────────────────────
  void _iniciarNavegacion({bool isFree = false}) {
    setState(() {
      _state = isFree ? _RouteState.freeTracking : _RouteState.navigating;
      _travelledPoints = [_currentPos!];
      _travelledDistanceKm = 0.0;
      if (isFree) {
        _destination = null;
        _destinationName = 'Recorrido Libre';
        _routePoints = [];
      }
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // metros para mayor sensibilidad en modo libre
    );

    _posStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((pos) {
      final newPos = LatLng(pos.latitude, pos.longitude);
      final lastPos = _travelledPoints.last;

      // Calcular distancia recorrida con mayor precisión
      const distance = Distance();
      // Usamos metros directamente para evitar redondeos de la librería a nivel de km
      final segmentMeters = distance.as(LengthUnit.Meter, lastPos, newPos);
      final segmentKm = segmentMeters / 1000.0;

      setState(() {
        _currentPos = newPos;
        _travelledPoints.add(newPos);
        _travelledDistanceKm += segmentKm;
      });

      // Centrar mapa en posición actual
      _mapCtrl.move(newPos, _mapCtrl.camera.zoom);

      // Verificar si llegó al destino (menos de 50 metros)
      if (_destination != null) {
        final distToEnd = distance.as(LengthUnit.Meter, newPos, _destination!);
        if (distToEnd < 50) {
          _completarRuta();
        }
      }
    });
  }

  // ─── COMPLETAR RUTA ─────────────────────────────────────
  Future<void> _completarRuta() async {
    _posStream?.cancel();
    final kmsRecorridos = _travelledDistanceKm;
    // Obtener los kms más actuales de la base de datos antes de sumar
    // para evitar sobrescribir si hubo cambios externos o errores de estado
    int kmsBase = widget.kmsActuales;
    try {
      kmsBase = await SupabaseService().getVehicleMileage(widget.vehiculoId);
    } catch (_) {
      // Si falla, usamos widget.kmsActuales como respaldo
    }

    final nuevoKm = kmsBase + kmsRecorridos.round();

    // Actualizar en Supabase
    try {
      await SupabaseService().updateVehicleKms(widget.vehiculoId, nuevoKm);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando km: $e')),
        );
      }
    }

    if (!mounted) return;
    setState(() => _state = _RouteState.completed);

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
            const Text('¡Ruta completada!'),
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
              label: 'Nuevo kilometraje',
              value: '${nuevoKm.round()} km',
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
    _posStream?.cancel();
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
                      urlTemplate:
                          'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                      userAgentPackageName: 'com.example.my_auto_guide',
                    ),
                    // Ruta trazada
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5,
                            color: Colors.blue.withOpacity(0.6),
                          ),
                        ],
                      ),
                    // Recorrido en navegación
                    if (_travelledPoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _travelledPoints,
                            strokeWidth: 6,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    // Marcadores
                    MarkerLayer(
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
                              border: Border.all(color: Colors.white, width: 3),
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
                          color: Colors.white,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.arrow_back, size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_state == _RouteState.idle ||
                            _state == _RouteState.routeReady)
                          Expanded(
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white,
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Buscar destino...',
                                  prefixIcon: const Icon(Icons.search),
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
                          color: Colors.white,
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
                                style: const TextStyle(fontSize: 13),
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
                  color: Colors.white,
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
                          color: Colors.grey.shade300,
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
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_currentPos != null) {
                    _mapCtrl.move(_currentPos!, 16);
                  }
                },
                child: const Icon(Icons.my_location, color: Colors.blue),
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
        Icon(icon, color: Colors.blueGrey, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
