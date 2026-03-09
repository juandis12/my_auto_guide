import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'login_screen.dart'; // Importa tu pantalla de login
import 'runt_webview.dart';

// Instancia global de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://xstzerpnupubyfbhrrzu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzdHplcnBudXB1YnlmYmhycnp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3Mjg3NDYsImV4cCI6MjA3MzMwNDc0Nn0.viihWGH6wRcv3gQQ5AySAQtoCcIdGZ7kEaSWyhcz-3A',
  );

  // Inicializar zonas horarias
  tz.initializeTimeZones();

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

  if (!kIsWeb) {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  runApp(const MyApp());
}

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
    // Aquí tu código normal de notificaciones locales
  }
}

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

// Asegúrate de tener tu RuntWebViewScreen como en el archivo anterior
