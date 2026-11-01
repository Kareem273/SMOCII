import 'package:flutter/foundation.dart';
import 'package:smokii/models/hardware_reading.dart';
import 'package:smokii/models/treatment_plan_model.dart';
import 'package:smokii/services/ai_agent_service.dart';

class TreatmentPlanService extends ChangeNotifier {
  static final TreatmentPlanService _instance =
      TreatmentPlanService._internal();
  factory TreatmentPlanService() => _instance;
  TreatmentPlanService._internal() {
    _initDefaultPlan();
  }

  late QuitPlan _currentPlan;
  QuitPlan get currentPlan => _currentPlan;

  void _initDefaultPlan() {
    final aiService = AiAgentService();
    final defaultSummary = aiService.generateSummary({});
    _currentPlan = aiService.buildPersonalizedPlan(defaultSummary);
  }

  void setCustomPlan(QuitPlan plan) {
    _currentPlan = plan;
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final index = _currentPlan.tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _currentPlan.tasks[index].isCompleted =
          !_currentPlan.tasks[index].isCompleted;
      notifyListeners();
    }
  }

  void handleHardwareIntervention(HardwareReading reading) {
    if (reading.level == NicotineLevel.high) {
      _currentPlan.hardwareFeedbackMessage =
          '⚠️ Spike Alert: Companion sensor detected ${reading.nicotinePpm} ppm nicotine. Protective craving protocol activated.';

      // Add emergency task if not already present
      final hasEmergency =
          _currentPlan.tasks.any((t) => t.id == 'task_emergency_spike');
      if (!hasEmergency) {
        _currentPlan.tasks.insert(
          0,
          PlanTask(
            id: 'task_emergency_spike',
            title: 'Urgent: 4-7-8 Breathing & 1-Hour Puff Pause',
            description:
                'Sensor detected peak nicotine. Pause all intake, drink 2 glasses of water, and allow levels to drop.',
            category: 'Behavior',
            timeOfDay: 'Immediate',
            isCompleted: false,
          ),
        );
      }
    } else if (reading.level == NicotineLevel.medium) {
      _currentPlan.hardwareFeedbackMessage =
          'ℹ️ Moderate Reading (${reading.nicotinePpm} ppm). Practice a 5-minute craving delay before your next session.';
    } else {
      _currentPlan.hardwareFeedbackMessage =
          '✅ Optimal Low Level (${reading.nicotinePpm} ppm). Great discipline! Sensor confirms low nicotine intake.';
    }

    notifyListeners();
  }

  // Pre-configured Treatment Templates
  List<Map<String, dynamic>> get availableTreatmentProtocols => [
        {
          'id': 'protocol_gradual',
          'title': 'Gradual Nicotine Step-Down',
          'duration': '4 Weeks',
          'description':
              'Slowly lowers daily puff counts and nicotine levels to minimize withdrawal symptoms.',
          'tag': 'Recommended for moderate to heavy smokers',
        },
        {
          'id': 'protocol_cold_turkey',
          'title': 'Target Quit-Day Protocol',
          'duration': '2 Weeks',
          'description':
              '14 days of psychological and behavioral preparation, followed by complete cessation on Day 15.',
          'tag': 'High motivation & clean break',
        },
        {
          'id': 'protocol_behavioral',
          'title': 'Trigger & Habit Replacement',
          'duration': '3 Weeks',
          'description':
              'Breaks subconscious associations between smoking and coffee, meals, driving, and social cues.',
          'tag': 'Ideal for habit and social smokers',
        },
      ];
}
