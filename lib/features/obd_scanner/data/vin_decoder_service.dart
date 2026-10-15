import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio para decodificar el número de identificación vehicular (VIN - Mode 09 PID 02)
/// y convertirlo en Marca, Modelo, Año y Tipo de Vehículo sin ataduras a ninguna marca específica.
class VinDecoderService {
  static final VinDecoderService _instance = VinDecoderService._internal();
  factory VinDecoderService() => _instance;
  VinDecoderService._internal();

  /// Tabla offline de WMI (World Manufacturer Identifier - Primeros 3 dígitos del VIN)
  static const Map<String, String> _wmiTable = {
    // Nissan
    '1N4': 'Nissan', '1N6': 'Nissan', '3N1': 'Nissan', '3N6': 'Nissan',
    'JN1': 'Nissan', 'JN6': 'Nissan', 'JN8': 'Nissan', 'VSK': 'Nissan',
    'MNB': 'Nissan', '5N1': 'Nissan', 'MDH': 'Nissan',
    // Chevrolet / General Motors
    '1G1': 'Chevrolet', '1GC': 'Chevrolet', '2G1': 'Chevrolet', '3G1': 'Chevrolet',
    'KL1': 'Chevrolet', 'KL4': 'Chevrolet', '8AG': 'Chevrolet', '9BG': 'Chevrolet',
    '1G4': 'Buick', '1G6': 'Cadillac', '1GT': 'GMC',
    // Toyota
    '4T1': 'Toyota', '4T3': 'Toyota', '5TB': 'Toyota', '2T1': 'Toyota',
    'JT2': 'Toyota', 'JTD': 'Toyota', 'JTE': 'Toyota', 'MR0': 'Toyota',
    'SB1': 'Toyota', 'MB1': 'Toyota', '8AJ': 'Toyota',
    // Ford
    '1FA': 'Ford', '1FB': 'Ford', '1FC': 'Ford', '1FD': 'Ford', '1FM': 'Ford',
    '1FT': 'Ford', '2FA': 'Ford', '3FA': 'Ford', 'WF0': 'Ford', '8AF': 'Ford',
    // Honda
    '1HG': 'Honda', '2HG': 'Honda', '3HG': 'Honda', 'JHM': 'Honda',
    'SHH': 'Honda', 'MRH': 'Honda', '93H': 'Honda',
    // Mazda
    '1YV': 'Mazda', 'JM1': 'Mazda', 'JMZ': 'Mazda', '3MZ': 'Mazda', 'MM8': 'Mazda',
    // Hyundai & Kia
    'KM8': 'Hyundai', 'KMH': 'Hyundai', 'MAL': 'Hyundai', '5NP': 'Hyundai',
    'KNA': 'Kia', 'KND': 'Kia', 'KNE': 'Kia', '5XX': 'Kia',
    // Volkswagen / Audi
    'WVW': 'Volkswagen', 'WVG': 'Volkswagen', '1VW': 'Volkswagen', '3VW': 'Volkswagen',
    '8AW': 'Volkswagen', '9BW': 'Volkswagen',
    'WAU': 'Audi', 'WA1': 'Audi', 'TRU': 'Audi',
    // BMW
    'WBA': 'BMW', 'WBS': 'BMW', 'WBY': 'BMW', '5UX': 'BMW', 'WBX': 'BMW',
    // Mercedes-Benz
    'WDB': 'Mercedes-Benz', 'WDD': 'Mercedes-Benz', 'WDF': 'Mercedes-Benz',
    '4JG': 'Mercedes-Benz', 'WDZ': 'Mercedes-Benz',
    // Renault
    'VF1': 'Renault', '93Y': 'Renault', '8A1': 'Renault',
    // Peugeot & Citroën
    'VF3': 'Peugeot', 'VF7': 'Citroën',
    // Fiat & Alfa Romeo
    'ZFA': 'Fiat', '9BD': 'Fiat', '3F3': 'Fiat', 'ZAR': 'Alfa Romeo',
    // Suzuki
    'MA3': 'Suzuki', 'TSM': 'Suzuki', 'JSA': 'Suzuki', 'JS2': 'Suzuki',
    // Mitsubishi
    'JA3': 'Mitsubishi', 'JA4': 'Mitsubishi', 'MMB': 'Mitsubishi', '4A3': 'Mitsubishi',
    // Subaru
    'JF1': 'Subaru', 'JF2': 'Subaru', '4S3': 'Subaru',
    // Jeep / Dodge / RAM / Chrysler
    '1C4': 'Jeep', '1J4': 'Jeep', '1C3': 'Chrysler', '2C3': 'Chrysler',
    '3D3': 'RAM', '3C6': 'RAM', '1B3': 'Dodge', '2B3': 'Dodge',
    // Volvo
    'YV1': 'Volvo', 'YV4': 'Volvo',
    // Land Rover
    'SAL': 'Land Rover', 'SAJ': 'Jaguar',
  };

