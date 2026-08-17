// =============================================================================
// ocr_invoice_service.dart — MOTOR HÍBRIDO DE ESCÁNER DE FACTURAS Y GASOLINA
// =============================================================================
// Combina Google ML Kit (On-Device, instantáneo) y Gemini Vision API (Nube)
// para extraer montos, galones, repuestos y fechas de tiquetes físicos.
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExtractedInvoiceData {
  final double totalAmount;
  final double gallons;
  final String date;
  final String vendorName;
  final List<String> items;
  final String sourceEngine; // 'ML_Kit_Local' o 'Gemini_Vision_Cloud'

  const ExtractedInvoiceData({
    required this.totalAmount,
    required this.gallons,
    required this.date,
    required this.vendorName,
    required this.items,
    required this.sourceEngine,
  });

  factory ExtractedInvoiceData.empty() {
    return const ExtractedInvoiceData(
      totalAmount: 0.0,
      gallons: 0.0,
      date: '',
      vendorName: 'Desconocido',
      items: [],
      sourceEngine: 'None',
    );
  }
}

class OcrInvoiceService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  static Future<ExtractedInvoiceData> scanInvoice(String imagePath) async {
    try {
      // 1. INTENTO ON-DEVICE CON GOOGLE ML KIT (Gratis, ultra-rápido)
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      final String fullText = recognizedText.text;
      debugPrint('📄 Texto ML Kit extraído (${fullText.length} caracteres)');

      final mlKitResult = _parseMlKitText(fullText);
      if (mlKitResult.totalAmount > 0) {
        return mlKitResult;
      }

      // 2. FALLBACK A GEMINI VISION EN LA NUBE (Si el texto es complejo/manuscrito)
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        return await _scanWithGeminiVision(imagePath, apiKey);
      }

      return mlKitResult;
    } catch (e) {
      debugPrint('Error en escáner OCR de facturas: $e');
      return ExtractedInvoiceData.empty();
    }
  }

  static ExtractedInvoiceData _parseMlKitText(String text) {
    double total = 0.0;
    double gallons = 0.0;
    String date = '';
    String vendor = 'Estación de Servicio / Taller';
    List<String> items = [];

    final lines = text.split('\n');

    // Buscar precios ($)
    final priceRegex = RegExp(r'\$?\s*(\d{1,3}(?:[.,]\d{3})+|\d{4,7})');
    for (final l in lines) {
      final lUpper = l.toUpperCase();
      if (lUpper.contains('TOTAL') || lUpper.contains('VALOR') || lUpper.contains('PAGO')) {
        final match = priceRegex.firstMatch(l);
        if (match != null) {
          final clean = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
          total = double.tryParse(clean) ?? 0.0;
        }
      }
      if (lUpper.contains('GAL') || lUpper.contains('CANT') || lUpper.contains('LITROS')) {
        final galMatch = RegExp(r'(\d+[.,]\d+)').firstMatch(l);
        if (galMatch != null) {
          gallons = double.tryParse(galMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
        }
      }
      if (RegExp(r'\b(\d{2}[/\-]\d{2}[/\-]\d{4})\b').hasMatch(l)) {
        date = RegExp(r'\b(\d{2}[/\-]\d{2}[/\-]\d{4})\b').firstMatch(l)!.group(1)!;
      }
    }

    return ExtractedInvoiceData(
      totalAmount: total,
      gallons: gallons,
      date: date.isNotEmpty ? date : DateTime.now().toString().split(' ')[0],
      vendorName: vendor,
      items: items,
      sourceEngine: 'ML_Kit_Local',
    );
  }

  static Future<ExtractedInvoiceData> _scanWithGeminiVision(String imagePath, String apiKey) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": "Analiza esta factura de taller o recibo de gasolina y responde ÚNICAMENTE con un JSON válido en este formato exacto: {\"total\": 150000, \"gallons\": 8.5, \"vendor\": \"Terpel\", \"date\": \"2026-08-16\", \"items\": [\"Gasolina Extra\", \"Aceite\"]}"
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ]
      });

      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);
      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(response.body);
        final candidateText = jsonRes['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final cleanJsonStr = candidateText.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = jsonDecode(cleanJsonStr);

        return ExtractedInvoiceData(
          totalAmount: (parsed['total'] as num?)?.toDouble() ?? 0.0,
          gallons: (parsed['gallons'] as num?)?.toDouble() ?? 0.0,
          date: parsed['date'] ?? '',
          vendorName: parsed['vendor'] ?? 'Taller / Estación',
          items: (parsed['items'] as List?)?.map((e) => e.toString()).toList() ?? [],
          sourceEngine: 'Gemini_Vision_Cloud',
        );
      }
    } catch (e) {
      debugPrint('Error invocando Gemini Vision: $e');
    }
    return ExtractedInvoiceData.empty();
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
