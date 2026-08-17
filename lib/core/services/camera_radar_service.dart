// =============================================================================
// camera_radar_service.dart — RADAR DE FOTOMULTAS Y CÁMARAS SALVAVIDAS POR GPS
// =============================================================================
// Monitorea automáticamente la proximidad a cámaras de fotomultas registradas
// en Colombia (SIMIT) y notifica al conductor mediante alertas visuales y sonoras.
// =============================================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class SpeedCameraLocation {
  final String id;
  final String city;
  final String locationName;
  final double latitude;
  final double longitude;
  final double speedLimitKmH;

  const SpeedCameraLocation({
    required this.id,
    required this.city,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.speedLimitKmH,
  });
}

class RadarAlertState {
  final bool isNearCamera;
  final SpeedCameraLocation? nearestCamera;
  final double distanceMeters;
  final double currentSpeedKmH;
  final bool isSpeeding;

  const RadarAlertState({
    required this.isNearCamera,
    this.nearestCamera,
    required this.distanceMeters,
    required this.currentSpeedKmH,
    required this.isSpeeding,
  });

  factory RadarAlertState.clear() {
    return const RadarAlertState(
      isNearCamera: false,
      nearestCamera: null,
      distanceMeters: 9999.0,
      currentSpeedKmH: 0.0,
      isSpeeding: false,
    );
  }
}

class CameraRadarService {
  static final CameraRadarService _instance = CameraRadarService._internal();
  factory CameraRadarService() => _instance;
  CameraRadarService._internal();

  StreamSubscription<Position>? _positionSub;
  bool _isActive = false;
  bool get isActive => _isActive;

  final _alertController = StreamController<RadarAlertState>.broadcast();
  Stream<RadarAlertState> get alertStream => _alertController.stream;

  RadarAlertState _currentState = RadarAlertState.clear();
  RadarAlertState get currentState => _currentState;

  // Base de datos representativa de Cámaras Salvavidas / Fotomultas en Colombia
  final List<SpeedCameraLocation> _cameras = const [
    SpeedCameraLocation(id: 'bog_1', city: 'Bogotá', locationName: 'Av. Boyacá con Calle 53', latitude: 4.6644, longitude: -74.1089, speedLimitKmH: 50),
    SpeedCameraLocation(id: 'bog_2', city: 'Bogotá', locationName: 'Autopista Norte con Calle 127', latitude: 4.7088, longitude: -74.0531, speedLimitKmH: 50),
    SpeedCameraLocation(id: 'bog_3', city: 'Bogotá', locationName: 'Av. NQS con Calle 72', latitude: 4.6622, longitude: -74.0788, speedLimitKmH: 50),
    SpeedCameraLocation(id: 'med_1', city: 'Medellín', locationName: 'Av. Las Palmas Km 3', latitude: 6.2201, longitude: -75.5589, speedLimitKmH: 60),
    SpeedCameraLocation(id: 'med_2', city: 'Medellín', locationName: 'Autopista Sur con Calle 10', latitude: 6.2112, longitude: -75.5788, speedLimitKmH: 60),
    SpeedCameraLocation(id: 'cali_1', city: 'Cali', locationName: 'Calle 5 con Carrera 80', latitude: 3.3855, longitude: -76.5411, speedLimitKmH: 50),
    SpeedCameraLocation(id: 'bar_1', city: 'Barranquilla', locationName: 'Vía 40 con Calle 76', latitude: 11.0022, longitude: -74.7955, speedLimitKmH: 50),
  ];

  void startRadar() {
    if (_isActive) return;
    _isActive = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((position) {
      _processPosition(position);
    }, onError: (e) {
      debugPrint('Error en servicio de Radar GPS: $e');
    });
  }

  void stopRadar() {
    _positionSub?.cancel();
    _isActive = false;
    _currentState = RadarAlertState.clear();
    _alertController.add(_currentState);
  }

  void _processPosition(Position pos) {
    final speedKmH = (pos.speed.isFinite && pos.speed >= 0) ? (pos.speed * 3.6) : 0.0;

    // Solo evaluar activamente si la velocidad es mayor a 5 km/h
    if (speedKmH < 5.0 && _cameras.isEmpty) return;

    SpeedCameraLocation? nearest;
    double minDistance = double.infinity;

    for (final cam in _cameras) {
      final dist = _haversineDistance(pos.latitude, pos.longitude, cam.latitude, cam.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = cam;
      }
    }

    final isNear = minDistance <= 350.0; // Alerta dentro de 350 metros
    final isSpeeding = nearest != null && speedKmH > nearest.speedLimitKmH;

    _currentState = RadarAlertState(
      isNearCamera: isNear,
      nearestCamera: isNear ? nearest : null,
      distanceMeters: minDistance.isFinite ? minDistance : 9999.0,
      currentSpeedKmH: double.parse(speedKmH.toStringAsFixed(1)),
      isSpeeding: isSpeeding,
    );

    _alertController.add(_currentState);
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Radio de la Tierra en metros
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  void dispose() {
    stopRadar();
    _alertController.close();
  }
}
