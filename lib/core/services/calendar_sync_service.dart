// =============================================================================
// calendar_sync_service.dart — SINCRONIZACIÓN DE EVENTOS EN CALENDARIO (ANDROID & IOS)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CalendarSyncService {
  /// Abre el calendario nativo del teléfono (Google Calendar o Apple Calendar en iOS)
  /// para programar un evento de vencimiento (SOAT, Tecno, Cambio de Aceite)
  static Future<bool> addEventToCalendar({
    required String title,
    required String description,
    required DateTime eventDate,
    required BuildContext context,
  }) async {
    final DateFormat formatter = DateFormat("yyyyMMdd'T'HHmmss");
    final String startDateStr = formatter.format(eventDate);
    final String endDateStr = formatter.format(eventDate.add(const Duration(hours: 1)));

    // 1. Intent de Google Calendar Web (funciona en Safari iOS y Chrome Android)
    final Uri googleCalendarUrl = Uri.parse(
      'https://calendar.google.com/calendar/render?'
      'action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&details=${Uri.encodeComponent(description)}'
      '&dates=$startDateStr/$endDateStr',
    );

    try {
      if (await canLaunchUrl(googleCalendarUrl)) {
        await launchUrl(googleCalendarUrl, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('Aviso: Error al abrir Google Calendar: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📅 No se pudo abrir la app de Calendario automáticamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
}