  /// Decodifica el año del modelo a partir del 10º carácter del VIN (Estándar ISO 3779)
  static int? decodeModelYear(String vin) {
    if (vin.length < 10) return null;
    final code = vin[9].toUpperCase();

    const yearMap = {
      '1': 2001, '2': 2002, '3': 2003, '4': 2004, '5': 2005,
      '6': 2006, '7': 2007, '8': 2008, '9': 2009, 'A': 2010,
      'B': 2011, 'C': 2012, 'D': 2013, 'E': 2014, 'F': 2015,
      'G': 2016, 'H': 2017, 'J': 2018, 'K': 2019, 'L': 2020,
      'M': 2021, 'N': 2022, 'P': 2023, 'R': 2024, 'S': 2025,
      'T': 2026, 'V': 2027, 'W': 2028, 'X': 2029, 'Y': 2030,
    };

    return yearMap[code];
  }

  /// Limpia y decodifica la respuesta cruda del comando OBD2 `0902` (Modo 09 PID 02)
  /// Retorna el VIN de 17 caracteres si es válido, o `null`.
  static String? extractVinFromRawResponse(String rawResponse) {
    if (rawResponse.isEmpty) return null;

    final upper = rawResponse.toUpperCase();
    if (upper.contains("NO DATA") || upper.contains("ERROR") || upper.contains("UNABLE")) {
      return null;
    }

    // Dividir por líneas
    final lines = upper
        .replaceAll('>', '')
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    final StringBuffer hexBuffer = StringBuffer();

    for (final line in lines) {
      // Remover prefijos CAN como "0: ", "1: ", "2: " o cabeceras "7E8 10 14 "
      var clean = line;
      clean = clean.replaceAll(RegExp(r'^[0-9A-F]{3}\s+[0-9A-F]{2}\s+'), ''); // CAN Header
      clean = clean.replaceAll(RegExp(r'^[0-9]:\s*'), ''); // ISO-TP frame line numbers (0:, 1:, 2:)
      clean = clean.replaceAll(RegExp(r'\s+'), ''); // Quitar espacios

      // Las respuestas de Modo 09 PID 02 comienzan con "4902"
      // Seguido a menudo por el número de ítem "01", "02", etc.
      final idx = clean.indexOf('4902');
      if (idx != -1) {
        // Cortar hasta después de 4902 y el byte de secuencia (ej: 490201 -> payload posterior)
        final after = clean.substring(idx + 4);
        if (after.length >= 2) {
          // El primer byte suele ser el número de datos/secuencia (01, 02)
          final data = after.substring(2);
          hexBuffer.write(data);
        }
      } else if (RegExp(r'^[0-9A-F]{8,}$').hasMatch(clean)) {
        // Línea subsecuente de datos hexadecimales sin etiqueta 4902
        hexBuffer.write(clean);
      }
    }

    final fullHex = hexBuffer.toString();
    if (fullHex.isEmpty) return null;

    // Convertir pares hexadecimales a caracteres ASCII legibles
    final StringBuffer asciiBuffer = StringBuffer();
    for (int i = 0; i + 2 <= fullHex.length; i += 2) {
      try {
        final byteVal = int.parse(fullHex.substring(i, i + 2), radix: 16);
        // Filtrar caracteres ASCII imprimibles habituales en VIN (A-Z, 0-9)
        if ((byteVal >= 48 && byteVal <= 57) || // 0-9
            (byteVal >= 65 && byteVal <= 90)) { // A-Z (excluyendo I, O, Q por norma VIN)
          asciiBuffer.write(String.fromCharCode(byteVal));
        }
      } catch (_) {}
    }

    final candidate = asciiBuffer.toString();
    // Buscar cualquier subsecuencia de 17 caracteres válidos de VIN
    final vinRegex = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
    final match = vinRegex.firstMatch(candidate);
    if (match != null) {
      return match.group(0);
    }

    // Si tiene exactamente 17 caracteres
    if (candidate.length == 17) {
      return candidate;
    }

    return null;
  }

