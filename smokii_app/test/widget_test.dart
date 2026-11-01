import 'package:flutter_test/flutter_test.dart';
import 'package:smokii/main.dart';
import 'package:smokii/models/assessment_model.dart';
import 'package:smokii/models/hardware_reading.dart';
import 'package:smokii/services/ai_agent_service.dart';
import 'package:smokii/services/hardware_service.dart';
import 'package:smokii/services/treatment_plan_service.dart';

void main() {
  group('SMOCII AI Assessment Tests', () {
    test('AI Agent triggers adaptive follow-up for early morning cravings', () {
      final aiService = AiAgentService();
      final answers = <String, AssessmentAnswer>{
        'q_morning_timing': const AssessmentAnswer(
          questionId: 'q_morning_timing',
          value: 'm_5_min',
          displayLabel: 'Within 5 minutes',
        ),
      };

      final adaptiveQ = aiService.evaluateNextAdaptiveQuestion(answers);
      expect(adaptiveQ, isNotNull);
      expect(adaptiveQ!.isAiFollowUp, isTrue);
      expect(adaptiveQ.id, equals('q_ai_morning_routine'));
    });

    test('AI Agent generates personalized summary and tailored treatment plan', () {
      final aiService = AiAgentService();
      final answers = <String, AssessmentAnswer>{
        'q_daily_consumption': const AssessmentAnswer(
          questionId: 'q_daily_consumption',
          value: 'c_11_20',
          displayLabel: '11 - 20',
        ),
        'q_morning_timing': const AssessmentAnswer(
          questionId: 'q_morning_timing',
          value: 'm_5_min',
          displayLabel: 'Within 5 minutes',
        ),
        'q_primary_triggers': const AssessmentAnswer(
          questionId: 'q_primary_triggers',
          value: 't_stress',
          displayLabel: 'Stress',
        ),
      };

      final summary = aiService.generateSummary(answers);
      expect(summary.dependenceLevel, contains('Dependence'));
      expect(summary.primaryTriggers, isNotEmpty);

      final plan = aiService.buildPersonalizedPlan(summary);
      expect(plan.phases.length, equals(4));
      expect(plan.tasks.length, greaterThanOrEqualTo(3));
    });
  });

  group('SMOCII Hardware & Treatment Plan Tests', () {
    test('Hardware reading spike activates High Nicotine Emergency Protocol', () {
      final hardwareService = HardwareService();
      final planService = TreatmentPlanService();

      final highReading = HardwareReading(
        id: 'test_high_1',
        timestamp: DateTime.now(),
        nicotinePpm: 42.5,
        level: NicotineLevel.high,
        sensorBattery: 90,
        puffsDetected: 9,
        sessionDurationSeconds: 45,
        deviceStatus: 'Spike Detected',
      );

      final intervention = hardwareService.evaluateReading(highReading);
      expect(intervention.requiresEmergencyIntervention, isTrue);

      planService.handleHardwareIntervention(highReading);
      expect(planService.currentPlan.hardwareFeedbackMessage, contains('Spike Alert'));
      expect(
        planService.currentPlan.tasks.any((t) => t.id == 'task_emergency_spike'),
        isTrue,
      );
    });
  });

  group('SMOCII Empathetic Human-Like AI Chatbot Tests', () {
    final aiService = AiAgentService();
    final dummyReading = HardwareReading(
      id: 'test_read',
      timestamp: DateTime.now(),
      nicotinePpm: 8.8,
      level: NicotineLevel.low,
      sensorBattery: 88,
      puffsDetected: 1,
      sessionDurationSeconds: 44,
      deviceStatus: 'Calibrated',
    );

    test('Answers "انا ممكن ابطل في قد ايه" with real clinical timeline', () {
      final reply = aiService.generateCoachingReply('انا ممكن ابطل في قد ايه', dummyReading);
      expect(reply, contains('72 ساعة'));
      expect(reply, contains('4 أسابيع'));
      expect(reply, isNot(contains('كل دقيقة بتقاوم فيها بتعيد برمجة مسارات الدوبامين')));
    });

    test('Answers withdrawal symptoms questions warmly and clinically', () {
      final reply = aiService.generateCoachingReply('ايه اعراض الانسحاب؟', dummyReading);
      expect(reply, contains('الصداع'));
      expect(reply, contains('الكحة'));
    });

    test('Answers weight and appetite concerns with supportive guidance', () {
      final reply = aiService.generateCoachingReply('خايف وزني يزيد واتخن', dummyReading);
      expect(reply, contains('الشهية'));
      expect(reply, contains('وزنك'));
    });
  });

  testWidgets('App renders splash screen without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
