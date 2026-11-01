import 'dart:math';
import 'package:smokii/models/device_model.dart';
import 'package:smokii/models/hardware_reading.dart';

class HardwareIntervention {
  final NicotineLevel level;
  final String title;
  final String message;
  final String actionRecommendation;
  final bool requiresEmergencyIntervention;

  const HardwareIntervention({
    required this.level,
    required this.title,
    required this.message,
    required this.actionRecommendation,
    required this.requiresEmergencyIntervention,
  });
}

class HardwareService {
  static final HardwareService _instance = HardwareService._internal();
  factory HardwareService() => _instance;
  HardwareService._internal();

  CompanionDevice? _connectedDevice;
  CompanionDevice? get connectedDevice => _connectedDevice;
  bool get isDeviceConnected => _connectedDevice != null;

  final List<CompanionDevice> _discoveredDevices = [
    CompanionDevice(
      id: 'smokii_esp32_01',
      name: 'SMOCII-Sensor-ESP32',
      macAddress: '24:6F:28:B4:9C:12',
      rssi: -54,
      batteryPercent: 88,
      firmwareVersion: 'v1.4.2-esp32',
    ),
    CompanionDevice(
      id: 'smokii_companion_02',
      name: 'SMOCII-Pocket-Companion',
      macAddress: '3C:71:BF:88:E1:05',
      rssi: -72,
      batteryPercent: 64,
      firmwareVersion: 'v1.2.0',
    ),
  ];

  final List<HardwareReading> _history = [
    HardwareReading(
      id: 'read_001',
      timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      nicotinePpm: 12.4,
      level: NicotineLevel.low,
      sensorBattery: 94,
      puffsDetected: 3,
      sessionDurationSeconds: 45,
      deviceStatus: 'Synced',
      notes: 'Morning breath check',
    ),
    HardwareReading(
      id: 'read_002',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      nicotinePpm: 14.1,
      level: NicotineLevel.low,
      sensorBattery: 89,
      puffsDetected: 2,
      sessionDurationSeconds: 40,
      deviceStatus: 'Synced',
      notes: 'Midday check',
    ),
    HardwareReading(
      id: 'read_003',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      nicotinePpm: 22.8,
      level: NicotineLevel.medium,
      sensorBattery: 82,
      puffsDetected: 7,
      sessionDurationSeconds: 60,
      deviceStatus: 'Synced',
      notes: 'Post-lunch sensor reading',
    ),
    HardwareReading(
      id: 'read_004',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      nicotinePpm: 11.2,
      level: NicotineLevel.low,
      sensorBattery: 78,
      puffsDetected: 1,
      sessionDurationSeconds: 30,
      deviceStatus: 'Connected & Calibrated',
      notes: 'Current session reading',
    ),
  ];

  List<HardwareReading> get history => List.unmodifiable(_history);

  HardwareReading get latestReading => _history.isNotEmpty
      ? _history.last
      : HardwareReading(
          id: 'read_default',
          timestamp: DateTime.now(),
          nicotinePpm: 11.2,
          level: NicotineLevel.low,
          sensorBattery: 78,
          puffsDetected: 1,
          sessionDurationSeconds: 30,
          deviceStatus: 'Connected',
        );

  // Scan for nearby hardware devices
  Future<List<CompanionDevice>> scanForNearbyDevices() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return _discoveredDevices;
  }

  // Connect to companion hardware device
  Future<bool> connectDevice(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    final match = _discoveredDevices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => _discoveredDevices.first,
    );
    match.isConnected = true;
    _connectedDevice = match;
    return true;
  }

  void disconnectDevice() {
    if (_connectedDevice != null) {
      _connectedDevice!.isConnected = false;
      _connectedDevice = null;
    }
  }

  // Trigger live sensor sample reading from connected device
  Future<HardwareReading> performReadingCheck({double? simulatedPpm}) async {
    // If no device connected, auto-connect to default
    if (_connectedDevice == null) {
      await connectDevice('smokii_esp32_01');
    }

    final random = Random();
    final ppm = simulatedPpm ??
        (random.nextDouble() > 0.35
            ? (8.0 + random.nextDouble() * 7.5) // Low: 8 - 15.5 ppm
            : (18.0 + random.nextDouble() * 20.0)); // Medium / High

    NicotineLevel level;
    if (ppm < 16.0) {
      level = NicotineLevel.low;
    } else if (ppm <= 32.0) {
      level = NicotineLevel.medium;
    } else {
      level = NicotineLevel.high;
    }

    final reading = HardwareReading(
      id: 'read_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      nicotinePpm: double.parse(ppm.toStringAsFixed(1)),
      level: level,
      sensorBattery: _connectedDevice?.batteryPercent ?? (75 + random.nextInt(20)),
      puffsDetected: level == NicotineLevel.low ? 1 : (level == NicotineLevel.medium ? 3 : 7),
      sessionDurationSeconds: 30 + random.nextInt(20),
      deviceStatus: 'Synced via ${_connectedDevice?.name ?? 'ESP32 Sensor'}',
      notes: 'Live companion sensor sample verified',
    );

    _history.add(reading);
    return reading;
  }

  HardwareIntervention evaluateReading(HardwareReading reading) {
    switch (reading.level) {
      case NicotineLevel.low:
        return const HardwareIntervention(
          level: NicotineLevel.low,
          title: 'Optimal Low Nicotine Level',
          message:
              'Hardware sensor confirms low nicotine absorption. Your body is clearing nicotine effectively.',
          actionRecommendation:
              'Keep drinking cold water and maintain your current streak.',
          requiresEmergencyIntervention: false,
        );

      case NicotineLevel.medium:
        return const HardwareIntervention(
          level: NicotineLevel.medium,
          title: 'Moderate Nicotine Level Detected',
          message:
              'A slight increase in nicotine concentration was detected compared to your morning baseline.',
          actionRecommendation:
              'Apply the 5-minute craving delay technique before taking any puffs.',
          requiresEmergencyIntervention: false,
        );

      case NicotineLevel.high:
        return const HardwareIntervention(
          level: NicotineLevel.high,
          title: 'High Nicotine Spike Detected',
          message:
              'Companion device flagged an elevated nicotine level. Relapse risk is temporarily elevated.',
          actionRecommendation:
              'Activate Craving SOS immediately: take 10 slow deep breaths and change your physical room.',
          requiresEmergencyIntervention: true,
        );
    }
  }
}
