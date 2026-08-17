// =============================================================================
// waze_community_alerts_service.dart — MOTOR DE ALERTAS COMUNITARIAS ESTILO WAZE
// =============================================================================
// Gestiona el reporte, sincronización y confirmación en tiempo real de
// retenes de policía, fotomultas, accidentes y vías dañadas.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum WazeIncidentType {
  police, // 👮 Retén de Policía / Tránsito
  radar, // 🚨 Cámara / Radar de Fotomulta
  accident, // 🚗 Accidente de Tránsito / Carro Varado
  construction, // 🚧 Obra en la Vía / Tráfico Pesado
  flooding, // 🌧️ Vía Inundada / Mal Estado
}

class WazeIncidentReport {
  final String id;
  final WazeIncidentType type;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String reporterId;
  final int confirmations;
  final int rejections;
  final DateTime timestamp;

  const WazeIncidentReport({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.reporterId,
    required this.confirmations,
    required this.rejections,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'reporterId': reporterId,
    'confirmations': confirmations,
    'rejections': rejections,
    'timestamp': timestamp.toIso8601String(),
  };

  factory WazeIncidentReport.fromJson(Map<String, dynamic> json) {
    return WazeIncidentReport(
      id: json['id'] ?? 'alert_${DateTime.now().millisecondsSinceEpoch}',
      type: WazeIncidentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WazeIncidentType.police,
      ),
      title: json['title'] ?? 'Incidente en Vía',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      reporterId: json['reporterId'] ?? '',
      confirmations: json['confirmations'] ?? 1,
      rejections: json['rejections'] ?? 0,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}

class WazeCommunityAlertsService {
  static final WazeCommunityAlertsService _instance = WazeCommunityAlertsService._internal();
  factory WazeCommunityAlertsService() => _instance;
  WazeCommunityAlertsService._internal();

  final List<WazeIncidentReport> _memoryIncidents = [];
  RealtimeChannel? _realtimeChannel;

  final _incidentsController = StreamController<List<WazeIncidentReport>>.broadcast();
  Stream<List<WazeIncidentReport>> get incidentsStream => _incidentsController.stream;

  List<WazeIncidentReport> get currentIncidents => List.unmodifiable(_memoryIncidents);

  void initRealtimeAlerts() {
    try {
      final supabase = Supabase.instance.client;
      _realtimeChannel = supabase.channel('public:waze_alerts');

      _realtimeChannel!.onBroadcast(
        event: 'new_waze_alert',
        callback: (payload) {
          try {
            final alert = WazeIncidentReport.fromJson(payload);
            _upsertMemoryAlert(alert);
          } catch (e) {
            debugPrint('Error parseando alerta Waze recibida: $e');
          }
        },
      );

      _realtimeChannel!.subscribe();

      // Cargar incidentes base de ejemplo si está vacía la memoria
      if (_memoryIncidents.isEmpty) {
        _seedMockIncidents();
      }
    } catch (e) {
      debugPrint('Aviso: Supabase Realtime no inicializado para alertas Waze: $e');
      _seedMockIncidents();
    }
  }

  void _seedMockIncidents() {
    _memoryIncidents.addAll([
      WazeIncidentReport(
        id: 'waze_demo_1',
        type: WazeIncidentType.police,
        title: '👮 Retén de Policía / Tránsito',
        description: 'Control de documentos en vía',
        latitude: 4.6580,
        longitude: -74.0950,
        reporterId: 'usr_1',
        confirmations: 4,
        rejections: 0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      WazeIncidentReport(
        id: 'waze_demo_2',
        type: WazeIncidentType.accident,
        title: '🚗 Vehículo Varado',
        description: 'Carro detenido en carril derecho',
        latitude: 4.6720,
        longitude: -74.0820,
        reporterId: 'usr_2',
        confirmations: 2,
        rejections: 0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ]);
    _incidentsController.add(_memoryIncidents);
  }

  Future<void> reportIncident({
    required WazeIncidentType type,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    final alert = WazeIncidentReport(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      reporterId: userId,
      confirmations: 1,
      rejections: 0,
      timestamp: DateTime.now(),
    );

    _upsertMemoryAlert(alert);

    if (_realtimeChannel != null) {
      _realtimeChannel!.sendBroadcastMessage(
        event: 'new_waze_alert',
        payload: alert.toJson(),
      );
    }
  }

  void voteIncident({required String id, required bool isStillThere}) {
    final idx = _memoryIncidents.indexWhere((element) => element.id == id);
    if (idx != -1) {
      final existing = _memoryIncidents[idx];
      final newConfirmations = isStillThere ? existing.confirmations + 1 : existing.confirmations;
      final newRejections = !isStillThere ? existing.rejections + 1 : existing.rejections;

      // Si las objeciones superan 2, eliminar el reporte de la comunidad
      if (newRejections >= 2) {
        _memoryIncidents.removeAt(idx);
      } else {
        _memoryIncidents[idx] = WazeIncidentReport(
          id: existing.id,
          type: existing.type,
          title: existing.title,
          description: existing.description,
          latitude: existing.latitude,
          longitude: existing.longitude,
          reporterId: existing.reporterId,
          confirmations: newConfirmations,
          rejections: newRejections,
          timestamp: existing.timestamp,
        );
      }
      _incidentsController.add(_memoryIncidents);
    }
  }

  void _upsertMemoryAlert(WazeIncidentReport alert) {
    final idx = _memoryIncidents.indexWhere((element) => element.id == alert.id);
    if (idx != -1) {
      _memoryIncidents[idx] = alert;
    } else {
      _memoryIncidents.insert(0, alert);
    }
    _incidentsController.add(_memoryIncidents);
  }

  void dispose() {
    _incidentsController.close();
  }
}
