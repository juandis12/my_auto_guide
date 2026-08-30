// =============================================================================
// waze_community_alerts_service.dart — MOTOR DE ALERTAS COMUNITARIAS ESTILO WAZE
// =============================================================================
// Gestiona el reporte, sincronización persistente y confirmación en tiempo real de
// retenes de policía, fotomultas, accidentes y vías dañadas para todos los usuarios.
// =============================================================================

import 'dart:async';
import 'dart:math';
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
      id: json['id']?.toString() ?? 'alert_${DateTime.now().millisecondsSinceEpoch}',
      type: WazeIncidentType.values.firstWhere(
        (e) => e.name == (json['type'] ?? json['tipo']),
        orElse: () => WazeIncidentType.police,
      ),
      title: json['title'] ?? json['titulo'] ?? 'Incidente en Vía',
      description: json['description'] ?? json['descripcion'] ?? '',
      latitude: (json['latitude'] ?? json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] ?? json['longitud'] as num?)?.toDouble() ?? 0.0,
      reporterId: json['reporterId']?.toString() ?? json['user_id']?.toString() ?? '',
      confirmations: (json['confirmations'] ?? json['confirmaciones'] as num?)?.toInt() ?? 1,
      rejections: (json['rejections'] ?? json['rechazos'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null 
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  factory WazeIncidentReport.fromSupabase(Map<String, dynamic> json) {
    final tipoStr = json['tipo'] ?? json['type'];
    return WazeIncidentReport(
      id: json['id']?.toString() ?? 'alert_${DateTime.now().millisecondsSinceEpoch}',
      type: WazeIncidentType.values.firstWhere(
        (e) => e.name == tipoStr,
        orElse: () => WazeIncidentType.police,
      ),
      title: json['titulo'] ?? json['title'] ?? 'Incidente en Vía',
      description: json['descripcion'] ?? json['description'] ?? '',
      latitude: (json['latitud'] ?? json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitud'] ?? json['longitude'] as num?)?.toDouble() ?? 0.0,
      reporterId: json['user_id']?.toString() ?? json['reporterId']?.toString() ?? '',
      confirmations: (json['confirmaciones'] ?? json['confirmations'] as num?)?.toInt() ?? 1,
      rejections: (json['rechazos'] ?? json['rejections'] as num?)?.toInt() ?? 0,
      timestamp: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : (json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now() : DateTime.now()),
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

  /// Inicializa la sincronización de alertas comunitarias con Supabase en tiempo real
  void initRealtimeAlerts() {
    try {
      final supabase = Supabase.instance.client;

      // 1. Cargar todas las alertas activas existentes creadas en las últimas 4 horas
      fetchActiveAlerts();

      // 2. Suscribirse a cambios en tiempo real vía Postgres Changes y Broadcast
      _realtimeChannel = supabase.channel('public:reportes_viales');

      _realtimeChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reportes_viales',
        callback: (payload) {
          final eventType = payload.eventType;
          if (eventType == PostgresChangeEvent.insert || eventType == PostgresChangeEvent.update) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final alert = WazeIncidentReport.fromSupabase(newRecord);
              if (alert.rejections >= 3) {
                _memoryIncidents.removeWhere((e) => e.id == alert.id);
                _incidentsController.add(List.unmodifiable(_memoryIncidents));
              } else {
                _upsertMemoryAlert(alert);
              }
            }
          } else if (eventType == PostgresChangeEvent.delete) {
            final oldRecord = payload.oldRecord;
            final id = oldRecord['id']?.toString();
            if (id != null) {
              _memoryIncidents.removeWhere((e) => e.id == id);
              _incidentsController.add(List.unmodifiable(_memoryIncidents));
            }
          }
        },
      );

      _realtimeChannel!.onBroadcast(
        event: 'new_waze_alert',
        callback: (payload) {
          try {
            final alert = WazeIncidentReport.fromJson(payload);
            _upsertMemoryAlert(alert);
          } catch (e) {
            debugPrint('Error parseando alerta Waze recibida por broadcast: $e');
          }
        },
      );

      _realtimeChannel!.subscribe();
    } catch (e) {
      debugPrint('Aviso: Supabase Realtime no inicializado para alertas Waze: $e');
      if (_memoryIncidents.isEmpty) {
        _seedMockIncidents();
      }
    }
  }

  /// Consulta en la base de datos de Supabase todas las alertas activas de la comunidad
  Future<void> fetchActiveAlerts() async {
    try {
      final supabase = Supabase.instance.client;
      final fourHoursAgo = DateTime.now().toUtc().subtract(const Duration(hours: 4)).toIso8601String();
      
      final data = await supabase
          .from('reportes_viales')
          .select()
          .gte('created_at', fourHoursAgo)
          .lt('rechazos', 3);

      final List<WazeIncidentReport> fetched = [];
      for (final row in data) {
        fetched.add(WazeIncidentReport.fromSupabase(row as Map<String, dynamic>));
      }

      _memoryIncidents.clear();
      _memoryIncidents.addAll(fetched);

      // Si no hay reportes en la base de datos aún, sembrar datos de prueba
      if (_memoryIncidents.isEmpty) {
        _seedMockIncidents();
      } else {
        _incidentsController.add(List.unmodifiable(_memoryIncidents));
      }
    } catch (e) {
      debugPrint('Aviso: Error cargando reportes viales desde Supabase: $e');
      if (_memoryIncidents.isEmpty) {
        _seedMockIncidents();
      }
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
    _incidentsController.add(List.unmodifiable(_memoryIncidents));
  }

  /// Guarda el reporte tanto localmente como en la base de datos global de Supabase
  Future<void> reportIncident({
    required WazeIncidentType type,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    final alertId = 'alert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final alert = WazeIncidentReport(
      id: alertId,
      type: type,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      reporterId: userId,
      confirmations: 1,
      rejections: 0,
      timestamp: DateTime.now().toUtc(),
    );

    _upsertMemoryAlert(alert);

    // 1. Enviar broadcast instantáneo a conductores activos
    if (_realtimeChannel != null) {
      _realtimeChannel!.sendBroadcastMessage(
        event: 'new_waze_alert',
        payload: alert.toJson(),
      );
    }

    // 2. Persistir en la base de datos global para todos los celulares
    try {
      await supabase.from('reportes_viales').insert({
        'id': alert.id,
        'tipo': alert.type.name,
        'titulo': alert.title,
        'descripcion': alert.description,
        'latitud': alert.latitude,
        'longitud': alert.longitude,
        'user_id': supabase.auth.currentUser?.id,
        'confirmaciones': alert.confirmations,
        'rechazos': alert.rejections,
        'created_at': alert.timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error guardando reporte vial en Supabase: $e');
    }
  }

  /// Permite a cualquier conductor confirmar o desmentir un reporte en tiempo real
  Future<void> voteIncident({required String id, required bool isStillThere}) async {
    final idx = _memoryIncidents.indexWhere((element) => element.id == id);
    if (idx != -1) {
      final existing = _memoryIncidents[idx];
      final newConfirmations = isStillThere ? existing.confirmations + 1 : existing.confirmations;
      final newRejections = !isStillThere ? existing.rejections + 1 : existing.rejections;

      // Si las objeciones superan 2, eliminar el reporte de la comunidad
      if (newRejections >= 3) {
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
      _incidentsController.add(List.unmodifiable(_memoryIncidents));

      // Sincronizar voto en la base de datos global
      try {
        final supabase = Supabase.instance.client;
        if (newRejections >= 3) {
          await supabase.from('reportes_viales').delete().eq('id', id);
        } else {
          await supabase.from('reportes_viales').update({
            'confirmaciones': newConfirmations,
            'rechazos': newRejections,
          }).eq('id', id);
        }
      } catch (e) {
        debugPrint('Error actualizando voto de alerta en Supabase: $e');
      }
    }
  }

  void _upsertMemoryAlert(WazeIncidentReport alert) {
    final idx = _memoryIncidents.indexWhere((element) => element.id == alert.id);
    if (idx != -1) {
      _memoryIncidents[idx] = alert;
    } else {
      _memoryIncidents.insert(0, alert);
    }
    _incidentsController.add(List.unmodifiable(_memoryIncidents));
  }

  void dispose() {
    _incidentsController.close();
  }
}
