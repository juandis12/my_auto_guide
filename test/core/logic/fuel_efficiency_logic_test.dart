import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/logic/fuel_efficiency_logic.dart';

void main() {
  group('FuelEfficiencyLogic.calculateEfficiencyScore', () {
    test('returns 100 when the real yield matches the model standard', () {
      // MT 15 => 135 km/gal standard.
      final score = FuelEfficiencyLogic.calculateEfficiencyScore(
        actualKm: 270,
        actualFuelGallons: 2,
        modelName: 'MT 15',
      );
      expect(score, closeTo(100.0, 0.0001));
    });

    test('returns more than 100 when driving better than the standard', () {
      final score = FuelEfficiencyLogic.calculateEfficiencyScore(
        actualKm: 300,
        actualFuelGallons: 2,
        modelName: 'MT 15',
      );
      expect(score, greaterThan(100.0));
    });

    test('returns 0 for non positive distance or fuel', () {
      expect(
        FuelEfficiencyLogic.calculateEfficiencyScore(
          actualKm: 0,
          actualFuelGallons: 2,
          modelName: 'MT 15',
        ),
        0.0,
      );
      expect(
        FuelEfficiencyLogic.calculateEfficiencyScore(
          actualKm: 100,
          actualFuelGallons: 0,
          modelName: 'MT 15',
        ),
        0.0,
      );
      expect(
        FuelEfficiencyLogic.calculateEfficiencyScore(
          actualKm: -50,
          actualFuelGallons: -1,
          modelName: 'MT 15',
        ),
        0.0,
      );
    });

    test('uses the car yield when isCar is true', () {
      final score = FuelEfficiencyLogic.calculateEfficiencyScore(
        actualKm: 90,
        actualFuelGallons: 2,
        modelName: 'Corolla',
        isCar: true,
      );
      expect(score, closeTo(100.0, 0.0001));
    });
  });

  group('FuelEfficiencyLogic.calculateSavings', () {
    test('is positive when less fuel than the standard was used', () {
      final savings = FuelEfficiencyLogic.calculateSavings(
        actualKm: 270,
        actualFuelGallons: 1,
        modelName: 'MT 15',
      );
      expect(savings, closeTo(1 * 15500, 0.0001));
    });

    test('is negative when more fuel than the standard was used', () {
      final savings = FuelEfficiencyLogic.calculateSavings(
        actualKm: 135,
        actualFuelGallons: 2,
        modelName: 'MT 15',
      );
      expect(savings, closeTo(-1 * 15500, 0.0001));
    });

    test('honours a custom fuel price', () {
      final savings = FuelEfficiencyLogic.calculateSavings(
        actualKm: 270,
        actualFuelGallons: 1,
        modelName: 'MT 15',
        pricePerGalon: 20000,
      );
      expect(savings, closeTo(20000, 0.0001));
    });
  });

  group('FuelEfficiencyLogic.getEfficiencyLabel', () {
    test('maps each score bracket to its label', () {
      expect(FuelEfficiencyLogic.getEfficiencyLabel(150), contains('Ultra-Eficiente'));
      expect(FuelEfficiencyLogic.getEfficiencyLabel(110), contains('Ultra-Eficiente'));
      expect(FuelEfficiencyLogic.getEfficiencyLabel(95), contains('Óptima'));
      expect(FuelEfficiencyLogic.getEfficiencyLabel(80), contains('Promedio'));
      expect(FuelEfficiencyLogic.getEfficiencyLabel(79.9), contains('Alto Consumo'));
      expect(FuelEfficiencyLogic.getEfficiencyLabel(0), contains('Alto Consumo'));
    });
  });
}
