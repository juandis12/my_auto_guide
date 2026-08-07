import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/logic/vehicle_ai_logic.dart';

void main() {
  group('VehicleAILogic.analyzeJourneyPatterns', () {
    test('returns the neutral analysis when there is no route history', () {
      final result = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: const [],
        modelName: 'MT 15',
      );
      expect(result['intensity'], 'Baja');
      expect(result['consistency'], 'Pendiente');
      expect(result['healthImpact'], 0.0);
      expect(result['careScore'], 100.0);
      expect(result['avgDailyKm'], 0.0);
    });

    test('classifies a steady low usage week', () {
      final result = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: const [
          {'distancia_km': 10},
          {'distancia_km': 10},
          {'distancia_km': 10},
        ],
        modelName: 'MT 15',
      );
      expect(result['intensity'], 'Baja');
      expect(result['consistency'], 'Alta');
      expect(result['avgDailyKm'], closeTo(30 / 7, 0.0001));
      expect(result['healthImpact'], 1.0);
      expect(result['careScore'], 100.0);
      expect(result['advice'], contains('Conducción estable'));
    });

    test('penalizes an intensive but consistent usage week', () {
      final result = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: const [
          {'distancia_km': 200},
          {'distancia_km': 200},
        ],
        modelName: 'MT 15',
      );
      expect(result['intensity'], 'Alta');
      expect(result['healthImpact'], -2.5);
      expect(result['careScore'], 85.0);
      expect(result['advice'], contains('Uso intensivo'));
    });

    test('detects an irregular usage pattern', () {
      final result = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: const [
          {'distancia_km': 1},
          {'distancia_km': 120},
        ],
        modelName: 'MT 15',
      );
      expect(result['consistency'], 'Variable');
      expect(result['advice'], contains('irregular'));
      expect(result['careScore'], lessThan(100.0));
    });

    test('reads distances from the alternative keys and string values', () {
      final result = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: const [
          {'distancia': '35.0'},
          {'distancia_km': null},
          {'otro': 1},
        ],
        modelName: 'MT 15',
      );
      expect(result['avgDailyKm'], closeTo(5.0, 0.0001));
    });

    test('classifies medium intensity between 15 and 50 km per day', () {
      final result = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: const [
          {'distancia_km': 70},
          {'distancia_km': 70},
        ],
        modelName: 'MT 15',
      );
      expect(result['intensity'], 'Media');
    });
  });

  group('VehicleAILogic.calculateSmartSavings', () {
    test('returns the empty result for non positive inputs', () {
      final result = VehicleAILogic.calculateSmartSavings(
        actualKm: 0,
        actualFuelGallons: 0,
        modelName: 'MT 15',
      );
      expect(result['amount'], 0.0);
      expect(result['isNegative'], false);
      expect(result['label'], 'Sin ahorro registrado');
    });

    test('celebrates a relevant saving', () {
      final result = VehicleAILogic.calculateSmartSavings(
        actualKm: 270,
        actualFuelGallons: 1,
        modelName: 'MT 15',
      );
      expect(result['amount'], closeTo(15500, 0.0001));
      expect(result['gallonsSaved'], closeTo(1.0, 0.0001));
      expect(result['isNegative'], false);
      expect(result['label'], contains('ahorrado'));
    });

    test('warns about an elevated consumption', () {
      final result = VehicleAILogic.calculateSmartSavings(
        actualKm: 135,
        actualFuelGallons: 2,
        modelName: 'MT 15',
      );
      expect(result['amount'], closeTo(-15500, 0.0001));
      expect(result['isNegative'], true);
      expect(result['label'], contains('Consumo elevado'));
    });

    test('reports an average consumption inside the neutral band', () {
      final result = VehicleAILogic.calculateSmartSavings(
        actualKm: 270,
        actualFuelGallons: 2.1,
        modelName: 'MT 15',
        localPrice: 15500,
      );
      expect(result['label'], contains('promedio'));
      expect(result['isNegative'], true);
    });

    test('honours the local fuel price', () {
      final result = VehicleAILogic.calculateSmartSavings(
        actualKm: 270,
        actualFuelGallons: 1,
        modelName: 'MT 15',
        localPrice: 20000,
      );
      expect(result['amount'], closeTo(20000, 0.0001));
    });
  });

  group('VehicleAILogic.predictUpcomingIssues', () {
    test('returns no issue for a freshly serviced vehicle', () {
      final issues = VehicleAILogic.predictUpcomingIssues(totalKms: 100, intensity: 'Baja');
      expect(issues, isEmpty);
    });

    test('flags the chain kit near the end of its cycle', () {
      final issues = VehicleAILogic.predictUpcomingIssues(totalKms: 19500, intensity: 'Media');
      final items = issues.map((i) => i['item']).toList();
      expect(items, contains('Kit de Arrastre'));
    });

    test('flags brake pads and spark plugs near the end of their cycle', () {
      final brakes = VehicleAILogic.predictUpcomingIssues(totalKms: 11500, intensity: 'Media');
      final sparks = VehicleAILogic.predictUpcomingIssues(totalKms: 14500, intensity: 'Media');
      expect(brakes.map((i) => i['item']), contains('Pastillas de Freno'));
      expect(sparks.map((i) => i['item']), contains('Bujías / Inyección'));
    });

    test('an intensive usage anticipates the warnings', () {
      const kms = 12500; // 12500 % 20000 = 12500, below the 17000 standard threshold.
      final normal = VehicleAILogic.predictUpcomingIssues(totalKms: kms, intensity: 'Media');
      final intensive = VehicleAILogic.predictUpcomingIssues(totalKms: kms, intensity: 'Alta');
      expect(normal.map((i) => i['item']), isNot(contains('Kit de Arrastre')));
      expect(intensive.map((i) => i['item']), contains('Kit de Arrastre'));
    });

    test('every issue carries the display metadata used by the UI', () {
      final issues = VehicleAILogic.predictUpcomingIssues(totalKms: 19500, intensity: 'Alta');
      expect(issues, isNotEmpty);
      for (final issue in issues) {
        expect(issue['risk'], isA<String>());
        expect(issue['reason'], isA<String>());
        expect(issue['icon'], isA<String>());
        expect(issue['color'], isA<String>());
      }
    });
  });
}
