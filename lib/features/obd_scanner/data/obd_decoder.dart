/// Decodificador de respuestas OBD-II / ELM327 según la norma SAE J1979 / ISO 15031-5
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
    // Dividir por líneas para analizar cada línea independiente
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
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Decodifica los DTC (Códigos de error de diagnóstico, Modo 03 SAE J1979)
  /// Ejemplo de entrada: "43 01 33 00 00" -> ["P0133"]
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
      final modeIndex = compact.indexOf('43');

      if (modeIndex == -1) continue;

      // Cadena de códigos posterior al indicador de Modo "43"
      final codesPayload = compact.substring(modeIndex + 2);

      // Los códigos DTC vienen en grupos de 2 bytes (4 caracteres hexadecimales)
      for (int i = 0; i + 4 <= codesPayload.length; i += 4) {
        final codeHex = codesPayload.substring(i, i + 4);
        if (codeHex == "0000") continue; // Código nulo / padding

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
}
