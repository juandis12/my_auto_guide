// =============================================================================
// caravana_realtime_service.dart — TRANSMISIÓN DE RODADAS EN VIVO (SUPABASE REALTIME)
// =============================================================================
// Permite sincronizar la posición GPS, velocidad y señales de SOS entre
// un grupo de motociclistas o automóviles durante un viaje en caravana.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaravanaMember {
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final double speedKmH;
  final bool isSosActive;
  final DateTime lastUpdated;

  const CaravanaMember({
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.speedKmH,
    required this.isSosActive,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'speedKmH': speedKmH,
    'isSosActive': isSosActive,
    'timestamp': lastUpdated.toIso8601String(),
  };

  factory CaravanaMember.fromJson(Map<String, dynamic> json) {
    return CaravanaMember(
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Conductor',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speedKmH: (json['speedKmH'] as num?)?.toDouble() ?? 0.0,
      isSosActive: json['isSosActive'] ?? false,
      lastUpdated: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}

class CaravanaRealtimeService {
  static final CaravanaRealtimeService _instance = CaravanaRealtimeService._internal();
  factory CaravanaRealtimeService() => _instance;
  CaravanaRealtimeService._internal();

  RealtimeChannel? _channel;
  final Map<String, CaravanaMember> _membersMap = {};

  final _membersController = StreamController<List<CaravanaMember>>.broadcast();
  Stream<List<CaravanaMember>> get membersStream => _membersController.stream;

  bool _isJoined = false;
  bool get isJoined => _isJoined;

  Future<void> joinCaravanaRoom({
    required String roomId,
    required String userName,
  }) async {
    if (_isJoined) await leaveCaravanaRoom();

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    _channel = supabase.channel('rodada:$roomId');

    _channel!.onBroadcast(
      event: 'pos_update',
      callback: (payload) {
        try {
          final member = CaravanaMember.fromJson(payload);
          _membersMap[member.userId] = member;
          _membersController.add(_membersMap.values.toList());
        } catch (e) {
          debugPrint('Error procesando miembro de caravana: $e');
        }
      },
    );

    await _channel!.subscribe();
    _isJoined = true;
    debugPrint('✅ Unid@ exitosamente a la Caravana: $roomId');
  }

  void broadcastLocation({
    required String userName,
    required double latitude,
    required double longitude,
    required double speedKmH,
    bool isSos = false,
  }) {
    if (!_isJoined || _channel == null) return;

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? 'my_id';

    final member = CaravanaMember(
      userId: userId,
      name: userName,
      latitude: latitude,
      longitude: longitude,
      speedKmH: speedKmH,
      isSosActive: isSos,
      lastUpdated: DateTime.now(),
    );

    _channel!.sendBroadcastMessage(
      event: 'pos_update',
      payload: member.toJson(),
    );
  }

  Future<void> leaveCaravanaRoom() async {
    if (_channel != null) {
      await Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    _membersMap.clear();
    _isJoined = false;
    _membersController.add([]);
  }

  void dispose() {
    leaveCaravanaRoom();
    _membersController.close();
  }
}
