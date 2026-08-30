import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// VULN-02: Las credenciales SMTP nunca salen del servidor de Supabase.
// Delegamos todo el envio de emails a las Edge Functions de Supabase.

class EmailService {
  static String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  /// Envía un reporte del SIMIT con un diseño responsivo premium.
  static Future<bool> sendSimitReport({
    required String toEmail,
    required String placa,
    required int finesCount,
    required double totalAmount,
    required List<String> explanations,
    Map<String, dynamic>? vehicleData,
  }) async {
    final client = Supabase.instance.client;
    final userName = client.auth.currentUser?.userMetadata?['name'] ?? 
                     client.auth.currentUser?.email?.split('@').first ?? 
                     'Conductor';

    final String htmlContent = _buildHtmlReport(
      userName: userName,
      placa: placa,
      finesCount: finesCount,
      totalAmount: totalAmount,
      explanations: explanations,
      vehicleData: vehicleData,
    );

    const String subject = 'Reporte de Estado de Vehículo - SIMIT y Vencimientos';

    try {
      final response = await client.functions.invoke(
        'send-email',
        body: {
          'toEmail': toEmail.trim(),
          'subject': subject,
          'htmlContent': htmlContent,
          'placa': placa,
        },
      );

      if (response.status == 200 || response.status == 201) {
        final data = response.data as Map<String, dynamic>?;
        if (data?['ok'] == true) {
          if (kDebugMode) debugPrint('[EMAIL] Reporte SIMIT enviado correctamente por Resend');
          return true;
        }
      }
      if (kDebugMode) debugPrint('[EMAIL] Falló entrega SIMIT: ${response.data}');
    } catch (e) {
      if (kDebugMode) debugPrint('[EMAIL] Error invocando Edge Function: $e');
    }

    return false;
  }

  /// Envía una alerta de mantenimiento del vehículo (crítica o preventiva).
  static Future<bool> sendMaintenanceAlertEmail({
    required String toEmail,
    required String maintenanceType,
    required double remainingPct,
    required double currentKms,
    required String vehicleBrand,
    required String vehicleNickname,
    required bool isPreventive,
  }) async {
    final client = Supabase.instance.client;
    final userName = client.auth.currentUser?.userMetadata?['name'] ?? 
                     client.auth.currentUser?.email?.split('@').first ?? 
                     'Conductor';

    final subject = isPreventive 
        ? '⚠️ Mantenimiento Preventivo Próximo: $maintenanceType' 
        : '🚨 ALERTA CRÍTICA: Mantenimiento Vencido ($maintenanceType)';

    try {
      final response = await client.functions.invoke(
        'send-email',
        body: {
          'toEmail': toEmail.trim(),
          'subject': subject,
          'placa': '', // Omitido en asunto principal
          'userName': userName,
          'maintenanceType': maintenanceType,
          'remainingPct': remainingPct,
          'currentKms': currentKms,
          'vehicleBrand': vehicleBrand,
          'vehicleNickname': vehicleNickname,
          'isPreventive': isPreventive,
        },
      );

      if (response.status == 200 || response.status == 201) {
        final data = response.data as Map<String, dynamic>?;
        if (data?['ok'] == true) {
          if (kDebugMode) debugPrint('[EMAIL] Alerta mecánica enviada correctamente');
          return true;
        }
      }
      if (kDebugMode) debugPrint('[EMAIL] Falló entrega de alerta: ${response.data}');
    } catch (e) {
      if (kDebugMode) debugPrint('[EMAIL] Error enviando alerta de mantenimiento: $e');
    }
    return false;
  }

