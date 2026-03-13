import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/notification_service.dart';
import 'features/auth/login_screen.dart';

/// Función principal — punto de entrada de la aplicación.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://xstzerpnupubyfbhrrzu.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzdHplcnBudXB1YnlmYmhycnp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3Mjg3NDYsImV4cCI6MjA3MzMwNDc0Nn0.viihWGH6wRcv3gQQ5AySAQtoCcIdGZ7kEaSWyhcz-3A'),
  );

  // 2. Inicializar Notificaciones y Zonas Horarias
  if (!kIsWeb) {
    await NotificationService().init();
  }

  // 3. ARRANCAR LA APLICACIÓN
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Auto Guide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CarRentalLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

