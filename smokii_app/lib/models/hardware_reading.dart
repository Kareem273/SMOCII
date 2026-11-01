import 'package:flutter/material.dart';
import 'package:smokii/const/constant.dart';

enum NicotineLevel { low, medium, high }

class HardwareReading {
  final String id;
  final DateTime timestamp;
  final double nicotinePpm;
  final NicotineLevel level;
  final int sensorBattery;
  final int puffsDetected;
  final int sessionDurationSeconds;
  final String deviceStatus;
  final String notes;

  const HardwareReading({
    required this.id,
    required this.timestamp,
    required this.nicotinePpm,
    required this.level,
    required this.sensorBattery,
    required this.puffsDetected,
    required this.sessionDurationSeconds,
    required this.deviceStatus,
    this.notes = '',
  });

  String get levelLabel {
    switch (level) {
      case NicotineLevel.low:
        return 'Low';
      case NicotineLevel.medium:
        return 'Medium';
      case NicotineLevel.high:
        return 'High';
    }
  }

  Color get levelColor {
    switch (level) {
      case NicotineLevel.low:
        return successColor;
      case NicotineLevel.medium:
        return warningColor;
      case NicotineLevel.high:
        return dangerColor;
    }
  }

  Color get levelBgColor {
    switch (level) {
      case NicotineLevel.low:
        return const Color(0xFFC8E6C9);
      case NicotineLevel.medium:
        return const Color(0xFFFFE0B2);
      case NicotineLevel.high:
        return const Color(0xFFFFCDD2);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'nicotinePpm': nicotinePpm,
        'level': level.name,
        'sensorBattery': sensorBattery,
        'puffsDetected': puffsDetected,
        'sessionDurationSeconds': sessionDurationSeconds,
        'deviceStatus': deviceStatus,
        'notes': notes,
      };

  factory HardwareReading.fromJson(Map<String, dynamic> json) {
    return HardwareReading(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      nicotinePpm: (json['nicotinePpm'] as num).toDouble(),
      level: NicotineLevel.values.byName(json['level'] as String),
      sensorBattery: (json['sensorBattery'] as num).toInt(),
      puffsDetected: (json['puffsDetected'] as num).toInt(),
      sessionDurationSeconds: (json['sessionDurationSeconds'] as num).toInt(),
      deviceStatus: json['deviceStatus'] as String? ?? 'Connected',
      notes: json['notes'] as String? ?? '',
    );
  }
}
