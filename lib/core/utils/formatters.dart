// =============================================================================
// formatters.dart — FORMATEO DE MONEDA, NÚMEROS Y FECHAS
// =============================================================================
//
// Centraliza los formatos usados en toda la app (pesos colombianos y fechas)
// para no repetir la construcción de `NumberFormat` / `DateFormat` en cada
// pantalla o servicio.
//
// =============================================================================

import 'package:intl/intl.dart';

class AppFormat {
  const AppFormat._();

  static const String locale = 'es_CO';

  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: locale,
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormat = NumberFormat.decimalPattern(locale);

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _shortDateTimeFormat = DateFormat('dd/MM HH:mm');

  /// `1234567` → `$1.234.567`
  static String currency(num amount) => currencyFormat.format(amount);

  /// `1234567` → `1.234.567` (sin símbolo de moneda ni decimales).
  static String thousands(num value) => _decimalFormat.format(value.round());

  /// Igual que [thousands] pero recibe texto: devuelve el valor original si no
  /// es un número entero válido.
  static String thousandsOrRaw(String value) {
    final parsed = int.tryParse(value);
    return parsed == null ? value : thousands(parsed);
  }

  /// `dd/MM/yyyy`
  static String date(DateTime value) => _dateFormat.format(value);

  /// `dd/MM/yyyy HH:mm`
  static String dateTime(DateTime value) => _dateTimeFormat.format(value);

  /// `dd/MM HH:mm`
  static String shortDateTime(DateTime value) =>
      _shortDateTimeFormat.format(value);
}
