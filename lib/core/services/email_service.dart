import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static Future<bool> sendSimitReport({
    required String toEmail,
    required String placa,
    required int finesCount,
    required double totalAmount,
    required List<String> explanations,
    Map<String, dynamic>? vehicleData,
  }) async {
    final gmailUser = dotenv.get('GMAIL_EMAIL', fallback: '');
    final gmailPass = dotenv.get('GMAIL_APP_PASSWORD', fallback: '');
    final apiKey = dotenv.get('RESEND_API_KEY', fallback: '');

    final String htmlContent = _buildHtmlReport(
      placa: placa,
      finesCount: finesCount,
      totalAmount: totalAmount,
      explanations: explanations,
      vehicleData: vehicleData,
    );

    const String subject = 'Reporte de Estado de Vehículo - SIMIT y Vencimientos';

    // 1. PRIMERA OPCIÓN: Enviar usando directamente tu cuenta de Gmail (SMTP)
    if (gmailUser.isNotEmpty && gmailPass.isNotEmpty) {
      try {
        final smtpServer = gmail(gmailUser, gmailPass);
        final message = Message()
          ..from = Address(gmailUser, 'My Auto Guide')
          ..recipients.add(toEmail)
          ..subject = '$subject ($placa)'
          ..html = htmlContent;

        final sendReport = await send(message, smtpServer);
        debugPrint('EmailService (Gmail SMTP): Correo enviado exitosamente desde $gmailUser a $toEmail ($sendReport)');
        return true;
      } catch (e) {
        debugPrint('EmailService (Gmail SMTP): Error enviando con Gmail: $e. Reintentando respaldo...');
      }
    }

    // 2. SEGUNDA OPCIÓN: Respaldo vía Resend API
    if (apiKey.isNotEmpty) {
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
            'subject': '$subject ($placa)',
            'html': htmlContent,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('EmailService (Resend): Reporte enviado a $toEmail');
          return true;
        }
      } catch (e) {
        debugPrint('EmailService (Resend): Error de conexión: $e');
      }
    }

    debugPrint('EmailService: No se configuró GMAIL_APP_PASSWORD ni RESEND_API_KEY en el archivo .env');
    return false;
  }

  static String _buildHtmlReport({
    required String placa,
    required int finesCount,
    required double totalAmount,
    required List<String> explanations,
    Map<String, dynamic>? vehicleData,
  }) {
    final String explanationsHtml = explanations.isNotEmpty
        ? '<h3 style="color: #035880; margin-top: 20px;">Detalle de Infracciones SIMIT:</h3><ul style="background: #fff0f0; padding: 15px 25px; border-radius: 8px; border: 1px solid #ffcccc;">${explanations.map((exp) => '<li style="margin-bottom: 8px; color: #cc0000;">$exp</li>').join('')}</ul>'
        : '<div style="background: #e8f8f5; padding: 12px 15px; border-radius: 8px; border: 1px solid #a3e4d7; margin-top: 15px;">'
          '<p style="color: #117a65; font-weight: bold; margin: 0;">¡Buenas noticias! Tu vehículo se encuentra libre de comparendos activos en el portal SIMIT.</p>'
          '</div>';

    String maintenanceHtml = '';
    if (vehicleData != null) {
      List<String> alerts = [];

      final lastSoatStr = vehicleData['last_soat'] as String?;
      if (lastSoatStr != null && lastSoatStr.isNotEmpty) {
        final date = DateTime.tryParse(lastSoatStr);
        if (date != null) {
          final diff = date.difference(DateTime.now()).inDays;
          if (diff < 0) {
            alerts.add('<li style="margin-bottom: 6px; color: #d9534f;">🔴 <strong>SOAT Vencido</strong>: Venció el ${_fmtDate(date)} (hace ${-diff} días).</li>');
          } else if (diff <= 30) {
            alerts.add('<li style="margin-bottom: 6px; color: #f0ad4e;">🟡 <strong>SOAT por Vencer</strong>: Vence el ${_fmtDate(date)} (quedan $diff días).</li>');
          } else {
            alerts.add('<li style="margin-bottom: 6px; color: #5cb85c;">🟢 <strong>SOAT Vigente</strong>: Hasta el ${_fmtDate(date)}.</li>');
          }
        }
      }

      final lastTecnoStr = vehicleData['last_tecno'] as String?;
      if (lastTecnoStr != null && lastTecnoStr.isNotEmpty) {
        final date = DateTime.tryParse(lastTecnoStr);
        if (date != null) {
          final diff = date.difference(DateTime.now()).inDays;
          if (diff < 0) {
            alerts.add('<li style="margin-bottom: 6px; color: #d9534f;">🔴 <strong>Tecnomecánica Vencida</strong>: Venció el ${_fmtDate(date)} (hace ${-diff} días).</li>');
          } else if (diff <= 30) {
            alerts.add('<li style="margin-bottom: 6px; color: #f0ad4e;">🟡 <strong>Tecnomecánica por Vencer</strong>: Vence el ${_fmtDate(date)} (quedan $diff días).</li>');
          } else {
            alerts.add('<li style="margin-bottom: 6px; color: #5cb85c;">🟢 <strong>Tecnomecánica Vigente</strong>: Hasta el ${_fmtDate(date)}.</li>');
          }
        }
      }

      final kmsActuales = (vehicleData['kms'] as num?)?.toDouble() ?? 0.0;
      final kmsLastAceite = (vehicleData['kms_last_aceite'] as num?)?.toDouble() ?? 0.0;
      if (kmsLastAceite > 0) {
        final kmDiff = kmsActuales - kmsLastAceite;
        const kmInterval = 3000.0;
        if (kmDiff >= kmInterval) {
          alerts.add('<li style="margin-bottom: 6px; color: #d9534f;">🔴 <strong>Cambio de Aceite Requerido</strong>: Has recorrido ${kmDiff.round()} km desde el último cambio (límite: 3,000 km).</li>');
        } else {
          final rem = (kmInterval - kmDiff).round();
          alerts.add('<li style="margin-bottom: 6px; color: #5cb85c;">🟢 <strong>Aceite de Motor OK</strong>: Faltan aprox. $rem km para el próximo cambio.</li>');
        }
      }

      if (alerts.isNotEmpty) {
        maintenanceHtml = '''
          <h3 style="color: #035880; margin-top: 25px;">Estado de Documentos y Mantenimiento:</h3>
          <ul style="background: #f8f9fa; padding: 15px 25px; border-radius: 8px; border: 1px solid #e0e0e0; list-style-type: none;">
            ${alerts.join('')}
          </ul>
        ''';
      }
    }

    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px; color: #333333;">
        <h2 style="color: #035880; border-bottom: 2px solid #035880; padding-bottom: 10px;">My Auto Guide — Reporte de Vehículo</h2>
        <p>Hola,</p>
        <p>A continuación encuentras el reporte detallado del estado de tu vehículo registrado en la aplicación:</p>
        
        <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
          <tr style="background-color: #f8f9fa;">
            <th style="padding: 10px; border: 1px solid #dddddd; text-align: left; width: 40%;">Placa</th>
            <td style="padding: 10px; border: 1px solid #dddddd; font-weight: bold;">$placa</td>
          </tr>
          <tr>
            <th style="padding: 10px; border: 1px solid #dddddd; text-align: left;">Multas SIMIT</th>
            <td style="padding: 10px; border: 1px solid #dddddd; font-weight: bold; color: ${finesCount > 0 ? '#d9534f' : '#5cb85c'};">$finesCount multas</td>
          </tr>
          <tr style="background-color: #f8f9fa;">
            <th style="padding: 10px; border: 1px solid #dddddd; text-align: left;">Valor Total a Pagar</th>
            <td style="padding: 10px; border: 1px solid #dddddd; font-weight: bold; color: #035880;">\$${totalAmount.round()} COP</td>
          </tr>
          <tr>
            <th style="padding: 10px; border: 1px solid #dddddd; text-align: left;">Fecha del Reporte</th>
            <td style="padding: 10px; border: 1px solid #dddddd;">${DateTime.now().toLocal().toString().substring(0, 19)}</td>
          </tr>
        </table>
        
        $explanationsHtml
        
        $maintenanceHtml
        
        <p style="font-size: 12px; color: #777777; margin-top: 30px; border-top: 1px solid #e0e0e0; padding-top: 10px;">
          Este es un reporte automático enviado por <strong>My Auto Guide</strong>.
        </p>
      </div>
    ''';
  }
}
