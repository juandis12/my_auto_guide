import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/services/notification_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/vehicle_provider.dart';
import 'core/services/sync_service.dart';
import 'features/auth/login_screen.dart';

/// Función principal — punto de entrada de la aplicación.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
// 1. Cargar variables de entorno (dotenv)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Archivo .env no encontrado. Asegúrate de crearlo.");
  }

  // 2. Inicializar Sentry (solo si hay DSN configurado)
  final sentryDsn = dotenv.get('SENTRY_DSN', fallback: '');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(const MyApp()),
    );
  } else {
    debugPrint('Sentry DSN no configurado. Saltando inicialización de Sentry.');
    runApp(const MyApp());
    }

    // 2. Inicializar Supabase
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL',
          fallback: const String.fromEnvironment('SUPABASE_URL')),
      anonKey: dotenv.get('SUPABASE_ANON_KEY',
          fallback: const String.fromEnvironment('SUPABASE_ANON_KEY')),
    );

    // 3. Inicializar Sync Service para sincronización offline
    SyncService().initialize();

    // 4. Inicializar Notificaciones y Zonas Horarias
    if (!kIsWeb) {
      await NotificationService().init();
    }

    // 5. ARRANCAR LA APLICACIÓN
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // En caso de error en inicialización, mostrar pantalla de error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error al inicializar la app: $e'),
        ),
      ),
    ));
    // Reportar a Sentry si está disponible
    Sentry.captureException(e, stackTrace: stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
      ],
      child: MaterialApp(
        title: 'My Auto Guide',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB), // Azul moderno
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.outfitTextTheme(),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        ),
        themeMode: ThemeMode.system,
        home: const CarRentalLoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
