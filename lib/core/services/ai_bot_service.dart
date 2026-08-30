// =============================================================================
// ai_bot_service.dart — ASISTENTE IA SEGURO (VULN-08 Fix)
// =============================================================================
// La GEMINI_API_KEY ya NO se incluye en el bundle del APK.
// Todas las peticiones pasan por la Edge Function 'gemini-chat' de Supabase,
// que actua como proxy seguro con rate limiting (20 req/min por usuario).
// =============================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIBotService {
  static final AIBotService _instance = AIBotService._internal();
  factory AIBotService() => _instance;
  AIBotService._internal();

  bool _initialized = false;

  void initialize({String? specificModel}) {
    // La inicializacion ahora es trivial: no se carga ninguna API key en el cliente.
    // El modelo se selecciona en el servidor (Edge Function gemini-chat).
    _initialized = true;
  }

  Future<String> sendMessage(String text) async {
    if (!_initialized) initialize();

    if (text.trim().isEmpty) return 'Por favor, escribe tu pregunta.';
    if (text.length > 2000) return 'El mensaje es demasiado largo. Por favor, acortalo.';

    try {
      // VULN-08: La API Key de Gemini vive SOLO en el servidor Supabase.
      // Esta llamada esta autenticada con el JWT del usuario actual.
      final response = await Supabase.instance.client.functions.invoke(
        'gemini-chat',
        body: {'message': text},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>?;
        return data?['text'] as String? ?? 'Sin respuesta de la IA.';
      }

      if (response.status == 429) {
        return 'Has alcanzado el limite de consultas por minuto. Espera un momento e intenta de nuevo.';
      }

      if (response.status == 401) {
        return 'Sesion no valida. Por favor, cierra sesion y vuelve a entrar.';
      }

      if (kDebugMode) {
        debugPrint('[AI] Edge Function respondio con status ${response.status}');
      }
      return 'Hubo un problema con el servicio de IA. Intenta de nuevo.';
    } catch (e) {
      if (kDebugMode) debugPrint('[AI] Error al invocar Edge Function gemini-chat');
      return 'No se pudo conectar con el asistente IA. Verifica tu conexion.';
    }
  }

  void resetChat() {
    initialize();
  }
}
