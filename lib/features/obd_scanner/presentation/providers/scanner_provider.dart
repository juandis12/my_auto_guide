import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/obd_bluetooth_service.dart';
import '../../data/obd_decoder.dart';

enum ScannerState {
  disconnected,
  scanning,
  connecting,
  initializing,
  connected,
  error,
}

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

  // Datos decodificados en tiempo real
  final Map<String, dynamic> _liveMetrics = {};
  Map<String, dynamic> get liveMetrics => Map.unmodifiable(_liveMetrics);

  List<String> _currentDtcs = [];
  List<String> get currentDtcs => List.unmodifiable(_currentDtcs);

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<String>? _dataSub;

  bool _isLoopRunning = false;

  ScannerProvider() {
    _initListeners();
  }

  void _initListeners() {
    // 1. Escuchar dispositivos encontrados durante el escaneo
    _scanSub = _btService.scanResults.listen((results) {
      _devices = results.where((r) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;
        return name.trim().isNotEmpty;
      }).toList();
      notifyListeners();
    });

    // 2. Escuchar cambios de estado de la conexión BLE
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

    // 3. Escuchar datos crudos para depuración
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

      // Fase 1: Conexión BLE y descubrimiento de características
      await _btService.connectToDevice(device);

      // Fase 2: Inicialización ELM327 y protocolo vehicular
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
      _errorMessage = "Fallo de conexión o handshake: $e";
      notifyListeners();
    }
  }

  /// Secuencia estandarizada de inicialización ELM327 / OBD2
  Future<void> _initializeElmProtocol() async {
    try {
      // 1. Reset del ELM327
      await _btService.sendCommand("ATZ", timeout: const Duration(seconds: 3));
      await Future.delayed(const Duration(milliseconds: 600));

      // 2. Desactivar Eco para evitar recibir el mismo comando enviado
      await _btService.sendCommand("ATE0", timeout: const Duration(seconds: 2));

      // 3. Desactivar Linefeeds automáticos
      await _btService.sendCommand("ATL0", timeout: const Duration(seconds: 2));

      // 4. Desactivar espacios entre bytes para simplificar parsing
      await _btService.sendCommand("ATS0", timeout: const Duration(seconds: 2));

      // 5. Desactivar cabeceras adicionales (headers off)
      await _btService.sendCommand("ATH0", timeout: const Duration(seconds: 2));

      // 6. Configurar protocolo en Auto (ATSP0)
      await _btService.sendCommand("ATSP0", timeout: const Duration(seconds: 2));

      // 7. Test de conexión con la ECU mediante consulta de PIDs soportados (0100)
      // Esta consulta activa la búsqueda y sincronización de protocolo en el vehículo
      final probeResult = await _btService.sendCommand("0100", timeout: const Duration(seconds: 6));
      
      final upperProbe = probeResult.toUpperCase();
      if (upperProbe.contains("UNABLE") || upperProbe.contains("BUS INIT: ... ERROR")) {
        // En caso de que el Spark requiera forzar el protocolo ISO 15765-4 CAN (11 bit ID, 500 kbaud)
        await _btService.sendCommand("ATSP6", timeout: const Duration(seconds: 2));
        await _btService.sendCommand("0100", timeout: const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint("[SCANNER_PROVIDER] Error en secuencia init: $e");
    }
  }

  /// Inicia el bucle de polling secuencial de telemetría (Half-Duplex)
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

    while (_isLoopRunning && _state == ScannerState.connected && _btService.isConnected) {
      try {
        // 1. Pedir RPM (PID 010C)
        final rpmRes = await _btService.sendCommand("010C", timeout: const Duration(seconds: 2));
        _parseMetric(rpmRes);

        // 2. Pedir Velocidad (PID 010D)
        final speedRes = await _btService.sendCommand("010D", timeout: const Duration(seconds: 2));
        _parseMetric(speedRes);

        // 3. Pedir Temperatura del refrigerante (PID 0105)
        final tempRes = await _btService.sendCommand("0105", timeout: const Duration(seconds: 2));
        _parseMetric(tempRes);

        // 4. Cada 15 ciclos (~15 segundos) pedir Códigos de Falla (Modo 03)
        dtcCounter++;
        if (dtcCounter >= 15) {
          dtcCounter = 0;
          final dtcRes = await _btService.sendCommand("03", timeout: const Duration(seconds: 3));
          _parseDtc(dtcRes);
        }

        // Intervalo entre rondas de lectura para no saturar el bus CAN ni drenar batería
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint("[SCANNER_PROVIDER] Advertencia en ciclo de lectura: $e");
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    _isLoopRunning = false;
  }

  void _parseMetric(String rawResponse) {
    final metric = ObdDecoder.decodeLiveResponse(rawResponse);
    if (metric != null) {
      _liveMetrics[metric['type']] = metric;
      notifyListeners();
    }
  }

  void _parseDtc(String rawResponse) {
    final dtcs = ObdDecoder.decodeDtcResponse(rawResponse);
    if (dtcs.isNotEmpty) {
      _currentDtcs = dtcs;
      notifyListeners();
    }
  }

  /// Forzar consulta manual de Códigos de Falla
  Future<void> checkDtcsNow() async {
    if (_state != ScannerState.connected) return;
    try {
      final res = await _btService.sendCommand("03", timeout: const Duration(seconds: 4));
      _parseDtc(res);
    } catch (e) {
      debugPrint("[SCANNER_PROVIDER] Error al consultar DTCs: $e");
    }
  }

  /// Desconectar escáner y limpiar estado
  Future<void> disconnect() async {
    _stopPolling();
    await _btService.disconnect();
    _state = ScannerState.disconnected;
    _liveMetrics.clear();
    _currentDtcs.clear();
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
