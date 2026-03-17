import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static const _platformChannel = MethodChannel('my_auto_guide/exact_alarms');

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Crear canales específicos
    if (Platform.isAndroid) {
      const AndroidNotificationChannel navChannel = AndroidNotificationChannel(
        'my_auto_guide_nav',
        'Navegación y Rutas',
        description: 'Notificaciones de seguimiento de rutas en tiempo real',
        importance: Importance.low, // Baja porque se actualiza seguido y no queremos ruido
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(navChannel);
    }
  }

  /// Verifica si la app puede agendar alarmas exactas (Android 12+).
  ///
  /// Si no se puede, muestra un diálogo para pedir al usuario que abra los
  /// ajustes de "Alarmas exactas".
  Future<bool> ensureExactAlarmsEnabled(BuildContext context) async {
    // Solo Android 12+ requiere permiso de alarmas exactas.
    if (!Platform.isAndroid) return true;

    try {
      final can =
          await _platformChannel.invokeMethod<bool>('canScheduleExactAlarms');
      if (can == true) return true;

      // Mostrar diálogo explicando por qué se necesita permiso.
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permiso de alarmas exactas'),
          content: const Text(
              'Para que los recordatorios se disparen en el momento exacto, '
              'la app requiere permiso de alarmas exactas. ¿Quieres abrir los ajustes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Abrir ajustes'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await _platformChannel.invokeMethod('requestScheduleExactAlarm');
      } else {
        // Usuario canceló; informar que las notificaciones pueden no ser exactas.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Notificaciones programadas pueden llegar con demora si no permites alarmas exactas.',
          ),
        ));
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> showMaintenanceNotification({
    required int id,
    required String title,
    required String body,
    DateTime? scheduledDate,
    BuildContext? context,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'mantenimiento_channel',
      'Mantenimientos',
      channelDescription: 'Recordatorios de mantenimiento de vehículos',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    if (scheduledDate != null) {
      // Si la fecha programada es en el pasado, no programar
      if (scheduledDate.isBefore(DateTime.now())) return;

      final hasPermission =
          context != null ? await ensureExactAlarmsEnabled(context) : false;

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: hasPermission
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } on Exception catch (e) {
        // En Android 13+ puede fallar si no se otorga permiso de alarmas exactas.
        // En ese caso, caemos a modo inexacto para evitar crash.
        if (e.toString().contains('exact_alarms_not_permitted')) {
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(scheduledDate, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } else {
          rethrow;
        }
      }
    } else {
      await _notificationsPlugin.show(id, title, body, notificationDetails);
    }
  }

  /// Programa una notificación para 5 días antes de la [dueDate].
  Future<void> scheduleLegalNotification({
    required int id,
    required String type, // 'SOAT' o 'Tecnomecánica'
    required DateTime dueDate,
  }) async {
    final scheduledDate = dueDate.subtract(const Duration(days: 5));
    // Si faltan menos de 5 días o ya venció, programar para hoy mismo si es posible
    final notificationDate = scheduledDate.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(minutes: 5))
        : scheduledDate;

    await showMaintenanceNotification(
      id: id,
      title: '¡Aviso de Vencimiento!',
      body:
          'Tu $type vence en 5 días (${dueDate.day}/${dueDate.month}). ¡No olvides renovarlo!',
      scheduledDate: notificationDate,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
