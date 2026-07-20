import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static Future<bool> sendSimitReport({
    required String toEmail,
    required String placa,
    required int finesCount,
    required double totalAmount,
    required List<String> explanations,
  }) async {
    final apiKey = dotenv.get('RESEND_API_KEY', fallback: '');
    if (apiKey.isEmpty) {
      debugPrint('EmailService: RESEND_API_KEY no configurado en el archivo .env');
      return false;
    }

    final String explanationsHtml = explanations.isNotEmpty
        ? '<h3>Detalle de infracciones encontradas:</h3><ul>' +
            explanations.map((exp) => '<li style="margin-bottom: 8px;">$exp</li>').join('') +
            '</ul>'
        : '<p style="color: #5cb85c; font-weight: bold;">¡Buenas noticias! Tu vehículo se encuentra libre de comparendos activos en el portal SIMIT.</p>';

    final String htmlContent = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px; color: #333333;">
        <h2 style="color: #035880; border-bottom: 2px solid #035880; padding-bottom: 10px;">My Auto Guide — Reporte SIMIT</h2>
        <p>Hola,</p>
        <p>Se ha realizado un escaneo automático del estado legal de tu vehículo en el portal oficial del SIMIT.</p>
        
        <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
          <tr style="background-color: #f8f9fa;">
            <th style="padding: 10px; border: 1px solid #dddddd; text-align: left; width: 40%;">Placa</th>
            <td style="padding: 10px; border: 1px solid #dddddd;">$placa</td>
          </tr>
          <tr>
            <th style="padding: 10px; border: 1px solid #dddddd; text-align: left;">Cantidad de Multas</th>
            <td style="padding: 10px; border: 1px solid #dddddd; font-weight: bold; color: ${finesCount > 0 ? '#d9534f' : '#5cb85c'};">$finesCount</td>
          </tr>
          <tr style="background-color: #f8f9fa;">
            <th style="padding: 10px; border: 1px solid #dddddd; text-align: left;">Valor Total a Pagar</th>
            <td style="padding: 10px; border: 1px solid #dddddd; font-weight: bold; color: #035880;">\$${totalAmount.round()} COP</td>
          </tr>
          <tr>
            <th style="padding: 10px; border: 1px solid #dddddd; text-align: left;">Fecha de Escaneo</th>
            <td style="padding: 10px; border: 1px solid #dddddd;">${DateTime.now().toLocal().toString().substring(0, 19)}</td>
          </tr>
        </table>
        
        $explanationsHtml
        
        <p style="font-size: 12px; color: #777777; margin-top: 30px; border-top: 1px solid #e0e0e0; padding-top: 10px;">
          Este es un reporte automático enviado por <strong>My Auto Guide</strong>. Por favor no respondas a este correo.
        </p>
      </div>
    ''';

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'My Auto Guide <onboarding@resend.dev>',
          'to': [toEmail],
          'subject': 'Reporte de Comparendos SIMIT - Placa $placa',
          'html': htmlContent,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('EmailService: Reporte enviado correctamente a $toEmail');
        return true;
      } else {
        debugPrint('EmailService: Error al enviar correo (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('EmailService: Error de conexión al enviar correo: $e');
      return false;
    }
  }
}