  /// Genera la plantilla HTML Premium para el reporte de multas (SIMIT)
  static String _buildHtmlReport({
    required String userName,
    required String placa,
    required int finesCount,
    required double totalAmount,
    required List<String> explanations,
    Map<String, dynamic>? vehicleData,
  }) {
    final isClean = finesCount == 0;
    final statusColor = isClean ? '#00FF87' : '#FF3B30';
    final statusTitle = isClean ? 'VEHÍCULO LIBRE DE MULTAS' : 'SE DETECTARON MULTAS';
    
    final String explanationsHtml = explanations.isNotEmpty
        ? explanations.map((exp) => '<li style="margin-bottom: 10px; color: #E2E8F0; line-height: 1.5; font-size: 13px;">🔴 $exp</li>').join('')
        : '<li style="color: #00FF87; line-height: 1.5; font-size: 13px; font-weight: bold;">🟢 Sin comparendos pendientes registrados en el portal oficial del SIMIT.</li>';

    String docsHtml = '';
    if (vehicleData != null) {
      List<String> docItems = [];
      final lastSoat = vehicleData['last_soat'] as String?;
      if (lastSoat != null && lastSoat.isNotEmpty) {
        final d = DateTime.tryParse(lastSoat);
        if (d != null) {
          final diff = d.difference(DateTime.now()).inDays;
          final color = diff < 0 ? '#FF3B30' : (diff <= 30 ? '#FF9500' : '#00FF87');
          final status = diff < 0 ? 'SOAT Vencido' : 'SOAT Vigente';
          docItems.add('<div style="padding: 10px 0; border-bottom: 1.2px solid #1F2430; display: flex; justify-content: space-between; font-size: 13px;"><span style="color: #718096;">SOAT</span><span style="color: $color; font-weight: 700;">$status (${_fmtDate(d)})</span></div>');
        }
      }
      final lastTecno = vehicleData['last_tecno'] as String?;
      if (lastTecno != null && lastTecno.isNotEmpty) {
        final d = DateTime.tryParse(lastTecno);
        if (d != null) {
          final diff = d.difference(DateTime.now()).inDays;
          final color = diff < 0 ? '#FF3B30' : (diff <= 30 ? '#FF9500' : '#00FF87');
          final status = diff < 0 ? 'Tecnomecánica Vencida' : 'Tecnomecánica Vigente';
          docItems.add('<div style="padding: 10px 0; border-bottom: 1.2px solid #1F2430; display: flex; justify-content: space-between; font-size: 13px;"><span style="color: #718096;">TECNOMECÁNICA</span><span style="color: $color; font-weight: 700;">$status (${_fmtDate(d)})</span></div>');
        }
      }
      if (docItems.isNotEmpty) {
        docsHtml = '''
        <div style="margin-top: 25px;">
          <h3 style="color: #FFFFFF; font-size: 14px; text-transform: uppercase; margin-bottom: 12px; letter-spacing: 0.5px;">Estado Legal del Activo</h3>
          <div style="background-color: #0D0F14; border-radius: 12px; border: 1.5px solid #1F2430; padding: 15px;">
            ${docItems.join('')}
          </div>
        </div>
        ''';
      }
    }

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reporte SIMIT - My Auto Guide</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #0A0C10; color: #FFFFFF; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #14171F; border-radius: 24px; border: 1.5px solid #1F2430; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
          
          <!-- Cabecera -->
          <div style="text-align: center; margin-bottom: 25px;">
            <div style="font-size: 24px; font-weight: 900; color: #00FF87; letter-spacing: 1px; margin-bottom: 15px;">MY AUTO GUIDE</div>
            <div style="display: inline-block; padding: 6px 14px; border-radius: 30px; font-size: 11px; font-weight: 900; letter-spacing: 0.8px; color: #000000; background-color: $statusColor;">$statusTitle</div>
            <h2 style="font-size: 20px; font-weight: 800; margin: 15px 0 5px 0; color: #FFFFFF;">Estado del Vehículo (Placa: $placa)</h2>
            <p style="font-size: 13px; color: #A0AEC0; line-height: 1.5; margin: 0;">Hola $userName,<br>A continuación te presentamos el resultado consolidado del SIMIT y estado del vehículo.</p>
          </div>

          <!-- Tabla de Datos -->
          <div style="background-color: #0D0F14; border-radius: 14px; padding: 18px; border: 1px solid #181C26;">
            <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #1F2430; font-size: 13px;">
              <span style="color: #718096;">PLACA VEHÍCULO</span>
              <span style="font-weight: 700; color: #FFFFFF;">$placa</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #1F2430; font-size: 13px;">
              <span style="color: #718096;">CANTIDAD DE MULTAS</span>
              <span style="font-weight: 700; color: $statusColor;">$finesCount comparendos</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 8px 0; font-size: 13px;">
              <span style="color: #718096;">MONTO TOTAL COMPROMETIDO</span>
              <span style="font-weight: 900; color: #00FF87;">\$${totalAmount.round()} COP</span>
            </div>
          </div>

          <!-- Listado Detallado SIMIT -->
          <div style="margin-top: 25px;">
            <h3 style="color: #FFFFFF; font-size: 14px; text-transform: uppercase; margin-bottom: 12px; letter-spacing: 0.5px;">Detalle Comparendos (SIMIT)</h3>
            <div style="background-color: #0D0F14; border-radius: 12px; border: 1.5px solid #1F2430; padding: 18px;">
              <ul style="margin: 0; padding-left: 5px; list-style-type: none;">
                $explanationsHtml
              </ul>
            </div>
          </div>

          <!-- Historial Documentos -->
          $docsHtml

          <!-- Botón de acción -->
          <a href="myautoguide://home" style="display: block; width: 85%; margin: 35px auto 15px auto; padding: 16px; border-radius: 12px; background-color: #035880; color: #FFFFFF; text-align: center; font-weight: 700; font-size: 14px; text-decoration: none; box-shadow: 0 4px 15px rgba(3, 88, 128, 0.4);">VER DETALLES EN LA APP</a>

          <!-- Footer -->
          <div style="font-size: 10px; color: #4A5568; text-align: center; margin-top: 30px; line-height: 1.4; border-top: 1.2px solid #1F2430; padding-top: 15px;">
            Este reporte fue solicitado y generado de forma segura mediante la plataforma.<br>
            © 2026 My Auto Guide. Todos los derechos reservados.
          </div>

        </div>
      </div>
    </body>
    </html>
    ''';
  }
}

}
