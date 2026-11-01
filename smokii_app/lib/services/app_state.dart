import 'package:flutter/material.dart';
import 'package:smokii/models/hardware_reading.dart';
import 'package:smokii/models/treatment_plan_model.dart';
import 'package:smokii/services/hardware_service.dart';
import 'package:smokii/services/treatment_plan_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    _hardwareService = HardwareService();
    _treatmentPlanService = TreatmentPlanService();
    _treatmentPlanService.addListener(notifyListeners);
  }

  late final HardwareService _hardwareService;
  late final TreatmentPlanService _treatmentPlanService;

  String userName = 'Hussin';
  int streakDays = 14;
  int lowDaysCount = 6;
  String avgLevel = 'Medium';
  double thisWeekProgress = 0.43;
  bool isHardwareChecking = false;
  HardwareIntervention? activeIntervention;
  String? geminiApiKey;

  void setGeminiApiKey(String? key) {
    geminiApiKey = key?.trim().isEmpty == true ? null : key?.trim();
    notifyListeners();
  }

  HardwareReading get latestReading => _hardwareService.latestReading;
  List<HardwareReading> get readingHistory => _hardwareService.history;
  QuitPlan get currentPlan => _treatmentPlanService.currentPlan;
  bool get isDeviceConnected => _hardwareService.isDeviceConnected;
  String get connectedDeviceName =>
      _hardwareService.connectedDevice?.name ?? 'Not Connected';
  int get connectedDeviceBattery =>
      _hardwareService.connectedDevice?.batteryPercent ?? 0;

  Future<List<dynamic>> scanNearbyDevices() =>
      _hardwareService.scanForNearbyDevices();

  Future<void> connectToDevice(String deviceId) async {
    await _hardwareService.connectDevice(deviceId);
    notifyListeners();
  }

  void disconnectDevice() {
    _hardwareService.disconnectDevice();
    notifyListeners();
  }

  Future<HardwareReading> triggerHardwareCheck({double? simulatedPpm}) async {
    isHardwareChecking = true;
    notifyListeners();

    try {
      final reading = await _hardwareService.performReadingCheck(
        simulatedPpm: simulatedPpm,
      );

      // Evaluate intervention
      final intervention = _hardwareService.evaluateReading(reading);
      activeIntervention = intervention;

      // Update treatment plan based on hardware data
      _treatmentPlanService.handleHardwareIntervention(reading);

      // Adjust metrics
      if (reading.level == NicotineLevel.low) {
        lowDaysCount += 1;
        thisWeekProgress = (thisWeekProgress + 0.08).clamp(0.0, 1.0);
        streakDays += 1;
      } else if (reading.level == NicotineLevel.high) {
        thisWeekProgress = (thisWeekProgress - 0.04).clamp(0.1, 1.0);
      }

      isHardwareChecking = false;
      notifyListeners();
      return reading;
    } catch (e) {
      isHardwareChecking = false;
      notifyListeners();
      rethrow;
    }
  }

  void dismissIntervention() {
    activeIntervention = null;
    notifyListeners();
  }

  void toggleTask(String taskId) {
    _treatmentPlanService.toggleTaskCompletion(taskId);
    notifyListeners();
  }

  void applyGeneratedPlan(QuitPlan newPlan) {
    _treatmentPlanService.setCustomPlan(newPlan);
    notifyListeners();
  }
}
