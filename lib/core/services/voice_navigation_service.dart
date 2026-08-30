import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'navigation_service.dart';

class VoiceNavigationService {
  static final VoiceNavigationService _instance = VoiceNavigationService._internal();
  factory VoiceNavigationService() => _instance;
  VoiceNavigationService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isMuted = false;
  String _lastSpokenInstruction = '';
  int _lastSpokenStepIndex = -1;
  DateTime _lastSpeechTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  void setMuted(bool muted) {
    _isMuted = muted;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.52);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('VoiceNavigationService: Error inicializando TTS: $e');
    }
  }

  Future<void> speak(String text, {bool force = false}) async {
    if (_isMuted && !force) return;
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    // Evitar spam repitiendo la misma frase en menos de 4 segundos
    if (text == _lastSpokenInstruction && now.difference(_lastSpeechTime).inSeconds < 4 && !force) {
      return;
    }

    _lastSpokenInstruction = text;
    _lastSpeechTime = now;

    try {
      if (!_isInitialized) await init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('VoiceNavigationService: Error al hablar: $e');
    }
  }

  /// Procesa la posición actual contra los pasos de navegación y emite alertas de voz naturales
  void processTelemetry({
    required LatLng currentPos,
    required List<NavigationStep> steps,
    required int currentStepIndex,
    required String destinationName,
  }) {
    if (_isMuted || steps.isEmpty) return;

    if (currentStepIndex >= steps.length) {
      return;
    }

    final currentStep = steps[currentStepIndex];
    final distanceToStep = const Distance().as(LengthUnit.Meter, currentPos, currentStep.location);

    // Instrucción de llegada
    if (currentStepIndex == steps.length - 1 && distanceToStep < 35) {
      if (_lastSpokenStepIndex != 99999) {
        _lastSpokenStepIndex = 99999;
        speak('Ha llegado a su destino: $destinationName', force: true);
      }
      return;
    }

    final instruction = _humanizeInstruction(currentStep.instruction);

    // Alerta inicial al arrancar el viaje (anuncia el primer giro de inmediato)
    if (currentStepIndex == 0 && _lastSpokenStepIndex == -1) {
      _lastSpokenStepIndex = 0;
      final distRounded = distanceToStep > 50 ? ((distanceToStep / 50).round() * 50).toInt() : distanceToStep.round();
      if (distRounded > 20) {
        speak('Iniciando ruta. En $distRounded metros, $instruction', force: true);
      } else {
        speak('Iniciando ruta. $instruction', force: true);
      }
      return;
    }

    // Alerta a 200 - 150 metros
    if (distanceToStep <= 220 && distanceToStep > 130) {
      final key = 'far_${currentStepIndex}';
      if (_lastSpokenInstruction != key) {
        _lastSpokenInstruction = key;
        final distRounded = ((distanceToStep / 50).round() * 50).toInt();
        speak('En $distRounded metros, $instruction');
      }
    }
    // Alerta a 60 - 30 metros (Giro inminente)
    else if (distanceToStep <= 65 && distanceToStep > 20) {
      final key = 'near_${currentStepIndex}';
      if (_lastSpokenInstruction != key) {
        _lastSpokenInstruction = key;
        speak('En 40 metros, $instruction');
      }
    }
    // Giro inmediato (< 20 metros)
    else if (distanceToStep <= 20) {
      final key = 'now_${currentStepIndex}';
      if (_lastSpokenInstruction != key) {
        _lastSpokenInstruction = key;
        _lastSpokenStepIndex = currentStepIndex;
        speak('$instruction ahora');
      }
    }
  }

  String _humanizeInstruction(String raw) {
    if (raw.trim().isEmpty) return 'continúe recto';
    String text = raw.toLowerCase();

    if (text.contains('turn right') || text.contains('gira a la derecha') || text.contains('gire a la derecha')) {
      return 'gire a la derecha';
    }
    if (text.contains('turn left') || text.contains('gira a la izquierda') || text.contains('gire a la izquierda')) {
      return 'gire a la izquierda';
    }
    if (text.contains('straight') || text.contains('recto') || text.contains('continúa')) {
      return 'continúe todo recto';
    }
    if (text.contains('roundabout') || text.contains('rotonda')) {
      return 'en la rotonda tome la salida indicada';
    }
    if (text.contains('u-turn') || text.contains('retorno')) {
      return 'haga un retorno en U cuando sea seguro';
    }

    return raw;
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _lastSpokenInstruction = '';
    _lastSpokenStepIndex = -1;
  }
}
