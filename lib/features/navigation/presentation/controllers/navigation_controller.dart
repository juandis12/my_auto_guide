import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../domain/models/navigation_telemetry.dart';
import '../../logic/telemetry_calculator.dart';
import '../../logic/gps_filter_service.dart';
import 'package:my_auto_guide/core/services/navigation_service.dart';
import 'package:my_auto_guide/core/services/voice_navigation_service.dart';

enum NavigationState {
  idle,
  ready,
  routeReady,
  navigating,
  freeTracking,
  completed,
  viewingHistory,
}

/// Controlador de estado para la navegación GPS.
/// Orquestador central entre el GPS, el Servicio de Fondo y la UI.
class NavigationController extends ChangeNotifier {
  final String vehicleId;
  String vehicleModel;
  bool isCar;

  NavigationTelemetry _telemetry = NavigationTelemetry.empty();
  NavigationState _state = NavigationState.idle;
  
  LatLng? _destination;
  String _destinationName = '';
  List<LatLng> _routePoints = [];
  double _routeDistanceKm = 0.0;
  double _routeDurationMin = 0.0;
  List<NavigationStep> _steps = [];
  int _currentStepIndex = 0;

  final GpsFilterService _gpsFilter = GpsFilterService();
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;

  NavigationController({
    required this.vehicleId,
    required this.vehicleModel,
    required this.isCar,
  });

  void updateVehicleInfo({required String model, required bool isCar}) {
    vehicleModel = model;
    this.isCar = isCar;
    notifyListeners();
  }

  // Getters
  NavigationState get state => _state;
  NavigationTelemetry get telemetry => _telemetry;
  LatLng? get destination => _destination;
  String get destinationName => _destinationName;
  List<LatLng> get routePoints => _routePoints;
  double get routeDistanceKm => _routeDistanceKm;
  double get routeDurationMin => _routeDurationMin;
  List<NavigationStep> get steps => _steps;
  int get currentStepIndex => _currentStepIndex;

  NavigationStep? get currentStep {
    if (_steps.isEmpty || _currentStepIndex >= _steps.length) return null;
    return _steps[_currentStepIndex];
  }

  // ─── ACCIONES DE NAVEGACIÓN ──────────────────────────────

  void setRouteReady({
    required LatLng destination,
    required String destinationName,
    required List<LatLng> points,
    required double distanceKm,
    required double durationMin,
    List<NavigationStep> steps = const [],
  }) {
    _destination = destination;
    _destinationName = destinationName;
    _routePoints = points;
    _routeDistanceKm = distanceKm;
    _routeDurationMin = durationMin;
    _steps = steps;
    _currentStepIndex = 0;
    // routeReady: hay una ruta calculada esperando que el usuario presione Iniciar
    _state = NavigationState.routeReady;
    notifyListeners();
  }

  /// Guarda solo el destino en memoria sin cambiar el estado ni la polilínea.
  /// Útil para que _trazarRuta() pueda acceder al destino antes de calcular la ruta.
  void setDestinationOnly({
    required LatLng destination,
    required String destinationName,
  }) {
    _destination = destination;
    _destinationName = destinationName;
    // No cambiamos _state ni _routePoints — eso lo hará setRouteReady cuando lleguen los puntos
    notifyListeners();
  }

  void loadHistoricalRoute({
    required String destinationName,
    required List<LatLng> points,
    required double distanceKm,
    double? maxSpeedKmH,
    double? avgSpeedKmH,
  }) {
    _destination = points.isNotEmpty ? points.last : null;
    _destinationName = destinationName;
    _routePoints = points;
    _routeDistanceKm = distanceKm;
    _routeDurationMin = 0.0;
    _steps = [];
    _currentStepIndex = 0;
    _state = NavigationState.viewingHistory;
    _telemetry = _telemetry.copyWith(
      travelledPoints: points,
      distanceKm: distanceKm,
      maxSpeedKmH: maxSpeedKmH ?? _telemetry.maxSpeedKmH,
      averageSpeedKmH: avgSpeedKmH ?? _telemetry.averageSpeedKmH,
    );
    notifyListeners();
  }

  void startNavigation({bool isFree = false}) {
    _gpsFilter.reset();
    _state = isFree ? NavigationState.freeTracking : NavigationState.navigating;
    _telemetry = NavigationTelemetry(
      startTime: DateTime.now(),
      currentPos: _telemetry.currentPos,
      travelledPoints: _telemetry.currentPos != null ? [_telemetry.currentPos!] : [],
    );
    if (isFree) {
      _destination = null;
      _destinationName = 'Recorrido Libre';
      _routePoints = [];
      _steps = [];
    }
    _currentStepIndex = 0;
    _connectToBackgroundService();

    if (!isFree && _destinationName.isNotEmpty) {
      VoiceNavigationService().speak('Iniciando navegación hacia $_destinationName');
    }
    
    notifyListeners();
  }

