import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Procesa una imagen y busca una fecha de vencimiento.
  /// Retorna un DateTime si se encuentra una fecha válida, de lo contrario null.
  Future<DateTime?> extractExpirationDate(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      
      // 1. Limpiar el texto de caracteres comunes mal interpretados por OCR
      // Ejemplo: 'I' -> '1', 'O' -> '0' en contextos numéricos, pero preferimos regex flexible.
      
      // 2. Regex para fechas comunes en Colombia: DD/MM/AAAA o DD-MM-AAAA
      // También buscamos AAAA/MM/DD
      final RegExp dateRegExp = RegExp(
        r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})|(\d{4})[/-](\d{1,2})[/-](\d{1,2})',
        caseSensitive: false,
      );

      final matches = dateRegExp.allMatches(fullText);
      
      if (matches.isEmpty) return null;

      // 3. Filtrar fechas. Normalmente la fecha de vencimiento es la mayor en el documento 
      // (comparada con fecha de expedición o nacimiento si las hay).
      List<DateTime> foundDates = [];
      for (var match in matches) {
        String? dateStr = match.group(0);
        if (dateStr == null) continue;

        DateTime? parsed = _parseFlexibleDate(dateStr);
        if (parsed != null) {
          // Filtrar fechas absurdas (menores a 2020 o mayores a 2040)
          if (parsed.year >= 2020 && parsed.year <= 2040) {
            foundDates.add(parsed);
          }
        }
      }

      if (foundDates.isEmpty) return null;

      // 4. Retornar la fecha más lejana (típicamente el vencimiento)
      foundDates.sort((a, b) => b.compareTo(a));
      return foundDates.first;

    } catch (e) {
      print('Error en OCRService: $e');
      return null;
    }
  }

  DateTime? _parseFlexibleDate(String dateStr) {
    // Reemplazar separadores por guiones
    dateStr = dateStr.replaceAll('/', '-');
    final parts = dateStr.split('-');
    
    try {
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          // AAAA-MM-DD
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          // DD-MM-AAAA
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
