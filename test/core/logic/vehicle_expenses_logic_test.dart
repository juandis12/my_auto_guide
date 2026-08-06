import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/logic/vehicle_expenses_logic.dart';

void main() {
  const expenses = <Map<String, dynamic>>[
    {'categoria': 'Combustible', 'monto': 50000},
    {'categoria': 'Combustible', 'monto': 25000.5},
    {'categoria': 'Seguro', 'monto': 25000},
  ];

  group('VehicleExpensesLogic.categories', () {
    test('exposes the five expense categories used across the app', () {
      expect(VehicleExpensesLogic.categories.map((c) => c.label), [
        'Combustible',
        'Mantenimiento',
        'Seguro',
        'Impuesto',
        'Otros',
      ]);
    });
  });

  group('VehicleExpensesLogic.formatCurrency', () {
    test('formats amounts as whole peso values with the currency symbol', () {
      final formatted = VehicleExpensesLogic.formatCurrency(1234567.89);
      expect(formatted, contains('\$'));
      expect(formatted, contains('1.234.568'));
      expect(formatted, isNot(contains(',')));
      expect(VehicleExpensesLogic.formatCurrency(0), contains('0'));
    });
  });

  group('VehicleExpensesLogic.calculateTotal', () {
    test('sums every amount regardless of its numeric type', () {
      expect(VehicleExpensesLogic.calculateTotal(expenses), closeTo(100000.5, 0.0001));
    });

    test('returns 0 for an empty list', () {
      expect(VehicleExpensesLogic.calculateTotal(const []), 0.0);
    });
  });

  group('VehicleExpensesLogic.groupByValues', () {
    test('accumulates the amounts per category', () {
      final grouped = VehicleExpensesLogic.groupByValues(expenses);
      expect(grouped.keys, unorderedEquals(['Combustible', 'Seguro']));
      expect(grouped['Combustible'], closeTo(75000.5, 0.0001));
      expect(grouped['Seguro'], closeTo(25000, 0.0001));
    });

    test('returns an empty map for an empty list', () {
      expect(VehicleExpensesLogic.groupByValues(const []), isEmpty);
    });
  });

  group('VehicleExpensesLogic.getDonutSegments', () {
    test('builds one segment per category with a non zero share', () {
      final segments = VehicleExpensesLogic.getDonutSegments({
        'Combustible': 75.0,
        'Seguro': 25.0,
        'Otros': 0.0,
      });
      expect(segments.map((s) => s.label), ['Combustible', 'Seguro']);
      expect(segments.first.percentage, closeTo(0.75, 0.0001));
      expect(segments.first.value, 75.0);
      expect(segments.map((s) => s.percentage).reduce((a, b) => a + b), closeTo(1.0, 0.0001));
    });

    test('returns no segment when the total is zero', () {
      expect(VehicleExpensesLogic.getDonutSegments({'Combustible': 0.0}), isEmpty);
      expect(VehicleExpensesLogic.getDonutSegments(const {}), isEmpty);
    });

    test('ignores categories that are not part of the catalogue', () {
      final segments = VehicleExpensesLogic.getDonutSegments({'Desconocido': 100.0});
      expect(segments, isEmpty);
    });
  });
}
