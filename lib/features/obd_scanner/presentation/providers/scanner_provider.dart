import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/obd_bluetooth_service.dart';
import '../../data/obd_decoder.dart';
import '../../data/vin_decoder_service.dart';

enum ScannerState {
  disconnected,
  scanning,
  connecting,
  initializing,
  connected,
  error,
}

/// Proveedor de estado y orquestador universal de diagnóstico OBD2 multimarca
class ScannerProvider extends ChangeNotifier {
  final ObdBluetoothService _btService = ObdBluetoothService();

  ScannerState _state = ScannerState.disconnected;
  ScannerState get state => _state;

  List<ScanResult> _devices = [];
  List<ScanResult> get devices => _devices;

  String _errorMessage = "";
  String get errorMessage => _errorMessage;

  String _liveDataStr = "";
  String get liveData => _liveDataStr;

  // Identidad del vehículo detectado (Universal)
  VehicleIdentity? _vehicleIdentity;
  VehicleIdentity? get vehicleIdentity => _vehicleIdentity;

  String _vehicleDisplayName = "Vehículo Conectado";
  String get vehicleDisplayName => _vehicleDisplayName;

  String _detectedProtocol = "Buscando protocolo...";
  String get detectedProtocol => _detectedProtocol;

  String? get detectedVin => _vehicleIdentity?.vin;

  // Protocolo forzado manualmente por el usuario (si aplica, ej: "ATSP5")
  String? _protocolOverride;
  String? get protocolOverride => _protocolOverride;

  // Voltaje de la batería del vehículo (Leído directo del pin 16 vía ATRV)
  double? _batteryVoltage;
  double? get batteryVoltage => _batteryVoltage;

  // PIDs soportados por esta ECU específica
  final Set<String> _supportedPids = {};
  Set<String> get supportedPids => Set.unmodifiable(_supportedPids);

  // Datos decodificados en tiempo real
  final Map<String, dynamic> _liveMetrics = {};
  Map<String, dynamic> get liveMetrics => Map.unmodifiable(_liveMetrics);

  // Códigos de Falla Confirmados (Modo 03) y Pendientes (Modo 07)
  List<String> _currentDtcs = [];
  List<String> get currentDtcs => List.unmodifiable(_currentDtcs);

  List<String> _pendingDtcs = [];
  List<String> get pendingDtcs => List.unmodifiable(_pendingDtcs);

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<String>? _dataSub;

  bool _isLoopRunning = false;

  ScannerProvider({String? initialVehicleName}) {
    if (initialVehicleName != null && initialVehicleName.trim().isNotEmpty) {
      _vehicleDisplayName = initialVehicleName.trim();
    }
    _initListeners();
  }

  void setInitialVehicleName(String? name) {
    if (name != null && name.trim().isNotEmpty && _vehicleIdentity == null) {
      _vehicleDisplayName = name.trim();
      notifyListeners();
    }
  }

  /// Permite al usuario forzar manualmente un protocolo si su auto es especial (ej: ATSP5 para Nissan KWP)
  void setProtocolOverride(String? protocolCmd) {
    _protocolOverride = protocolCmd;
    notifyListeners();
  }

  void _initListeners() {
    _scanSub = _btService.scanResults.listen((results) {
      _devices = results.where((r) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;
        return name.trim().isNotEmpty;
      }).toList();
      notifyListeners();
    });

    _connSub = _btService.connectionState.listen((connectionState) {
      if (connectionState == BluetoothConnectionState.disconnected) {
        if (_state != ScannerState.disconnected) {
          _stopPolling();
          _state = ScannerState.disconnected;
          _errorMessage = "Conexión Bluetooth finalizada o perdida";
          notifyListeners();
        }
      }
    });

