class CompanionDevice {
  final String id;
  final String name;
  final String macAddress;
  final int rssi; // Signal strength in dBm, e.g. -58
  final int batteryPercent;
  final String firmwareVersion;
  bool isConnected;

  CompanionDevice({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.rssi,
    required this.batteryPercent,
    required this.firmwareVersion,
    this.isConnected = false,
  });

  String get signalStrength {
    if (rssi >= -60) return 'Strong';
    if (rssi >= -75) return 'Good';
    return 'Weak';
  }
}
