import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/features/vehicles/domain/models/maintenance_prediction.dart';

void main() {
  group('MaintenancePrediction.fromMap', () {
    test('maps a prediction produced by VehicleHealthLogic', () {
      final prediction = MaintenancePrediction.fromMap({
        'item': 'Aceite',
        'reason': 'Uso intensivo detectado',
        'risk': 'Medio',
      });

      expect(prediction.item, 'Aceite');
      expect(prediction.reason, 'Uso intensivo detectado');
      expect(prediction.risk, 'Medio');
      expect(prediction.isCritical, false);
    });

    test('applies defaults when the map is incomplete', () {
      final prediction = MaintenancePrediction.fromMap(const {});
      expect(prediction.item, 'Mantenimiento General');
      expect(prediction.reason, '');
      expect(prediction.risk, 'Bajo');
      expect(prediction.isCritical, false);
    });

    test('marks high and critical risks as critical regardless of casing', () {
      expect(MaintenancePrediction.fromMap({'risk': 'Alto'}).isCritical, true);
      expect(MaintenancePrediction.fromMap({'risk': 'alto'}).isCritical, true);
      expect(MaintenancePrediction.fromMap({'risk': 'crítico'}).isCritical, true);
      expect(MaintenancePrediction.fromMap({'risk': 'Bajo'}).isCritical, false);
    });
  });

  group('MaintenancePrediction.fromList', () {
    test('maps every entry of a raw list', () {
      final predictions = MaintenancePrediction.fromList([
        {'item': 'Cadena', 'risk': 'Alto'},
        {'item': 'Filtro', 'risk': 'Bajo'},
      ]);

      expect(predictions.length, 2);
      expect(predictions.first.item, 'Cadena');
      expect(predictions.first.isCritical, true);
      expect(predictions.last.isCritical, false);
    });

    test('returns an empty list for an empty input', () {
      expect(MaintenancePrediction.fromList(const []), isEmpty);
    });
  });
}
