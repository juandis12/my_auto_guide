import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/navigation_telemetry.dart';
import '../../logic/telemetry_calculator.dart';

enum NavigationState { idle, routeReady, navigating, completed, freeTracking }

/// Controlador de estado para la navegación GPS.
/// Orquestador central entre el GPS, el Servicio de Fondo y la UI.
class NavigationController extends ChangeNotifier {
  final String vehicleId;
  final String vehicleModel;
  final bool isCar;

  NavigationState _state = NavigationState.idle;
  NavigationTelemetry _telemetry = NavigationTelemetry.empty();
  
  LatLng? _destination;
  String _destinationName = '';
  List<LatLng> _routePoints = [];
  double _routeDistanceKm = 0.0;
  double _routeDurationMin = 0.0;

  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;

  NavigationController({
    required this.vehicleId,
    required this.vehicleModel,
    required this.isCar,
  });

  // Getters
  NavigationState get state => _state;
  NavigationTelemetry get telemetry => _telemetry;
  LatLng? get destination => _destination;
  String get destinationName => _destinationName;
  List<LatLng> get routePoints => _routePoints;
  double get routeDistanceKm => _routeDistanceKm;
  double get routeDurationMin => _routeDurationMin;

  // ─── ACCIONES DE NAVEGACIÓN ──────────────────────────────

  void setRouteReady({
    required LatLng destination,
    required String destinationName,
    required List<LatLng> points,
    required double distanceKm,
    required double durationMin,
  }) {
    _destination = destination;
    _destinationName = destinationName;
    _routePoints = points;
    _routeDistanceKm = distanceKm;
    _routeDurationMin = durationMin;
    _state = NavigationState.routeReady;
    notifyListeners();
  }

  void startNavigation({bool isFree = false}) {
    _state = isFree ? NavigationState.freeTracking : NavigationState.navigating;
    _telemetry = NavigationTelemetry(
      startTime: DateTime.now(),
      travelledPoints: _telemetry.currentPos != null ? [_telemetry.currentPos!] : [],
    );
    if (isFree) {
      _destination = null;
      _destinationName = 'Recorrido Libre';
      _routePoints = [];
    }
    _connectToBackgroundService();
    notifyListeners();
  }

  void updateCurrentPosition(LatLng pos, {double? speedMs, double? bgDistanceKm}) {
    final oldPos = _telemetry.currentPos;
    
    // Actualizar puntos recorridos y distancia si estamos navegando
    List<LatLng> pts = _telemetry.travelledPoints;
    double dist = _telemetry.distanceKm;
    double maxSpeed = _telemetry.maxSpeedKmH;
    double avgSpeed = _telemetry.averageSpeedKmH;

    if (_state == NavigationState.navigating || _state == NavigationState.freeTracking) {
      pts = TelemetryCalculator.optimizeRoutePoints(pts, pos);
      
      if (bgDistanceKm != null && bgDistanceKm > dist) {
        dist = bgDistanceKm;
      } else if (oldPos != null) {
        dist += TelemetryCalculator.calculateIncrementalDistance(oldPos, pos);
      }

      if (speedMs != null && speedMs >= 0) {
        final speedKmH = speedMs * 3.6;
        if (speedKmH > maxSpeed) maxSpeed = speedKmH;
      }

      // Calcular velocidad promedio continua
      if (_telemetry.startTime != null && dist > 0.005) {
        final durationSec = DateTime.now().difference(_telemetry.startTime!).inSeconds;
        if (durationSec > 3) {
          avgSpeed = TelemetryCalculator.calculateAverageSpeed(
            distanceKm: dist,
            durationSeconds: durationSec,
            fallbackSpeedKmH: avgSpeed,
          );
        }
      }
    }

    _telemetry = _telemetry.copyWith(
      currentPos: pos,
      travelledPoints: pts,
      distanceKm: dist,
      maxSpeedKmH: maxSpeed,
      averageSpeedKmH: avgSpeed,
    );

    // Auto-completar si llegamos al destino
    if (_state == NavigationState.navigating && _destination != null) {
      final distanceToEnd = Distance().as(LengthUnit.Meter, pos, _destination!);
      if (distanceToEnd < 50) {
        _state = NavigationState.completed;
      }
    }

    notifyListeners();
  }

  void stopNavigation() {
    _serviceSubscription?.cancel();
    _state = NavigationState.completed;
    notifyListeners();
  }

  /// Limpia la ruta activa y resetea a modo libre de espera, manteniendo la posición actual del GPS
  void clearRouteAndReset() {
    _serviceSubscription?.cancel();
    _state = NavigationState.idle;
    final currentPos = _telemetry.currentPos;
    _telemetry = NavigationTelemetry(currentPos: currentPos);
    _destination = null;
    _destinationName = '';
    _routePoints = [];
    _routeDistanceKm = 0.0;
    _routeDurationMin = 0.0;
    notifyListeners();
  }

  void reset() {
    _serviceSubscription?.cancel();
    _state = NavigationState.idle;
    _telemetry = NavigationTelemetry.empty();
    _destination = null;
    _destinationName = '';
    _routePoints = [];
    notifyListeners();
  }

  // ─── COMUNICACIÓN CON BACKGROUND SERVICE ──────────────────

  void _connectToBackgroundService() {
    final service = FlutterBackgroundService();
    _serviceSubscription?.cancel();
    _serviceSubscription = service.on('update').listen((event) {
      final double lat = (event?['lat'] as num?)?.toDouble() ?? 0.0;
      final double lng = (event?['lng'] as num?)?.toDouble() ?? 0.0;
      final double speedMs = (event?['speed'] as num?)?.toDouble() ?? 0.0;
      final double bgDistanceKm = (event?['distance'] as num?)?.toDouble() ?? 0.0;
      
      if (lat != 0.0 && lng != 0.0) {
        updateCurrentPosition(LatLng(lat, lng), speedMs: speedMs, bgDistanceKm: bgDistanceKm);
      }
    });
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }
}