    _dataSub = _btService.obdDataStream.listen((data) {
      _liveDataStr += data;
      if (_liveDataStr.length > 500) {
        _liveDataStr = _liveDataStr.substring(_liveDataStr.length - 500);
      }
      notifyListeners();
    });
  }

  /// Inicia el escaneo de adaptadores OBD2 BLE
  Future<void> startScanning() async {
    try {
      _state = ScannerState.scanning;
      _errorMessage = "";
      _devices.clear();
      notifyListeners();
      await _btService.startScan();
    } catch (e) {
      _state = ScannerState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Detiene el escaneo
  Future<void> stopScanning() async {
    await _btService.stopScan();
    if (_state == ScannerState.scanning) {
      _state = ScannerState.disconnected;
      notifyListeners();
    }
  }

  /// Conecta al dispositivo y realiza el handshake con la ECU del vehículo
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _errorMessage = "";
      _state = ScannerState.connecting;
      notifyListeners();

      // Fase 1: Conexión BLE y descubrimiento de características GATT
      await _btService.connectToDevice(device);

      // Fase 2: Inicialización ELM327 y protocolo vehicular universal
      _state = ScannerState.initializing;
      notifyListeners();

      await _initializeElmProtocol();

      // Fase 3: Conexión confirmada con ECU -> Iniciar telemetría
      _state = ScannerState.connected;
      notifyListeners();

      _startPolling();
    } catch (e) {
      _stopPolling();
      _state = ScannerState.error;
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      notifyListeners();
    }
  }

  /// Matriz universal de inicialización ELM327 / OBD2 que cubre el 100% de protocolos
  Future<void> _initializeElmProtocol() async {
    // 1. Reset del ELM327
    await _btService.sendCommand("ATZ", timeout: const Duration(seconds: 3));
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Configurar parámetros estándar ELM327
    await _btService.sendCommand("ATE0", timeout: const Duration(seconds: 2)); // Echo Off
    await _btService.sendCommand("ATL0", timeout: const Duration(seconds: 2)); // Linefeeds Off
    await _btService.sendCommand("ATS0", timeout: const Duration(seconds: 2)); // Spaces Off
    await _btService.sendCommand("ATH0", timeout: const Duration(seconds: 2)); // Headers Off

    // 3. Leer voltaje inicial de batería (Funciona en todos los vehículos desde el pin 16)
    try {
      final vRes = await _btService.sendCommand("ATRV", timeout: const Duration(seconds: 2));
      _batteryVoltage = ObdDecoder.decodeVoltageResponse(vRes);
      if (_batteryVoltage != null) {
        _liveMetrics['BatteryVoltage'] = {
          'type': 'BatteryVoltage',
          'value': _batteryVoltage,
          'unit': 'V',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (_) {}

    // 4. Temporización adaptativa para acelerar respuestas en ECUs modernas
    try {
      await _btService.sendCommand("ATAT2", timeout: const Duration(seconds: 2));
    } catch (_) {}

    bool ecuConnected = false;

    // Si el usuario forzó un protocolo manual específico
    if (_protocolOverride != null && _protocolOverride!.isNotEmpty) {
      try {
        debugPrint("[SCANNER_PROVIDER] Usando protocolo forzado por usuario: $_protocolOverride");
        await _btService.sendCommand(_protocolOverride!, timeout: const Duration(seconds: 2));
        final forcedRes = await _btService.sendCommand("0100", timeout: const Duration(seconds: 6));
        if (ObdDecoder.isEcuResponding(forcedRes)) {
          ecuConnected = true;
          _parseSupportedPids(forcedRes);
        }
      } catch (e) {
        debugPrint("[SCANNER_PROVIDER] Protocolo forzado falló: $e");
      }
    }

    // 5. Negociación Automática (ATSP0) con timeout suficiente para escaneo multi-bus
    if (!ecuConnected) {
      try {
        await _btService.sendCommand("ATSP0", timeout: const Duration(seconds: 2));
        final probeResult = await _btService.sendCommand("0100", timeout: const Duration(seconds: 8));
        if (ObdDecoder.isEcuResponding(probeResult)) {
          ecuConnected = true;
          _parseSupportedPids(probeResult);
        }
      } catch (e) {
        debugPrint("[SCANNER_PROVIDER] Auto-protocolo ATSP0 no respondió a tiempo: $e");
      }
    }

    // 6. Matriz de Protocolos de Fallback Universal
    // Si ATSP0 no enganchó (típico en Nissan KWP2000, camiones diésel o CAN 250k),
    // probamos metódicamente cada uno de los protocolos automotrices existentes:
    if (!ecuConnected) {
      final universalProtocolMatrix = [
        {'cmd': 'ATSP5', 'name': 'ISO 14230-4 KWP (Fast Init)', 'desc': 'KWP2000 Rápido (Nissan Navara / Renault / Hyundai / Diésel)'},
        {'cmd': 'ATSP6', 'name': 'ISO 15765-4 CAN (11-bit, 500k)', 'desc': 'CAN 500k Estándar Moderno (Toyota, Chevrolet, Ford, Mazda)'},
        {'cmd': 'ATSP8', 'name': 'ISO 15765-4 CAN (11-bit, 250k)', 'desc': 'CAN 250k (Pickups Diésel, Nissan, Ford Transit)'},
        {'cmd': 'ATSP4', 'name': 'ISO 14230-4 KWP (5 baud init)', 'desc': 'KWP2000 Lento'},
        {'cmd': 'ATSP3', 'name': 'ISO 9141-2', 'desc': 'ISO 9141-2 (Asiáticos / Europeos clásicos)'},
        {'cmd': 'ATSP7', 'name': 'ISO 15765-4 CAN (29-bit, 500k)', 'desc': 'CAN 29-bit 500k (Europeos comerciales y Honda)'},
        {'cmd': 'ATSP9', 'name': 'ISO 15765-4 CAN (29-bit, 250k)', 'desc': 'CAN 29-bit 250k'},
        {'cmd': 'ATSP1', 'name': 'SAE J1850 PWM', 'desc': 'Ford Clásico (41.6k)'},
        {'cmd': 'ATSP2', 'name': 'SAE J1850 VPW', 'desc': 'General Motors / Chrysler Clásico (10.4k)'},
      ];

      for (final p in universalProtocolMatrix) {
        try {
          debugPrint("[SCANNER_PROVIDER] Probando protocolo universal: ${p['name']}");
          await _btService.sendCommand(p['cmd']!, timeout: const Duration(seconds: 2));
          final retryRes = await _btService.sendCommand("0100", timeout: const Duration(seconds: 4));

          if (ObdDecoder.isEcuResponding(retryRes)) {
            ecuConnected = true;
            _detectedProtocol = p['name']!;
            _parseSupportedPids(retryRes);
            debugPrint("[SCANNER_PROVIDER] ¡Conectado con éxito bajo protocolo: ${p['name']}!");
            break;
          }
        } catch (e) {
          debugPrint("[SCANNER_PROVIDER] Falló ${p['name']}: $e");
        }
      }
    }

    // SI NINGÚN PROTOCOLO RESPONDIÓ, SE INFORMA CLARAMENTE AL USUARIO
    if (!ecuConnected) {
      throw Exception(
        "No se pudo sincronizar con la computadora del motor (ECU).\n\n"
        "Comprobaciones necesarias:\n"
        "1. Asegúrate de que la llave esté en posición ON (ignición encendida) o con motor en marcha.\n"
        "2. Verifica que el puerto OBD2 tenga energía de 12V (fusible de cigarrera / OBD).\n"
        "3. Si tu auto tiene un protocolo específico, puedes seleccionarlo manualmente en la pantalla de opciones."
      );
    }

    // 7. Consultar nombre del protocolo detectado (ATDP)
    try {
      final dpRes = await _btService.sendCommand("ATDP", timeout: const Duration(seconds: 2));
      final parsed = ObdDecoder.cleanProtocolName(dpRes);
      if (parsed.isNotEmpty && parsed != "OBD-II Universal") {
        _detectedProtocol = parsed;
      }
    } catch (_) {}

    // 8. Identificar vehículo automáticamente mediante lectura de VIN (Modo 09 PID 02)
    await _detectVehicleIdentity();
  }

  void _parseSupportedPids(String rawResponse) {
    final pids = ObdDecoder.decodeSupportedPids(rawResponse);
    if (pids.isNotEmpty) {
      _supportedPids.clear();
      _supportedPids.addAll(pids);
      debugPrint("[SCANNER_PROVIDER] PIDs soportados por esta ECU: $_supportedPids");
    }
  }

  /// Consulta el VIN a la ECU (Modo 09 PID 02: 0902) y deduce Marca, Modelo y Año
  Future<void> _detectVehicleIdentity() async {
    try {
      debugPrint("[SCANNER_PROVIDER] Consultando VIN vehicular (0902)...");
      final vinRes = await _btService.sendCommand("0902", timeout: const Duration(seconds: 4));
      final extractedVin = VinDecoderService.extractVinFromRawResponse(vinRes);

      if (extractedVin != null && extractedVin.isNotEmpty) {
        debugPrint("[SCANNER_PROVIDER] VIN Detectado: $extractedVin");
        final identity = await VinDecoderService().identifyVehicle(extractedVin);
        _vehicleIdentity = identity;
        _vehicleDisplayName = identity.displayName;
        notifyListeners();
      } else {
        debugPrint("[SCANNER_PROVIDER] La ECU no reportó VIN (habitual en diésel pre-2008 / OBD2 básico)");
        if (_vehicleDisplayName.isEmpty || _vehicleDisplayName == "Vehículo Conectado") {
          _vehicleDisplayName = "Vehículo OBD-II Universal";
        }
      }
    } catch (e) {
      debugPrint("[SCANNER_PROVIDER] Error al consultar VIN: $e");
      if (_vehicleDisplayName.isEmpty || _vehicleDisplayName == "Vehículo Conectado") {
        _vehicleDisplayName = "Vehículo OBD-II Universal";
      }
    }
  }

  /// Inicia el bucle de polling secuencial adaptativo
  void _startPolling() {
    if (_isLoopRunning) return;
    _isLoopRunning = true;
    _runTelemetryLoop();
  }

  void _stopPolling() {
    _isLoopRunning = false;
  }

  Future<void> _runTelemetryLoop() async {
    int dtcCounter = 0;
    int batteryCounter = 0;
    int consecutiveFailures = 0;

    // Determinar qué PIDs consultar según el soporte real de la ECU
    final canQueryRpm = _supportedPids.isEmpty || _supportedPids.contains('0C');
    final canQuerySpeed = _supportedPids.isEmpty || _supportedPids.contains('0D');
    final canQueryTemp = _supportedPids.isEmpty || _supportedPids.contains('05');
    final canQueryLoad = _supportedPids.contains('04');
    final canQueryThrottle = _supportedPids.contains('11');
    final canQueryMaf = _supportedPids.contains('10');

    while (_isLoopRunning && _state == ScannerState.connected && _btService.isConnected) {
      try {
        // 1. Tacómetro (RPM - PID 010C)
        if (canQueryRpm) {
          final rpmRes = await _btService.sendCommand("010C", timeout: const Duration(seconds: 2));
          final parsed = _parseMetric(rpmRes);
          if (parsed != null) {
            consecutiveFailures = 0;
          } else if (rpmRes.toUpperCase().contains("NO DATA") || rpmRes.toUpperCase().contains("UNABLE")) {
            consecutiveFailures++;
          }
        }

        // 2. Velocímetro (PID 010D)
        if (canQuerySpeed) {
          final speedRes = await _btService.sendCommand("010D", timeout: const Duration(seconds: 2));
          _parseMetric(speedRes);
        }

        // 3. Temperatura de refrigerante (PID 0105)
        if (canQueryTemp) {
          final tempRes = await _btService.sendCommand("0105", timeout: const Duration(seconds: 2));
          _parseMetric(tempRes);
        }

        // 4. Métricas complementarias si están soportadas
        if (canQueryLoad) {
          final loadRes = await _btService.sendCommand("0104", timeout: const Duration(seconds: 2));
          _parseMetric(loadRes);
        }

        if (canQueryThrottle) {
          final throtRes = await _btService.sendCommand("0111", timeout: const Duration(seconds: 2));
          _parseMetric(throtRes);
        }

        if (canQueryMaf) {
          final mafRes = await _btService.sendCommand("0110", timeout: const Duration(seconds: 2));
          _parseMetric(mafRes);
        }

        // 5. Voltaje de Batería cada 10 ciclos
        batteryCounter++;
        if (batteryCounter >= 10) {
          batteryCounter = 0;
          try {
            final vRes = await _btService.sendCommand("ATRV", timeout: const Duration(seconds: 2));
            final volt = ObdDecoder.decodeVoltageResponse(vRes);
            if (volt != null) {
              _batteryVoltage = volt;
              _liveMetrics['BatteryVoltage'] = {
                'type': 'BatteryVoltage',
                'value': volt,
                'unit': 'V',
                'timestamp': DateTime.now().toIso8601String(),
              };
              notifyListeners();
            }
          } catch (_) {}
        }

        // 6. Códigos de Falla Confirmados (Modo 03) y Pendientes (Modo 07) cada 15 ciclos (~15 seg)
        dtcCounter++;
        if (dtcCounter >= 15) {
          dtcCounter = 0;
          // Códigos confirmados (Modo 03)
          final dtcRes = await _btService.sendCommand("03", timeout: const Duration(seconds: 3));
          _parseDtc(dtcRes);

          // Códigos pendientes (Modo 07)
          try {
            final pendingRes = await _btService.sendCommand("07", timeout: const Duration(seconds: 3));
            final pending = ObdDecoder.decodeDtcResponse(pendingRes);
            if (pending.isNotEmpty) {
              _pendingDtcs = pending;
              notifyListeners();
            }
          } catch (_) {}
        }

        // Si hay más de 12 fallos consecutivos, la ignición se apagó o se desconectó el cable
        if (consecutiveFailures >= 12) {
          _errorMessage = "Se perdió la comunicación con la ECU del motor (verifique switch de encendido).";
          _state = ScannerState.error;
          notifyListeners();
          break;
        }

        // Pausa entre ciclos adaptada para máxima fluidez y protección de batería
        await Future.delayed(const Duration(milliseconds: 350));
      } catch (e) {
        debugPrint("[SCANNER_PROVIDER] Advertencia en ciclo de lectura: $e");
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    _isLoopRunning = false;
  }

  Map<String, dynamic>? _parseMetric(String rawResponse) {
    final metric = ObdDecoder.decodeLiveResponse(rawResponse);
    if (metric != null) {
      _liveMetrics[metric['type']] = metric;
      notifyListeners();
      return metric;
    }
    return null;
  }

  void _parseDtc(String rawResponse) {
    final dtcs = ObdDecoder.decodeDtcResponse(rawResponse);
    if (dtcs.isNotEmpty) {
      _currentDtcs = dtcs;
      notifyListeners();
    }
  }

  /// Consulta manual inmediata de códigos de falla (Modo 03 y Modo 07)
  Future<void> checkDtcsNow() async {
    if (_state != ScannerState.connected) return;
    try {
      final res03 = await _btService.sendCommand("03", timeout: const Duration(seconds: 4));
      _parseDtc(res03);

      final res07 = await _btService.sendCommand("07", timeout: const Duration(seconds: 4));
      final pending = ObdDecoder.decodeDtcResponse(res07);
      _pendingDtcs = pending;
      notifyListeners();
    } catch (e) {
      debugPrint("[SCANNER_PROVIDER] Error al consultar DTCs: $e");
    }
  }

  /// Borra los códigos de falla (Modo 04) y apaga el testigo Check Engine (MIL)
  Future<bool> clearAllDtcs() async {
    if (_state != ScannerState.connected) return false;
    try {
      debugPrint("[SCANNER_PROVIDER] Enviando comando de borrado de códigos (Modo 04)...");
      final res = await _btService.sendCommand("04", timeout: const Duration(seconds: 5));
      if (res.toUpperCase().contains("OK") || !res.toUpperCase().contains("ERROR")) {
        _currentDtcs.clear();
        _pendingDtcs.clear();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("[SCANNER_PROVIDER] Error al borrar códigos: $e");
      return false;
    }
  }

  /// Desconectar escáner y limpiar estado
  Future<void> disconnect() async {
    _stopPolling();
    await _btService.disconnect();
    _state = ScannerState.disconnected;
    _liveMetrics.clear();
    _currentDtcs.clear();
    _pendingDtcs.clear();
    _supportedPids.clear();
    _vehicleIdentity = null;
    _batteryVoltage = null;
    _detectedProtocol = "Buscando protocolo...";
    _errorMessage = "";
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    _scanSub?.cancel();
    _connSub?.cancel();
    _dataSub?.cancel();
    _btService.dispose();
    super.dispose();
  }
}
