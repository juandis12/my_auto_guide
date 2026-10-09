import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ObdBluetoothService {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _charSubscription;

  // UUID estándar de puerto serie Bluetooth LE (usado por muchos OBD2 clónicos BLE)
  // Nota: ThinkDiag/ScanMate puede usar UUIDs específicos, empezaremos buscando
  // el servicio por defecto, o listaremos todos para debugear.
  final String _sppServiceUuid = "0000ffe0-0000-1000-8000-00805f9b34fb";
  final String _sppCharUuid = "0000ffe1-0000-1000-8000-00805f9b34fb";

  // Stream para enviar los dispositivos encontrados a la UI
  final StreamController<List<ScanResult>> _scanResultsController = StreamController.broadcast();
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  // Stream para el estado de la conexión
  final StreamController<BluetoothConnectionState> _connectionStateController = StreamController.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  // Stream para los datos crudos que vienen del carro
  final StreamController<String> _obdDataController = StreamController.broadcast();
  Stream<String> get obdDataStream => _obdDataController.stream;

  BluetoothCharacteristic? _writeCharacteristic;

  Future<void> startScan() async {
    // Verificar si el Bluetooth está encendido
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
      throw Exception("El Bluetooth está apagado");
    }

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResultsController.add(results);
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    _connectedDevice = device;

    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.connected) {
        _discoverServices(device);
      }
    });

    await device.connect(autoConnect: false, license: License.nonprofit);
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    
    // Buscar la característica de escritura/lectura
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        // Guardamos la primera que tenga propiedades de escritura y notificación
        // (Esto lo refinaremos cuando leamos el UUID exacto del ScanMate)
        if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
             _writeCharacteristic = characteristic;
             await characteristic.setNotifyValue(true);
             _charSubscription = characteristic.lastValueStream.listen((value) {
                // Convertir bytes a ASCII
                String data = String.fromCharCodes(value);
                _obdDataController.add(data);
             });
             return;
          }
        }
      }
    }
  }

  Future<void> sendCommand(String command) async {
    if (_writeCharacteristic == null) {
      throw Exception("No hay característica de escritura disponible.");
    }
    // OBD2 requiere retorno de carro al final (\r)
    List<int> bytes = ("$command\r").codeUnits;
    await _writeCharacteristic!.write(bytes, withoutResponse: false);
  }

  Future<void> disconnect() async {
    _scanSubscription?.cancel();
    _charSubscription?.cancel();
    _connectionSubscription?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }
}
