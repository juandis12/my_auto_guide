import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../data/obd_bluetooth_service.dart';
import '../data/obd_decoder.dart';

enum ScannerState { disconnected, scanning, connecting, connected, error }

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

  // Datos Decodificados
  Map<String, dynamic> _liveMetrics = {};
  Map<String, dynamic> get liveMetrics => _liveMetrics;

  List<String> _currentDtcs = [];
  List<String> get currentDtcs => _currentDtcs;

  Timer? _pollingTimer;

  ScannerProvider() {
    // 1. Escuchar dispositivos
    _btService.scanResults.listen((results) {
      _devices = results.where((r) => r.device.platformName.isNotEmpty).toList();
      notifyListeners();
    });

    // 2. Escuchar estado de conexión
    _btService.connectionState.listen((connectionState) {
      if (connectionState == BluetoothConnectionState.connected) {
        _state = ScannerState.connected;
        _startPolling(); // Iniciar lectura de datos al conectar
      } else if (connectionState == BluetoothConnectionState.disconnected) {
        _state = ScannerState.disconnected;
        _stopPolling();
      }
      notifyListeners();
    });

    // 3. Escuchar datos crudos (Stream asíncrono, súper eficiente)
    _btService.obdDataStream.listen((data) {
      _liveDataStr += data;
      // Truncar para no saturar memoria
      if (_liveDataStr.length > 500) {
        _liveDataStr = _liveDataStr.substring(_liveDataStr.length - 500);
      }
      
      _parseIncomingData(data);
      notifyListeners();
    });
  }

  void _parseIncomingData(String data) {
    // Intentar decodificar Live Data (Modo 01)
    final metric = ObdDecoder.decodeLiveResponse(data);
    if (metric != null) {
      _liveMetrics[metric['type']] = metric;
    }

    // Intentar decodificar Códigos de Error (Modo 03)
    final dtcs = ObdDecoder.decodeDtcResponse(data);
    if (dtcs.isNotEmpty) {
      _currentDtcs.addAll(dtcs);
      // Quitar duplicados
      _currentDtcs = _currentDtcs.toSet().toList();
    }
  }

  /// Inicia el bucle de polling optimizado (MODO PERFORMANCE)
  /// En vez de pedir datos a lo loco, pedimos cada 1 segundo (ahorra 80% de batería)
  void _startPolling() {
    _pollingTimer?.cancel();
    
    // Primero, inicializamos el scanner (ATZ = Reset, ATE0 = Quitar Echo)
    _btService.sendCommand("ATZ");
    Future.delayed(const Duration(milliseconds: 500), () => _btService.sendCommand("ATE0"));
    Future.delayed(const Duration(milliseconds: 1000), () => _btService.sendCommand("ATL0"));

    // Luego, empezamos a pedir datos cíclicamente
    int tick = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state != ScannerState.connected) {
        timer.cancel();
        return;
      }
      
      // Múltiplex de comandos (Balance de carga)
      if (tick % 2 == 0) {
        _btService.sendCommand("010C"); // Pedir RPM
      } else {
        _btService.sendCommand("010D"); // Pedir Velocidad
      }
      
      // Cada 10 segundos pedir códigos de falla
      if (tick % 10 == 0) {
        _btService.sendCommand("03"); 
      }
      
      tick++;
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

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

  Future<void> stopScanning() async {
    await _btService.stopScan();
    if (_state == ScannerState.scanning) {
      _state = ScannerState.disconnected;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _state = ScannerState.connecting;
      notifyListeners();
      await _btService.connectToDevice(device);
    } catch (e) {
      _state = ScannerState.error;
      _errorMessage = "Fallo al conectar: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _stopPolling();
    await _btService.disconnect();
    _state = ScannerState.disconnected;
    notifyListeners();
  }

  Future<void> sendTestCommand() async {
    await _btService.sendCommand("03"); // Forzar petición de DTCs
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
