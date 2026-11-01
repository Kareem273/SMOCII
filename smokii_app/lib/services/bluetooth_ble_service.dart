import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DiscoveredBleDevice {
  final BluetoothDevice device;
  final String name;
  final String remoteId;
  final int rssi;
  final bool isSmociiHardware;

  DiscoveredBleDevice({
    required this.device,
    required this.name,
    required this.remoteId,
    required this.rssi,
    required this.isSmociiHardware,
  });

  String get signalStrength {
    if (rssi >= -60) return 'Strong';
    if (rssi >= -75) return 'Good';
    return 'Weak';
  }
}

class BluetoothBleService {
  static final BluetoothBleService _instance = BluetoothBleService._internal();
  factory BluetoothBleService() => _instance;
  BluetoothBleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  StreamSubscription<List<ScanResult>>? _scanSub;
  final List<DiscoveredBleDevice> _scannedDevices = [];
  List<DiscoveredBleDevice> get scannedDevices =>
      List.unmodifiable(_scannedDevices);

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // Check if Bluetooth adapter is supported & turned ON
  Future<bool> isBluetoothSupportedAndOn() async {
    try {
      if (kIsWeb) return false;
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return false;
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('Bluetooth check error: $e');
      return false;
    }
  }

  // Request to turn Bluetooth ON (Android)
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      debugPrint('Cannot turn on Bluetooth automatically: $e');
    }
  }

  // Real BLE Scan
  Future<void> startRealScan({
    required Function(List<DiscoveredBleDevice>) onDevicesUpdated,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    _scannedDevices.clear();
    _isScanning = true;

    try {
      // Ensure bluetooth is on
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        _isScanning = false;
        return;
      }

      await _scanSub?.cancel();

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final rawName = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown BLE Device');

          final isSmocii = rawName.toUpperCase().contains('SMOCII') ||
              rawName.toUpperCase().contains('ESP32') ||
              rawName.toUpperCase().contains('SENSOR');

          final id = r.device.remoteId.str;
          final existingIdx =
              _scannedDevices.indexWhere((d) => d.remoteId == id);

          final discovered = DiscoveredBleDevice(
            device: r.device,
            name: rawName,
            remoteId: id,
            rssi: r.rssi,
            isSmociiHardware: isSmocii,
          );

          if (existingIdx != -1) {
            _scannedDevices[existingIdx] = discovered;
          } else {
            _scannedDevices.add(discovered);
          }
        }

        // Sort so SMOCII and stronger signal appear first
        _scannedDevices.sort((a, b) {
          if (a.isSmociiHardware && !b.isSmociiHardware) return -1;
          if (!a.isSmociiHardware && b.isSmociiHardware) return 1;
          return b.rssi.compareTo(a.rssi);
        });

        onDevicesUpdated(List.from(_scannedDevices));
      });

      await FlutterBluePlus.startScan(timeout: timeout);
      _isScanning = false;
    } catch (e) {
      debugPrint('BLE Scan error: $e');
      _isScanning = false;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
    } catch (_) {}
    _isScanning = false;
  }

  // Connect to real hardware device
  Future<bool> connectToBleDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
      );
      _connectedDevice = device;

      // Discover GATT services on ESP32
      final services = await device.discoverServices();
      debugPrint('Discovered ${services.length} GATT services on ${device.platformName}');
      return true;
    } catch (e) {
      debugPrint('Error connecting to BLE device: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
  }
}
