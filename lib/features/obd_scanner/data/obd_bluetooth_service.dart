import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Servicio de comunicación Bluetooth Low Energy (BLE) para escáneres OBD-II / ELM327
/// Compatible con ScanMate (ThinkDiag), ELM327 v1.5/v2.1 y clones estándar BLE.
class ObdBluetoothService {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  // Características de E/S
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  // Controladores de streams
  final StreamController<List<ScanResult>> _scanResultsController = StreamController.broadcast();
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  final StreamController<BluetoothConnectionState> _connectionStateController = StreamController.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  final StreamController<String> _obdDataController = StreamController.broadcast();
  Stream<String> get obdDataStream => _obdDataController.stream;

  final StreamController<String> _debugLogController = StreamController.broadcast();
  Stream<String> get debugLogStream => _debugLogController.stream;

  // Buffer y sincronización de comandos ELM327 (Half-Duplex)
  final StringBuffer _rxBuffer = StringBuffer();
  Completer<String>? _currentCommandCompleter;
  final List<_QueuedCommand> _commandQueue = [];
  bool _isProcessingQueue = false;

  bool get isConnected => _connectedDevice != null && _writeCharacteristic != null && _notifyCharacteristic != null;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  void _log(String message) {
    debugPrint("[OBD_SERVICE] $message");
    if (!_debugLogController.isClosed) {
      _debugLogController.add(message);
    }
  }

