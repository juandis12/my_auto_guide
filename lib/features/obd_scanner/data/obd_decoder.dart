class ObdDecoder {
  /// Interpreta la respuesta cruda de un escáner ELM327/OBD2
  /// Ejemplo de entrada: "41 0C 1A F8" o "410C1AF8"
  static Map<String, dynamic>? decodeLiveResponse(String rawData) {
    // Limpiar respuesta: quitar espacios, caracteres nulos, etc.
    final cleanData = rawData.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    
    // Si no empieza con 41 (Respuesta al Modo 01), ignorar o tratar diferente
    if (!cleanData.startsWith('41') || cleanData.length < 6) {
      return null;
    }

    final pid = cleanData.substring(2, 4);
    final valueHex = cleanData.substring(4); // El resto son los datos

    switch (pid) {
      case '0C': // RPM
        if (valueHex.length >= 4) {
          final a = int.parse(valueHex.substring(0, 2), radix: 16);
          final b = int.parse(valueHex.substring(2, 4), radix: 16);
          final rpm = ((a * 256) + b) / 4;
          return {'type': 'RPM', 'value': rpm, 'unit': 'rpm'};
        }
        break;
      case '0D': // Velocidad (Speed)
        if (valueHex.length >= 2) {
          final a = int.parse(valueHex.substring(0, 2), radix: 16);
          return {'type': 'Speed', 'value': a, 'unit': 'km/h'};
        }
        break;
      case '05': // Temperatura del refrigerante del motor (Coolant)
        if (valueHex.length >= 2) {
          final a = int.parse(valueHex.substring(0, 2), radix: 16);
          final temp = a - 40;
          return {'type': 'CoolantTemp', 'value': temp, 'unit': '°C'};
        }
        break;
      // Podemos seguir agregando los PIDs estándar de OBD2 aquí.
    }

    return null; // PID no reconocido o no soportado
  }

  /// Decodifica los DTC (Códigos de error, Modo 03)
  /// Ejemplo: "43 01 33 00 00" -> P0133
  static List<String> decodeDtcResponse(String rawData) {
    final cleanData = rawData.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    List<String> dtcs = [];

    // Respuestas al modo 03 empiezan con 43
    if (!cleanData.startsWith('43') || cleanData.length < 6) {
      return dtcs;
    }

    // La cadena puede contener varios códigos, vienen de 2 en 2 bytes (4 hex chars)
    final codesStr = cleanData.substring(2); 
    
    for (int i = 0; i < codesStr.length; i += 4) {
      if (i + 4 <= codesStr.length) {
        final codeHex = codesStr.substring(i, i + 4);
        if (codeHex == "0000") continue; // 0000 significa que no hay más códigos

        final decodedCode = _hexToDtc(codeHex);
        dtcs.add(decodedCode);
      }
    }

    return dtcs;
  }

  static String _hexToDtc(String hexVal) {
    if (hexVal.length != 4) return "UNKNOWN";

    final firstChar = hexVal[0];
    String letter = "P"; // Powertrain por defecto
    String secondChar = "0";

    // Decodificar el primer byte que contiene el sistema (P, C, B, U)
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
    }

    return "$letter$secondChar${hexVal.substring(1)}";
  }
}
