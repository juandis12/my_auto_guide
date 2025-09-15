import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; // Importa tu pantalla de login

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
        'https://xstzerpnupubyfbhrrzu.supabase.co', // Reemplaza con tu URL Supabase
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzdHplcnBudXB1YnlmYmhycnp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3Mjg3NDYsImV4cCI6MjA3MzMwNDc0Nn0.viihWGH6wRcv3gQQ5AySAQtoCcIdGZ7kEaSWyhcz-3A', // Reemplaza con tu clave API anónima
  );

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
