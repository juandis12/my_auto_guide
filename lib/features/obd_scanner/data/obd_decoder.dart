/// Decodificador universal de respuestas OBD-II / ELM327 según la norma SAE J1979 / ISO 15031-5
class ObdDecoder {
  /// Interpreta la respuesta cruda de un escáner ELM327/OBD2 para el Modo 01 (Live Data).
  /// Soporta respuestas con eco ("010C\r41 0C 1A F8"), sin espacios ("410C1AF8"),
  /// mensajes de búsqueda ("SEARCHING...\r\n41 0C 1A F8\r>") y cabeceras CAN ("7E8 04 41 0C 1A F8").
  static Map<String, dynamic>? decodeLiveResponse(String rawData) {
    if (rawData.isEmpty) return null;

    final upper = rawData.toUpperCase();

    // Comprobar mensajes de error de bus o conexión del ELM327
    if (upper.contains("NO DATA") ||
        upper.contains("UNABLE TO CONNECT") ||
        upper.contains("BUS INIT") ||
        upper.contains("CAN ERROR") ||
        upper.contains("STOPPED")) {
      return null;
    }

    // Limpiar caracteres de control, saltos de línea y prompts
    final lines = upper
        .replaceAll('>', '')
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    for (final line in lines) {
      // Quitar cabeceras CAN comunes si existen (Ej: "7E8 04 41 0C 1A F8" -> "41 0C 1A F8")
      var cleanLine = line;
      if (RegExp(r'^[0-9A-F]{3}\s+[0-9A-F]{2}\s+').hasMatch(cleanLine)) {
        cleanLine = cleanLine.replaceFirst(RegExp(r'^[0-9A-F]{3}\s+[0-9A-F]{2}\s+'), '');
      }

      // Compactar quitando todos los espacios
      final compact = cleanLine.replaceAll(RegExp(r'\s+'), '');

      // Buscar el patrón de respuesta de Modo 01: "41" seguido de 2 hex para el PID
      final modeIndex = compact.indexOf('41');
      if (modeIndex == -1 || compact.length < modeIndex + 4) {
        continue;
      }

      final payload = compact.substring(modeIndex);
      if (payload.length < 4) continue;

      final pid = payload.substring(2, 4);
      final dataHex = payload.substring(4);

      final metric = _parsePid(pid, dataHex);
      if (metric != null) {
        return metric;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _parsePid(String pid, String dataHex) {
    try {
      switch (pid) {
        case '0C': // RPM del motor (Engine RPM)
          if (dataHex.length >= 4) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            final b = int.parse(dataHex.substring(2, 4), radix: 16);
            final rpm = ((a * 256) + b) / 4.0;
            return {
              'type': 'RPM',
              'value': rpm.round(),
              'unit': 'rpm',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '0D': // Velocidad del vehículo (Vehicle Speed)
          if (dataHex.length >= 2) {
            final speed = int.parse(dataHex.substring(0, 2), radix: 16);
            return {
              'type': 'Speed',
              'value': speed,
              'unit': 'km/h',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '05': // Temperatura del refrigerante de motor (Engine Coolant Temp)
          if (dataHex.length >= 2) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            final temp = a - 40;
            return {
              'type': 'CoolantTemp',
              'value': temp,
              'unit': '°C',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '04': // Carga calculada del motor (Calculated Engine Load)
          if (dataHex.length >= 2) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            final load = (a * 100.0) / 255.0;
            return {
              'type': 'EngineLoad',
              'value': load.round(),
              'unit': '%',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '0F': // Temperatura de aire de admisión (Intake Air Temp)
          if (dataHex.length >= 2) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            final temp = a - 40;
            return {
              'type': 'IntakeTemp',
              'value': temp,
              'unit': '°C',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '11': // Posición del acelerador (Throttle Position)
          if (dataHex.length >= 2) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            final throttle = (a * 100.0) / 255.0;
            return {
              'type': 'Throttle',
              'value': throttle.round(),
              'unit': '%',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '2F': // Nivel de combustible (Fuel Tank Level)
          if (dataHex.length >= 2) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            final level = (a * 100.0) / 255.0;
            return {
              'type': 'FuelLevel',
              'value': level.round(),
              'unit': '%',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '10': // Flujo de aire de admisión MAF (Mass Air Flow Rate)
          if (dataHex.length >= 4) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            final b = int.parse(dataHex.substring(2, 4), radix: 16);
            final maf = ((a * 256.0) + b) / 100.0;
            return {
              'type': 'MAF',
              'value': double.parse(maf.toStringAsFixed(1)),
              'unit': 'g/s',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '0A': // Presión del riel de combustible (Fuel Pressure)
          if (dataHex.length >= 2) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            return {
              'type': 'FuelPressure',
              'value': a * 3,
              'unit': 'kPa',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;

        case '1F': // Tiempo de funcionamiento desde encendido (Engine Run Time)
          if (dataHex.length >= 4) {
            final a = int.parse(dataHex.substring(0, 2), radix: 16);
            final b = int.parse(dataHex.substring(2, 4), radix: 16);
            return {
              'type': 'RunTime',
              'value': (a * 256) + b,
              'unit': 's',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
          break;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Decodifica el voltaje de la batería obtenido del comando del adaptador ELM327 `ATRV`
  /// Ejemplo de entrada: "12.6V" o "14.2V"
  static double? decodeVoltageResponse(String rawData) {
    if (rawData.isEmpty) return null;
    final match = RegExp(r'([0-9]{1,2}\.[0-9])').firstMatch(rawData);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Decodifica los PIDs soportados por la ECU del vehículo (PID 00, 20, 40)
  /// Retorna un conjunto con los PIDs hexadecimales admitidos por este vehículo.
  static Set<String> decodeSupportedPids(String rawData) {
    final supported = <String>{};
    if (rawData.isEmpty) return supported;

    final upper = rawData.toUpperCase().replaceAll('>', '').replaceAll(RegExp(r'\s+'), '');
    final idx = upper.indexOf('4100');
    if (idx == -1 || upper.length < idx + 12) return supported;

    final hexPayload = upper.substring(idx + 4, idx + 12);
    try {
      final bitmask = int.parse(hexPayload, radix: 16);
      for (int i = 0; i < 32; i++) {
        final isSupported = ((bitmask >> (31 - i)) & 1) == 1;
        if (isSupported) {
          final pidNumber = i + 1;
          final hexPid = pidNumber.toRadixString(16).padLeft(2, '0').toUpperCase();
          supported.add(hexPid);
        }
      }
    } catch (_) {}

    return supported;
  }

  /// Decodifica los DTC (Códigos de error de diagnóstico)
  /// Soporta Modo 03 (Confirmados: "43..."), Modo 07 (Pendientes: "47...") y Modo 0A (Permanentes: "4A...")
  static List<String> decodeDtcResponse(String rawData) {
    if (rawData.isEmpty) return [];

    final upper = rawData.toUpperCase();
    if (upper.contains("NO DATA") || upper.contains("NO CODES") || upper.contains("UNABLE")) {
      return [];
    }

    final dtcs = <String>{};

    final lines = upper
        .replaceAll('>', '')
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    for (final line in lines) {
      // Limpiar cabecera CAN si existe
      var cleanLine = line;
      if (RegExp(r'^[0-9A-F]{3}\s+[0-9A-F]{2}\s+').hasMatch(cleanLine)) {
        cleanLine = cleanLine.replaceFirst(RegExp(r'^[0-9A-F]{3}\s+[0-9A-F]{2}\s+'), '');
      }

      final compact = cleanLine.replaceAll(RegExp(r'\s+'), '');

      // Buscar indicador de Modo: 43 (Modo 03), 47 (Modo 07), 4A (Modo 0A)
      int modeIndex = compact.indexOf('43');
      if (modeIndex == -1) {
        modeIndex = compact.indexOf('47');
      }
      if (modeIndex == -1) {
        modeIndex = compact.indexOf('4A');
      }

      if (modeIndex == -1) continue;

      final codesPayload = compact.substring(modeIndex + 2);

      // Los códigos DTC vienen en grupos de 2 bytes (4 caracteres hexadecimales)
      for (int i = 0; i + 4 <= codesPayload.length; i += 4) {
        final codeHex = codesPayload.substring(i, i + 4);
        if (codeHex == "0000") continue; // Padding nulo

        final decoded = _hexToDtc(codeHex);
        if (decoded.isNotEmpty && decoded != "UNKNOWN") {
          dtcs.add(decoded);
        }
      }
    }

    return dtcs.toList();
  }

  /// Convierte 4 dígitos hexadecimales en el código estándar SAE OBD-II (P, C, B, U)
  static String _hexToDtc(String hexVal) {
    if (hexVal.length != 4) return "UNKNOWN";

    final firstChar = hexVal[0];
    String letter = "P";
    String secondChar = "0";

    switch (firstChar) {
      case '0': letter = 'P'; secondChar = '0'; break;
      case '1': letter = 'P'; secondChar = '1'; break;
      case '2': letter = 'P'; secondChar = '2'; break;
      case '3': letter = 'P'; secondChar = '3'; break;
      case '4': letter = 'C'; secondChar = '0'; break;
      case '5': letter = 'C'; secondChar = '1'; break;
      case '6': letter = 'C'; secondChar = '2'; break;
      case '7': letter = 'C'; secondChar = '3'; break;
      case '8': letter = 'B'; secondChar = '0'; break;
      case '9': letter = 'B'; secondChar = '1'; break;
      case 'A': letter = 'B'; secondChar = '2'; break;
      case 'B': letter = 'B'; secondChar = '3'; break;
      case 'C': letter = 'U'; secondChar = '0'; break;
      case 'D': letter = 'U'; secondChar = '1'; break;
      case 'E': letter = 'U'; secondChar = '2'; break;
      case 'F': letter = 'U'; secondChar = '3'; break;
      default: return "UNKNOWN";
    }

    return "$letter$secondChar${hexVal.substring(1)}";
  }

  /// Determina si la ECU respondió satisfactoriamente a una consulta de diagnóstico
  static bool isEcuResponding(String rawData) {
    if (rawData.isEmpty) return false;
    final upper = rawData.toUpperCase();
    if (upper.contains("NO DATA") ||
        upper.contains("UNABLE TO CONNECT") ||
        upper.contains("BUS INIT: ... ERROR") ||
        upper.contains("CAN ERROR") ||
        upper.contains("STOPPED") ||
        upper.contains("FB ERROR") ||
        upper.contains("ERROR")) {
      return false;
    }
    // Debe contener '41' (Modo 01) o '49' (Modo 09) o '43' (Modo 03) o '47' (Modo 07)
    return upper.contains("41") || upper.contains("49") || upper.contains("43") || upper.contains("47");
  }

  /// Limpia y formatea la descripción de protocolo devuelta por ATDP / ATDPN
  static String cleanProtocolName(String rawData) {
    if (rawData.isEmpty) return "OBD-II Estándar";
    var clean = rawData
        .replaceAll('>', '')
        .replaceAll('SEARCHING...', '')
        .replaceAll('AUTO,', '')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .trim();

    if (clean.isEmpty || clean == "?" || clean.toUpperCase().contains("ERROR") || clean.toUpperCase().contains("NO DATA")) {
      return "OBD-II Universal";
    }

    if (clean.length > 32) {
      clean = clean.substring(0, 32);
    }
    return clean;
  }
}
