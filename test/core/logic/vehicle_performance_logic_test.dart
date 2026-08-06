import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/logic/vehicle_performance_logic.dart';

void main() {
  group('VehiclePerformanceLogic.extractCC', () {
    test('resolves known models with special mappings', () {
      expect(VehiclePerformanceLogic.extractCC('MT 15'), 150);
      expect(VehiclePerformanceLogic.extractCC('R15'), 150);
      expect(VehiclePerformanceLogic.extractCC('XTZ 150'), 150);
      expect(VehiclePerformanceLogic.extractCC('NKD'), 110);
      expect(VehiclePerformanceLogic.extractCC('Crypton'), 110);
      expect(VehiclePerformanceLogic.extractCC('Boxer CT 100'), 100);
      expect(VehiclePerformanceLogic.extractCC('N-Max'), 155);
      expect(VehiclePerformanceLogic.extractCC('FZ 2.0'), 150);
    });

    test('extracts the first 3 or 4 digit number of the model name', () {
      expect(VehiclePerformanceLogic.extractCC('Pulsar NS 200'), 200);
      expect(VehiclePerformanceLogic.extractCC('versys 650'), 650);
      expect(VehiclePerformanceLogic.extractCC('KTM 1390 Super Duke'), 1390);
    });

    test('falls back to 125cc when no number can be extracted', () {
      expect(VehiclePerformanceLogic.extractCC('Dominar'), 125);
      expect(VehiclePerformanceLogic.extractCC(''), 125);
      expect(VehiclePerformanceLogic.extractCC('GS 90'), 125);
    });
  });

  group('VehiclePerformanceLogic.getKmPerGalon', () {
    test('uses a flat average yield for cars', () {
      expect(VehiclePerformanceLogic.getKmPerGalon('Corolla', isCar: true), 45.0);
      expect(VehiclePerformanceLogic.getKmPerGalon('MT 15', isCar: true), 45.0);
    });

    test('maps motorcycle displacement to its yield bracket', () {
      expect(VehiclePerformanceLogic.getKmPerGalon('Boxer CT 100'), 180.0);
      expect(VehiclePerformanceLogic.getKmPerGalon('MT 15'), 135.0);
      expect(VehiclePerformanceLogic.getKmPerGalon('Pulsar NS 200'), 105.0);
      expect(VehiclePerformanceLogic.getKmPerGalon('Duke 390'), 90.0);
      expect(VehiclePerformanceLogic.getKmPerGalon('Versys 650'), 70.0);
      expect(VehiclePerformanceLogic.getKmPerGalon('Super Duke 1390'), 45.0);
    });
  });

  group('VehiclePerformanceLogic.estimateFuelConsumption', () {
    test('penalizes consumption when the vehicle is idle or in heavy traffic', () {
      final idle = VehiclePerformanceLogic.estimateFuelConsumption(100, 'MT 15');
      final traffic = VehiclePerformanceLogic.estimateFuelConsumption(100, 'MT 15', avgSpeedKmH: 10);
      final cruise = VehiclePerformanceLogic.estimateFuelConsumption(100, 'MT 15', avgSpeedKmH: 70);

      expect(idle, closeTo(100 / (135.0 * 0.5), 0.0001));
      expect(traffic, closeTo(100 / (135.0 * 0.6), 0.0001));
      expect(cruise, closeTo(100 / 135.0, 0.0001));
      expect(idle, greaterThan(traffic));
      expect(traffic, greaterThan(cruise));
    });

    test('cruise speed is the most efficient bracket', () {
      final city = VehiclePerformanceLogic.estimateFuelConsumption(100, 'MT 15', avgSpeedKmH: 30);
      final suburban = VehiclePerformanceLogic.estimateFuelConsumption(100, 'MT 15', avgSpeedKmH: 50);
      final cruise = VehiclePerformanceLogic.estimateFuelConsumption(100, 'MT 15', avgSpeedKmH: 85);
      final highway = VehiclePerformanceLogic.estimateFuelConsumption(100, 'MT 15', avgSpeedKmH: 100);
      final overSpeed = VehiclePerformanceLogic.estimateFuelConsumption(100, 'MT 15', avgSpeedKmH: 130);

      expect(cruise, lessThan(suburban));
      expect(suburban, lessThan(city));
      expect(highway, greaterThan(cruise));
      expect(overSpeed, closeTo(100 / (135.0 * 0.75), 0.0001));
    });

    test('returns zero consumption for a zero distance trip', () {
      expect(VehiclePerformanceLogic.estimateFuelConsumption(0, 'MT 15', avgSpeedKmH: 60), 0.0);
    });
  });

  group('VehiclePerformanceLogic.estimateFuelCost', () {
    test('multiplies gallons by the fuel price', () {
      expect(VehiclePerformanceLogic.estimateFuelCost(2), 31000);
      expect(VehiclePerformanceLogic.estimateFuelCost(2, pricePerGalon: 16000), 32000);
      expect(VehiclePerformanceLogic.estimateFuelCost(0), 0);
    });
  });
}