  /// Identifica la información del vehículo a partir del VIN
  /// 1. Consulta offline WMI y año de modelo.
  /// 2. Si hay conexión a internet, complementa mediante la API pública de NHTSA vPIC.
  Future<VehicleIdentity> identifyVehicle(String vin) async {
    final cleanVin = vin.trim().toUpperCase();
    String make = 'Vehículo Universal';
    String model = '';
    int? year = decodeModelYear(cleanVin);

    // 1. Identificación offline rápida mediante WMI (3 caracteres)
    if (cleanVin.length >= 3) {
      final wmi = cleanVin.substring(0, 3);
      if (_wmiTable.containsKey(wmi)) {
        make = _wmiTable[wmi]!;
      } else {
        // Intentar con los dos primeros caracteres
        final wmi2 = cleanVin.substring(0, 2);
        for (final entry in _wmiTable.entries) {
          if (entry.key.startsWith(wmi2)) {
            make = entry.value;
            break;
          }
        }
      }
    }

    // 2. Consulta online a la API libre de NHTSA vPIC (con timeout de 2.5 seg)
    try {
      final url = Uri.parse('https://vpic.nhtsa.dot.gov/api/vehicles/decodevinvalues/$cleanVin?format=json');
      final response = await http.get(url).timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'] as List?;
        if (results != null && results.isNotEmpty) {
          final info = results[0] as Map<String, dynamic>;
          final apiMake = info['Make']?.toString().trim();
          final apiModel = info['Model']?.toString().trim();
          final apiYear = int.tryParse(info['ModelYear']?.toString() ?? '');

          if (apiMake != null && apiMake.isNotEmpty) {
            make = _formatBrandName(apiMake);
          }
          if (apiModel != null && apiModel.isNotEmpty) {
            model = apiModel;
          }
          if (apiYear != null && apiYear > 1980) {
            year = apiYear;
          }
        }
      }
    } catch (e) {
      debugPrint("[VIN_DECODER] Fallback offline (sin internet o timeout NHTSA): $e");
    }

    return VehicleIdentity(
      vin: cleanVin,
      make: make,
      model: model,
      year: year,
    );
  }

  String _formatBrandName(String raw) {
    if (raw.isEmpty) return raw;
    final lower = raw.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}

/// Representa la identidad confirmada del vehículo
class VehicleIdentity {
  final String vin;
  final String make;
  final String model;
  final int? year;

  VehicleIdentity({
    required this.vin,
    required this.make,
    this.model = '',
    this.year,
  });

  /// Nombre comercial representativo (ej: "Nissan Navara (2012)" o "Chevrolet Spark")
  String get displayName {
    final buffer = StringBuffer(make);
    if (model.isNotEmpty) {
      buffer.write(' $model');
    }
    if (year != null) {
      buffer.write(' ($year)');
    }
    return buffer.toString().trim();
  }

  @override
  String toString() => displayName;
}
