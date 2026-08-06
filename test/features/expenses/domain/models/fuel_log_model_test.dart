import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/features/expenses/domain/models/fuel_log_model.dart';

void main() {
  group('FuelLogModel.fromJson', () {
    test('maps a complete row coming from Supabase', () {
      final log = FuelLogModel.fromJson({
        'id': 7,
        'vehiculo_id': 42,
        'fecha': '2024-05-01T10:30:00.000Z',
        'kms_actuales': 15000,
        'monto_cop': 62000.5,
        'galones': 4,
        'precio_por_galon': 15500,
        'es_tanque_lleno': false,
        'notas': 'Tanqueada parcial',
      });

      expect(log.id, '7');
      expect(log.vehiculoId, '42');
      expect(log.fecha, DateTime.parse('2024-05-01T10:30:00.000Z'));
      expect(log.kmsActuales, 15000.0);
      expect(log.montoCop, 62000.5);
      expect(log.galones, 4.0);
      expect(log.precioPorGalon, 15500.0);
      expect(log.esTanqueLleno, false);
      expect(log.notas, 'Tanqueada parcial');
    });

    test('applies safe defaults for missing fields', () {
      final before = DateTime.now();
      final log = FuelLogModel.fromJson(const {});

      expect(log.id, '');
      expect(log.vehiculoId, '');
      expect(log.kmsActuales, 0.0);
      expect(log.montoCop, 0.0);
      expect(log.galones, 0.0);
      expect(log.precioPorGalon, 0.0);
      expect(log.esTanqueLleno, true);
      expect(log.notas, isNull);
      expect(log.fecha.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
    });
  });

  group('FuelLogModel.toJson', () {
    test('round trips through fromJson without losing data', () {
      final original = FuelLogModel(
        id: '1',
        vehiculoId: '2',
        fecha: DateTime.parse('2024-01-15T08:00:00.000Z'),
        kmsActuales: 1200,
        montoCop: 31000,
        galones: 2,
        precioPorGalon: 15500,
        esTanqueLleno: false,
        notas: 'Estación de servicio',
      );

      final restored = FuelLogModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.vehiculoId, original.vehiculoId);
      expect(restored.fecha, original.fecha);
      expect(restored.kmsActuales, original.kmsActuales);
      expect(restored.montoCop, original.montoCop);
      expect(restored.galones, original.galones);
      expect(restored.precioPorGalon, original.precioPorGalon);
      expect(restored.esTanqueLleno, original.esTanqueLleno);
      expect(restored.notas, original.notas);
    });

    test('serializes the date as an ISO 8601 string', () {
      final log = FuelLogModel(
        id: '1',
        vehiculoId: '2',
        fecha: DateTime.utc(2024, 1, 15, 8),
        kmsActuales: 0,
        montoCop: 0,
        galones: 0,
        precioPorGalon: 0,
      );
      expect(log.toJson()['fecha'], '2024-01-15T08:00:00.000Z');
      expect(log.toJson()['es_tanque_lleno'], true);
    });
  });
}
