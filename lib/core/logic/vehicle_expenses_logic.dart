// =============================================================================
// vehicle_expenses_logic.dart — LÓGICA DE NEGOCIO PARA GESTIÓN DE GASTOS
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseCategory {
  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class VehicleExpensesLogic {
  static const List<ExpenseCategory> categories = [
    ExpenseCategory(label: 'Combustible', icon: Icons.local_gas_station_rounded, color: Colors.orange),
    ExpenseCategory(label: 'Mantenimiento', icon: Icons.build_circle_rounded, color: Colors.blue),
    ExpenseCategory(label: 'Seguro', icon: Icons.verified_user_rounded, color: Colors.green),
    ExpenseCategory(label: 'Impuesto', icon: Icons.account_balance_rounded, color: Colors.blueGrey),
    ExpenseCategory(label: 'Otros', icon: Icons.more_horiz_rounded, color: Colors.purple),
  ];

  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static Map<String, double> groupByValues(List<Map<String, dynamic>> expenses) {
    final Map<String, double> totals = {};
    for (var exp in expenses) {
      final cat = exp['categoria'] as String;
      final amount = (exp['monto'] as num).toDouble();
      totals[cat] = (totals[cat] ?? 0.0) + amount;
    }
    return totals;
  }

  static double calculateTotal(List<Map<String, dynamic>> expenses) {
    return expenses.fold(0.0, (sum, item) => sum + (item['monto'] as num).toDouble());
  }

  static List<DonutSegment> getDonutSegments(Map<String, double> groupedTotals) {
    final total = groupedTotals.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return [];

    return categories.map((cat) {
      final value = groupedTotals[cat.label] ?? 0.0;
      return DonutSegment(
        color: cat.color,
        percentage: value / total,
        label: cat.label,
        value: value,
      );
    }).where((s) => s.percentage > 0).toList();
  }
}

class DonutSegment {
  final Color color;
  final double percentage; // 0.0 to 1.0
  final String label;
  final double value;

  DonutSegment({
    required this.color,
    required this.percentage,
    required this.label,
    required this.value,
  });
}
