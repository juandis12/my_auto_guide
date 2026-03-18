import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIBotService {
  static final AIBotService _instance = AIBotService._internal();
  factory AIBotService() => _instance;
  AIBotService._internal();

  GenerativeModel? _model;
  ChatSession? _chat;
  String _currentModelName = 'gemini-1.5-flash';

  final List<String> _modelFallbacks = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash-8b', // Último remanente de la serie 1.5
  ];

  void initialize({String? specificModel}) {
    final apiKey = dotenv.get('GEMINI_API_KEY', fallback: '');
    if (apiKey.isEmpty) return;

    _currentModelName = specificModel ?? _modelFallbacks.first;

    _model = GenerativeModel(
      model: _currentModelName,
      apiKey: apiKey,
      systemInstruction: Content.system('''
Actúa como un ingeniero de software senior, arquitecto de sistemas y experto mecánico automotriz especializado en el proyecto "MY AUTO GUIDE".

Tu misión es asistir al usuario en dudas técnicas sobre sus vehículos y el uso de la aplicación.

REGLAS ABSOLUTAS:
1. Especialidad Exclusiva: Solo respondes sobre mecánica, mantenimiento, técnica automotriz, seguridad vial y el funcionamiento de My Auto Guide.
2. Veracidad: Nunca inventes datos. Si no conoces la respuesta técnica oficial, di: "NO PUEDO CONFIRMAR ESTO".
3. Razonamiento Técnico: Explica el "porqué" de las averías o mantenimientos paso a paso.
4. Identidad: Eres "Master Mechanic", el asistente inteligente de My Auto Guide.
5. Filtro de Temas: Si te preguntan sobre cocina, política, o cualquier tema ajeno a los vehículos, responde amablemente que tu experticia se limita al mundo automotriz.
6. Datos de My Auto Guide: Sabes que la app maneja RUNT, GPS tracking, gastos y mantenimientos preventivos.

Ejemplos de respuesta:
- Si preguntan por presión de llantas: Da el dato técnico habitual para ese modelo (si lo conoces) o explica cómo leerlo en el manual/basculante.
- Si describen un ruido: Explica posibles causas mecánicas (ej: pastillas desgastadas, rodamientos, etc).
'''),
    );

    _chat = _model!.startChat();
  }

  Future<String> sendMessage(String text) async {
    int retryCount = 0;
    
    while (retryCount < _modelFallbacks.length) {
      if (_chat == null) {
        initialize(specificModel: _modelFallbacks[retryCount]);
      }
      if (_chat == null) return "Error: IA no configurada. Verifica tu API Key.";

      try {
        final response = await _chat!.sendMessage(Content.text(text));
        return response.text ?? "Sin respuesta de la IA.";
      } catch (e) {
        final errorStr = e.toString();
        debugPrint('AI Error con $_currentModelName: $errorStr');

        // Si el error es de modelo no encontrado o versión de API, probamos el siguiente
        if (errorStr.contains('not found') || errorStr.contains('404') || errorStr.contains('supported')) {
          retryCount++;
          _chat = null; // Forzar re-inicialización con el siguiente modelo
          if (retryCount >= _modelFallbacks.length) {
            return "No se encontró un modelo de IA compatible. Por favor, intenta más tarde o verifica tu API Key.";
          }
          continue; 
        }
        
        return "Hubo un problema de conexión con la IA: $e";
      }
    }
    return "Error inesperado en el servicio de IA.";
  }

  void resetChat() {
    _chat = null;
    initialize();
  }
}
