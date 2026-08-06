import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/logic/vehicle_health_logic.dart';

void main() {
  group('VehicleHealthLogic.calculateHealthIndex', () {
    test('returns 100 when every indicator is brand new', () {
      final index = VehicleHealthLogic.calculateHealthIndex(
        pctCadena: 1,
        pctFiltro: 1,
        pctAceite: 1,
        pctSoat: 1,
        pctTecno: 1,
      );
      expect(index, closeTo(100.0, 0.0001));
    });

    test('returns 0 when everything is exhausted', () {
      final index = VehicleHealthLogic.calculateHealthIndex(
        pctCadena: 0,
        pctFiltro: 0,
        pctAceite: 0,
        pctSoat: 0,
        pctTecno: 0,
      );
      expect(index, 0.0);
    });

    test('weights mechanical health at 60% and legal health at 40%', () {
      final onlyMechanical = VehicleHealthLogic.calculateHealthIndex(
        pctCadena: 1,
        pctFiltro: 1,
        pctAceite: 1,
        pctSoat: 0,
        pctTecno: 0,
      );
      final onlyLegal = VehicleHealthLogic.calculateHealthIndex(
        pctCadena: 0,
        pctFiltro: 0,
        pctAceite: 0,
        pctSoat: 1,
        pctTecno: 1,
      );
      expect(onlyMechanical, closeTo(60.0, 0.0001));
      expect(onlyLegal, closeTo(40.0, 0.0001));
    });
  });

  group('VehicleHealthLogic.calculateHybridPercentage', () {
    test('returns 0 when there is no reference date', () {
      final pct = VehicleHealthLogic.calculateHybridPercentage(
        lastDate: null,
        lastKms: 1000,
        cycleDays: 30,
        cycleKms: 1000,
        currentKms: 1200,
      );
      expect(pct, 0.0);
    });

    test('ignores the kilometre factor when no previous kms were recorded', () {
      final pct = VehicleHealthLogic.calculateHybridPercentage(
        lastDate: DateTime.now().subtract(const Duration(days: 15)),
        lastKms: 0,
        cycleDays: 30,
        cycleKms: 1000,
        currentKms: 99999,
      );
      expect(pct, closeTo(0.5, 0.05));
    });

    test('keeps the most worn factor between time and kilometres', () {
      final timeDominant = VehicleHealthLogic.calculateHybridPercentage(
        lastDate: DateTime.now().subtract(const Duration(days: 27)),
        lastKms: 1000,
        cycleDays: 30,
        cycleKms: 1000,
        currentKms: 1100,
      );
      final kmsDominant = VehicleHealthLogic.calculateHybridPercentage(
        lastDate: DateTime.now().subtract(const Duration(days: 3)),
        lastKms: 1000,
        cycleDays: 30,
        cycleKms: 1000,
        currentKms: 1900,
      );
      expect(timeDominant, closeTo(0.1, 0.05));
      expect(kmsDominant, closeTo(0.1, 0.05));
    });

    test('clamps the result between 0 and 1', () {
      final overdue = VehicleHealthLogic.calculateHybridPercentage(
        lastDate: DateTime.now().subtract(const Duration(days: 400)),
        lastKms: 1000,
        cycleDays: 30,
        cycleKms: 1000,
        currentKms: 50000,
      );
      final future = VehicleHealthLogic.calculateHybridPercentage(
        lastDate: DateTime.now().add(const Duration(days: 10)),
        lastKms: 1000,
        cycleDays: 30,
        cycleKms: 1000,
        currentKms: 500,
      );
      expect(overdue, 0.0);
      expect(future, 1.0);
    });
  });

  group('VehicleHealthLogic.getVehicleStatus', () {
    test('maps each health bracket to its label', () {
      expect(VehicleHealthLogic.getVehicleStatus(100), 'Estado de Exhibición');
      expect(VehicleHealthLogic.getVehicleStatus(95), 'Estado de Exhibición');
      expect(VehicleHealthLogic.getVehicleStatus(85), 'Mantenimiento Sobresaliente');
      expect(VehicleHealthLogic.getVehicleStatus(70), 'Operación Óptima');
      expect(VehicleHealthLogic.getVehicleStatus(50), 'Mantenimiento Requerido');
      expect(VehicleHealthLogic.getVehicleStatus(49.9), 'Atención Inmediata');
    });
  });

  group('VehicleHealthLogic.getUserLevel', () {
    test('maps each health bracket to its gamification level', () {
      expect(VehicleHealthLogic.getUserLevel(90)['name'], 'Diamante');
      expect(VehicleHealthLogic.getUserLevel(75)['name'], 'Oro');
      expect(VehicleHealthLogic.getUserLevel(50)['name'], 'Plata');
      expect(VehicleHealthLogic.getUserLevel(49.9)['name'], 'Bronce');
    });

    test('exposes a colour for every level', () {
      for (final index in [95.0, 80.0, 60.0, 10.0]) {
        expect(VehicleHealthLogic.getUserLevel(index)['color'], isA<int>());
      }
    });
  });

  group('VehicleHealthLogic.getWeeklySummary', () {
    test('escalates the tone as health drops', () {
      expect(VehicleHealthLogic.getWeeklySummary(90), startsWith('Resumen Semanal'));
      expect(VehicleHealthLogic.getWeeklySummary(70), startsWith('Resumen Semanal'));
      expect(VehicleHealthLogic.getWeeklySummary(69.9), startsWith('Alerta Semanal'));
    });
  });

  group('VehicleHealthLogic.getQualityCertifications', () {
    test('returns no certification for a neglected vehicle', () {
      final certs = VehicleHealthLogic.getQualityCertifications(
        pctCadena: 0.1,
        pctFiltro: 0.1,
        pctAceite: 0.1,
        pctSoat: 0.1,
        pctTecno: 0.1,
      );
      expect(certs, isEmpty);
    });

    test('awards maintenance based certifications', () {
      final certs = VehicleHealthLogic.getQualityCertifications(
        pctCadena: 0.95,
        pctFiltro: 0.95,
        pctAceite: 0.95,
        pctSoat: 0.95,
        pctTecno: 0.95,
      );
      final ids = certs.map((c) => c['id']).toList();
      expect(ids, containsAll(['oil_certified', 'legal_certified', 'performance_certified']));
    });

    test('awards usage based certifications', () {
      final certs = VehicleHealthLogic.getQualityCertifications(
        pctCadena: 0.1,
        pctFiltro: 0.1,
        pctAceite: 0.1,
        pctSoat: 0.1,
        pctTecno: 0.1,
        routeCount: 10,
        efficiencyScore: 90,
        totalSavings: 50000,
        documentsComplete: true,
        consistency: 'Alta',
        hasLongRoute: true,
      );
      final ids = certs.map((c) => c['id']).toList();
      expect(
        ids,
        containsAll([
          'travel_pro',
          'eco_driver',
          'smart_saver',
          'paperless',
          'visionary_mechanic',
          'marathoner',
        ]),
      );
    });

    test('every certification carries display metadata', () {
      final certs = VehicleHealthLogic.getQualityCertifications(
        pctCadena: 1,
        pctFiltro: 1,
        pctAceite: 1,
        pctSoat: 1,
        pctTecno: 1,
      );
      for (final cert in certs) {
        expect(cert['label'], isA<String>());
        expect(cert['description'], isA<String>());
        expect(cert['icon'], isA<String>());
        expect(cert['color'], isA<String>());
      }
    });
  });

  group('VehicleHealthLogic.predictMaintenance', () {
    test('reports missing data when there is no last maintenance date', () {
      final result = VehicleHealthLogic.predictMaintenance(item: 'Aceite', lastDate: null);
      expect(result['status'], 'Sin datos suficientes');
    });

    test('reports no recent usage when there is no route history', () {
      final result = VehicleHealthLogic.predictMaintenance(
        item: 'Aceite',
        lastDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(result['status'], 'Sin uso reciente');
      expect(result['item'], 'Aceite');
    });

    test('derives the daily average from the last 7 days of routes', () {
      final result = VehicleHealthLogic.predictMaintenance(
        item: 'Cadena',
        lastDate: DateTime.now().subtract(const Duration(days: 5)),
        cycleDays: 60,
        routeHistory: [
          {'fecha': DateTime.now().subtract(const Duration(days: 1)), 'distancia_km': 70},
          {'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(), 'distancia': '105.0'},
          // Older than a week: must be ignored.
          {'fecha': DateTime.now().subtract(const Duration(days: 30)), 'distancia_km': 1000},
          // Unusable rows: must be skipped without throwing.
          {'distancia_km': 500},
        ],
      );
      expect(result['kmPerDay'], closeTo(25.0, 0.0001));
      expect(result['wearFactor'], closeTo(1.0, 0.0001));
      expect(result['days'], 55);
      expect(result['status'], 'Proyectado');
      expect(result['risk'], 'Bajo');
      expect(result['isCritical'], false);
    });

    test('clamps the wear factor between 0.5x and 4x', () {
      final intense = VehicleHealthLogic.predictMaintenance(
        item: 'Aceite',
        lastDate: DateTime.now(),
        avgKmPerDay: 1000,
        cycleDays: 60,
      );
      final light = VehicleHealthLogic.predictMaintenance(
        item: 'Aceite',
        lastDate: DateTime.now(),
        avgKmPerDay: 1,
        cycleDays: 60,
      );
      expect(intense['wearFactor'], 4.0);
      expect(light['wearFactor'], 0.5);
      expect(intense['days'], 15);
      expect(light['days'], 120);
    });

    test('flags an overdue maintenance as critical', () {
      final result = VehicleHealthLogic.predictMaintenance(
        item: 'Aceite',
        lastDate: DateTime.now().subtract(const Duration(days: 90)),
        avgKmPerDay: 25,
        cycleDays: 60,
      );
      expect(result['status'], 'Vencido');
      expect(result['risk'], 'Alto');
      expect(result['isCritical'], true);
      expect(result['reason'], 'Uso intensivo detectado');
      expect((result['date'] as DateTime).isAfter(DateTime.now().subtract(const Duration(minutes: 1))), isTrue);
    });

    test('falls back to a 30 day cycle when none is provided', () {
      final result = VehicleHealthLogic.predictMaintenance(
        item: 'Filtro',
        lastDate: DateTime.now(),
        avgKmPerDay: 25,
      );
      expect(result['days'], 30);
    });
  });

  group('VehicleHealthLogic.getProactiveAdvice', () {
    test('warns about imminent and upcoming maintenance only', () {
      final advice = VehicleHealthLogic.getProactiveAdvice(predictions: [
        {'item': 'Aceite', 'days': 3},
        {'item': 'Cadena', 'days': 15},
        {'item': 'Filtro', 'days': 60},
        {'item': 'SOAT'},
      ]);
      expect(advice.length, 2);
      expect(advice[0], contains('Aceite'));
      expect(advice[0], contains('ALERTA'));
      expect(advice[1], contains('Cadena'));
      expect(advice[1], contains('AVISO'));
    });

    test('returns an empty list when there is nothing to report', () {
      expect(VehicleHealthLogic.getProactiveAdvice(predictions: []), isEmpty);
    });
  });
}