  /// Inicia el escaneo de dispositivos BLE cercanos
  Future<void> startScan() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState == BluetoothAdapterState.off) {
      throw Exception("El Bluetooth está apagado en el dispositivo");
    }

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!_scanResultsController.isClosed) {
        _scanResultsController.add(results);
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );
  }

  /// Detiene el escaneo
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      _log("Error al detener escaneo: $e");
    }
  }

  /// Conecta con el dispositivo OBD-II seleccionado
  Future<bool> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    _connectedDevice = device;

    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(state);
      }
      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnectCleanup();
      }
    });

    try {
      _log("Conectando a ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}...");
      await device.connect(
        timeout: const Duration(seconds: 12),
        autoConnect: false,
        license: License.nonprofit,
      );

      // Solicitar MTU ampliado para evitar fragmentación excesiva de paquetes
      try {
        _log("Negociando MTU...");
        await device.requestMtu(512);
      } catch (e) {
        _log("Advertencia de MTU (no crítico): $e");
      }

      // Descubrir servicios y características UART/SPP
      final discovered = await _discoverServicesAndCharacteristics(device);
      if (!discovered) {
        throw Exception("No se encontraron canales de lectura/escritura compatibles con OBD2 en este dispositivo.");
      }

      _log("Conexión y mapeo de características completado con éxito.");
      return true;
    } catch (e) {
      _log("Fallo al conectar dispositivo: $e");
      await disconnect();
      rethrow;
    }
  }

  /// Identifica las características de escritura y notificación del dispositivo
  Future<bool> _discoverServicesAndCharacteristics(BluetoothDevice device) async {
    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    final services = await device.discoverServices();
    _log("Descubiertos ${services.length} servicios GATT");

    // UUIDs conocidos de OBD2 / ELM327 BLE / ThinkDiag / ScanMate
    const primaryServiceUuids = [
      "fff0", // ThinkDiag / ScanMate / Clones OBD BLE
      "ffe0", // Vgate / ELM327 BLE estándar
      "fee0", // Clones OBD BLE
      "6e400001-b5a3-f393-e0a9-e50e24dcca9e", // Nordic UART
      "49535343-fe7d-4ae5-8fa9-9fafd205e455", // ISSC Transparent Serial
    ];

    // PASO 1: Intentar emparejar con servicios UART/OBD conocidos
    for (final service in services) {
      final sUuid = service.uuid.toString().toLowerCase();
      final isKnown = primaryServiceUuids.any((known) => sUuid.contains(known));

      if (isKnown) {
        _log("Servicio conocido detectado: $sUuid");
        for (final char in service.characteristics) {
          final cUuid = char.uuid.toString().toLowerCase();
          
          // Específico ScanMate/ThinkDiag: fff2 = Write, fff1 = Notify
          if (cUuid.contains("fff2") || (char.properties.write || char.properties.writeWithoutResponse)) {
            _writeCharacteristic ??= char;
          }
          if (cUuid.contains("fff1") || (char.properties.notify || char.properties.indicate)) {
            _notifyCharacteristic ??= char;
          }
        }
      }
    }

    // PASO 2: Heurística universal si el paso 1 no encontró ambas características
    if (_writeCharacteristic == null || _notifyCharacteristic == null) {
      _log("Búsqueda heurística universal de características BLE...");
      for (final service in services) {
        for (final char in service.characteristics) {
          final canWrite = char.properties.write || char.properties.writeWithoutResponse;
          final canNotify = char.properties.notify || char.properties.indicate;

          // Si una característica soporta ambas (como en ffe1)
          if (canWrite && canNotify) {
            _writeCharacteristic ??= char;
            _notifyCharacteristic ??= char;
            break;
          }

          if (canWrite && _writeCharacteristic == null) {
            _writeCharacteristic = char;
          }
          if (canNotify && _notifyCharacteristic == null) {
            _notifyCharacteristic = char;
          }
        }
        if (_writeCharacteristic != null && _notifyCharacteristic != null) break;
      }
    }

    if (_writeCharacteristic == null || _notifyCharacteristic == null) {
      _log("ERROR: Fallo al mapear características. Write: $_writeCharacteristic, Notify: $_notifyCharacteristic");
      return false;
    }

    _log("Mapeado: Write=${_writeCharacteristic!.uuid}, Notify=${_notifyCharacteristic!.uuid}");

    // Habilitar notificaciones para escuchar respuestas del vehículo
    await _notifyCharacteristic!.setNotifyValue(true);
    _notifySubscription?.cancel();
    _notifySubscription = _notifyCharacteristic!.onValueReceived.listen(_handleIncomingBytes);

    return true;
  }

  /// Procesa los paquetes entrantes desde el adaptador OBD
  void _handleIncomingBytes(List<int> bytes) {
    if (bytes.isEmpty) return;

    // Convertir bytes recibidos a texto ASCII
    final chunk = utf8.decode(bytes, allowMalformed: true);
    _rxBuffer.write(chunk);

    if (!_obdDataController.isClosed) {
      _obdDataController.add(chunk);
    }

    final accumulated = _rxBuffer.toString();

    // El ELM327 finaliza cada comando enviando el prompt '>'
    if (accumulated.contains('>')) {
      final responseText = accumulated;
      _rxBuffer.clear();

      if (_currentCommandCompleter != null && !_currentCommandCompleter!.isCompleted) {
        _currentCommandCompleter!.complete(responseText);
      }
    }
  }

  /// Envía un comando OBD-II y espera la respuesta completa hasta recibir el prompt '>'
  Future<String> sendCommand(
    String command, {
    Duration timeout = const Duration(seconds: 4),
  }) {
    if (!isConnected) {
      return Future.error(Exception("No hay conexión activa con el escáner"));
    }

    final completer = Completer<String>();
    _commandQueue.add(_QueuedCommand(
      command: command.trim(),
      timeout: timeout,
      completer: completer,
    ));

    _processQueue();
    return completer.future;
  }

  /// Cola de ejecución Half-Duplex para comandos serie OBD2
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _commandQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_commandQueue.isNotEmpty) {
      final item = _commandQueue.removeAt(0);

      try {
        final result = await _executeSingleCommand(item.command, item.timeout);
        if (!item.completer.isCompleted) {
          item.completer.complete(result);
        }
      } catch (e) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(e);
        }
      }

      // Pequeño descanso entre comandos para permitir a la ECU procesar (20ms)
      await Future.delayed(const Duration(milliseconds: 20));
    }

    _isProcessingQueue = false;
  }

  Future<String> _executeSingleCommand(String command, Duration timeout) async {
    if (_writeCharacteristic == null) {
      throw Exception("No hay característica de escritura configurada");
    }

    _rxBuffer.clear();
    _currentCommandCompleter = Completer<String>();

    // Todos los comandos OBD2/ELM327 requieren terminar con retorno de carro (\r)
    final formatted = command.endsWith('\r') ? command : '$command\r';
    final bytes = ascii.encode(formatted);

    final useWithoutResponse = _writeCharacteristic!.properties.writeWithoutResponse &&
        !_writeCharacteristic!.properties.write;

    _log("TX -> $command");
    await _writeCharacteristic!.write(bytes, withoutResponse: useWithoutResponse);

    // Esperar respuesta con timeout de seguridad
    Timer? timeoutTimer;
    timeoutTimer = Timer(timeout, () {
      if (_currentCommandCompleter != null && !_currentCommandCompleter!.isCompleted) {
        final partial = _rxBuffer.toString();
        _rxBuffer.clear();
        _log("Timeout esperando respuesta para: $command. Parcial: $partial");
        _currentCommandCompleter!.complete(partial);
      }
    });

    final response = await _currentCommandCompleter!.future;
    timeoutTimer.cancel();
    _currentCommandCompleter = null;

    _log("RX <- ${response.replaceAll('\r', '\\r').replaceAll('\n', '\\n')}");
    return response;
  }

  void _handleDisconnectCleanup() {
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _notifySubscription?.cancel();
    _notifySubscription = null;
    _rxBuffer.clear();

    if (_currentCommandCompleter != null && !_currentCommandCompleter!.isCompleted) {
      _currentCommandCompleter!.completeError(Exception("Dispositivo desconectado"));
      _currentCommandCompleter = null;
    }

    for (final item in _commandQueue) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(Exception("Dispositivo desconectado"));
      }
    }
    _commandQueue.clear();
    _isProcessingQueue = false;
  }

  /// Desconecta el dispositivo y libera todos los recursos
  Future<void> disconnect() async {
    _handleDisconnectCleanup();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        _log("Error al desconectar: $e");
      }
      _connectedDevice = null;
    }
  }

  void dispose() {
    disconnect();
    _scanResultsController.close();
    _connectionStateController.close();
    _obdDataController.close();
    _debugLogController.close();
  }
}

class _QueuedCommand {
  final String command;
  final Duration timeout;
  final Completer<String> completer;

  _QueuedCommand({
    required this.command,
    required this.timeout,
    required this.completer,
  });
}
