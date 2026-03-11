// =============================================================================
// main.dart — PUNTO DE ENTRADA DE LA APLICACIÓN
// =============================================================================
//
// Este archivo es el punto de arranque de «My Auto Guide».
// Responsabilidades:
//   1. Inicializar el framework Flutter (WidgetsFlutterBinding).
//   2. Conectar con Supabase (backend-as-a-service): base de datos,
//      autenticación y almacenamiento de archivos.
//   3. Configurar las zonas horarias (paquete timezone) para las
//      notificaciones programadas.
//   4. Inicializar el plugin de notificaciones locales en Android/iOS/Linux.
//   5. Lanzar la aplicación con [MyApp] y mostrar la pantalla de login.
//
// Flujo de navegación inicial:
//   main() → MyApp → CarRentalLoginScreen (login_screen.dart)
//
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'login_screen.dart'; // Pantalla de inicio de sesión
import 'runt_webview.dart';

/// Instancia global del plugin de notificaciones locales.
/// Se usa en toda la app para mostrar y programar alertas de mantenimiento.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Función principal — punto de entrada de la aplicación.
///
/// Ejecuta en orden:
/// 1. `ensureInitialized()` para garantizar que los bindings estén listos.
/// 2. `Supabase.initialize()` con la URL del proyecto y la clave anónima.
/// 3. `tz.initializeTimeZones()` para soporte de notificaciones programadas.
/// 4. Configuración del plugin de notificaciones para cada plataforma.
/// 5. `runApp()` para arrancar la interfaz gráfica.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. INICIALIZAR SUPABASE ───────────────────────────────────────────
  // Conecta con el proyecto de Supabase usando la URL y la clave pública.
  // Esto habilita: autenticación, consultas a la base de datos y storage.
  await Supabase.initialize(
    url: 'https://xstzerpnupubyfbhrrzu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzdHplcnBudXB1YnlmYmhycnp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3Mjg3NDYsImV4cCI6MjA3MzMwNDc0Nn0.viihWGH6wRcv3gQQ5AySAQtoCcIdGZ7kEaSWyhcz-3A',
  );

  // ── 2. INICIALIZAR ZONAS HORARIAS ─────────────────────────────────────
  // Necesario para programar notificaciones con fecha/hora exacta.
  tz.initializeTimeZones();

  // ── 3. CONFIGURAR NOTIFICACIONES LOCALES ──────────────────────────────
  // Se configura el ícono de la notificación (Android) y opciones por plataforma.
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Abrir notificación');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    linux: initializationSettingsLinux,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  // Solo inicializa notificaciones si NO estamos en web (no soportado).
  if (!kIsWeb) {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // ── 4. ARRANCAR LA APLICACIÓN ─────────────────────────────────────────
  runApp(const MyApp());
}

/// Widget raíz de la aplicación.
///
/// Configura:
/// - El tema global con Material 3 (semilla azul).
/// - La pantalla inicial: [CarRentalLoginScreen].
/// - Oculta el banner de debug.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Rental App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const CarRentalLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Muestra una notificación local o un SnackBar de respaldo en web.
///
/// En plataformas nativas utiliza el plugin de notificaciones;
/// en la versión web (donde no está disponible) muestra un SnackBar informativo.
void mostrarNotificacionOSugerencia(BuildContext context) {
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Las notificaciones automáticas no están disponibles en la versión web.',
        ),
      ),
    );
  } else {
    // Aquí se ejecutaría el código de notificaciones locales
  }
}

/// Pantalla de inicio alternativa (no se usa en el flujo principal).
///
/// Contiene un botón de ejemplo para abrir la consulta RUNT desde un WebView.
/// En la app real, la navegación se hace desde [InicioApp].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Abrir RUNT WebView'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RuntWebViewScreen(
                  placa: 'ABC123',
                  cedula: '12345678',
                  vehiculoId: '1',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