  void updateCurrentPosition(
    LatLng pos, {
    double? speedMs, 
    double? bgDistanceKm,
    double? accuracy,
    double? bearing,
    bool? isStationary,
    bool fromBackground = false,
  }) {
    LatLng activePos = pos;
    double currentSpeed = speedMs ?? 0.0;
    double currentBearing = bearing ?? _telemetry.bearing;
    bool stationary = isStationary ?? (speedMs != null && speedMs < 0.8);

    // Si viene directo de GPS satelital en foreground o idle, procesar con GpsFilterService
    if (!fromBackground) {
      final filterResult = _gpsFilter.filterPoint(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: accuracy ?? 10.0,
        speedMs: currentSpeed,
        heading: bearing,
        activeRoutePoints: _state == NavigationState.navigating ? _routePoints : null,
      );

      if (filterResult == null) {
        // Descartar lectura degradada o anómala
        return;
      }

      activePos = filterResult.position;
      currentSpeed = filterResult.speedMs;
      currentBearing = filterResult.bearing;
      stationary = filterResult.isStationary;
    } else if (_state == NavigationState.navigating && _routePoints.length >= 2) {
      // Map-Matching Snap-to-Route para eventos provenientes de background
      final snapResult = GpsFilterService.snapToRoute(pos, _routePoints, maxDistanceMeters: 25.0);
      activePos = snapResult.position;
    }

    final oldPos = _telemetry.currentPos;
    
    // Actualizar puntos recorridos y distancia si estamos navegando
    List<LatLng> pts = _telemetry.travelledPoints;
    double dist = _telemetry.distanceKm;
    double maxSpeed = _telemetry.maxSpeedKmH;
    double avgSpeed = _telemetry.averageSpeedKmH;

    if (_state == NavigationState.navigating || _state == NavigationState.freeTracking) {
      pts = TelemetryCalculator.optimizeRoutePoints(
        pts, 
        activePos,
        isStationary: stationary,
        minDistanceThresholdMeters: 4.0,
      );
      
      if (bgDistanceKm != null && bgDistanceKm > dist) {
        dist = bgDistanceKm;
      } else if (oldPos != null) {
        dist += TelemetryCalculator.calculateIncrementalDistance(
          oldPos, 
          activePos,
          isStationary: stationary,
          speedMs: currentSpeed,
        );
      }

      if (currentSpeed >= 0) {
        final speedKmH = currentSpeed * 3.6;
        if (speedKmH > maxSpeed) maxSpeed = speedKmH;
      }

      // Calcular velocidad promedio continua
      if (_telemetry.startTime != null && dist > 0.005) {
        final durationSec = DateTime.now().difference(_telemetry.startTime!).inSeconds;
        if (durationSec > 3) {
          avgSpeed = TelemetryCalculator.calculateKinematicAverageSpeed(
            distanceKm: dist,
            durationSeconds: durationSec,
            fallbackSpeedKmH: avgSpeed,
          );
        }
      }

      // Actualizar el paso de navegación actual según la proximidad
      // Umbral de 40 m: cubre curvas amplias y latencia de GPS urbano
      if (_steps.isNotEmpty && _currentStepIndex < _steps.length) {
        final stepLoc = _steps[_currentStepIndex].location;
        final distToStep = const Distance().as(LengthUnit.Meter, activePos, stepLoc);
        if (distToStep < 40 && _currentStepIndex < _steps.length - 1) {
          _currentStepIndex++;
        }
      }

      // Emisión de instrucciones por voz TTS
      if (_state == NavigationState.navigating && _steps.isNotEmpty) {
        VoiceNavigationService().processTelemetry(
          currentPos: activePos,
          steps: _steps,
          currentStepIndex: _currentStepIndex,
          destinationName: _destinationName,
        );
      }
    }

    _telemetry = _telemetry.copyWith(
      currentPos: activePos,
      travelledPoints: pts,
      distanceKm: dist,
      maxSpeedKmH: maxSpeed,
      averageSpeedKmH: avgSpeed,
      bearing: currentBearing,
      isStationary: stationary,
    );

    // Auto-completar si llegamos al destino (< 40 metros)
    if (_state == NavigationState.navigating && _destination != null) {
      final distanceToEnd = const Distance().as(LengthUnit.Meter, activePos, _destination!);
      if (distanceToEnd < 40) {
        _state = NavigationState.completed;
      }
    }

    notifyListeners();
  }

  void stopNavigation() {
    _serviceSubscription?.cancel();
    VoiceNavigationService().stop();
    _gpsFilter.reset();
    _state = NavigationState.completed;
    notifyListeners();
  }

  /// Limpia la ruta activa y resetea a modo libre de espera, manteniendo la posición actual del GPS
  void clearRouteAndReset() {
    _serviceSubscription?.cancel();
    _gpsFilter.reset();
    _state = NavigationState.idle;
    final currentPos = _telemetry.currentPos;
    _telemetry = NavigationTelemetry(currentPos: currentPos);
    _destination = null;
    _destinationName = '';
    _routePoints = [];
    _steps = [];
    _currentStepIndex = 0;
    _routeDistanceKm = 0.0;
    _routeDurationMin = 0.0;
    notifyListeners();
  }

  void reset() {
    _serviceSubscription?.cancel();
    _gpsFilter.reset();
    _state = NavigationState.idle;
    _telemetry = NavigationTelemetry.empty();
    _destination = null;
    _destinationName = '';
    _routePoints = [];
    _steps = [];
    _currentStepIndex = 0;
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
      final double bearing = (event?['bearing'] as num?)?.toDouble() ?? 0.0;
      final double accuracy = (event?['accuracy'] as num?)?.toDouble() ?? 10.0;
      final bool isStationary = (event?['isStationary'] as bool?) ?? (speedMs < 0.8);
      
      if (lat != 0.0 && lng != 0.0) {
        updateCurrentPosition(
          LatLng(lat, lng), 
          speedMs: speedMs, 
          bgDistanceKm: bgDistanceKm,
          bearing: bearing,
          accuracy: accuracy,
          isStationary: isStationary,
          fromBackground: true,
        );
      }
    });
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }
}

