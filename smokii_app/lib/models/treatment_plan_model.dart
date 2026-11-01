class PlanTask {
  final String id;
  final String title;
  final String description;
  final String category; // 'Behavior', 'Delay', 'Hardware Check', 'Mindset'
  bool isCompleted;
  final String timeOfDay; // 'Morning', 'Afternoon', 'Evening', 'Anytime'

  PlanTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.isCompleted = false,
    this.timeOfDay = 'Anytime',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'isCompleted': isCompleted,
        'timeOfDay': timeOfDay,
      };

  factory PlanTask.fromJson(Map<String, dynamic> json) => PlanTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        timeOfDay: json['timeOfDay'] as String? ?? 'Anytime',
      );
}

class TreatmentPhase {
  final int phaseNumber;
  final String title;
  final String goal;
  final int durationDays;
  final int targetPuffReduction; // e.g., 25%
  final bool isCurrent;
  final bool isCompleted;

  const TreatmentPhase({
    required this.phaseNumber,
    required this.title,
    required this.goal,
    required this.durationDays,
    required this.targetPuffReduction,
    this.isCurrent = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'phaseNumber': phaseNumber,
        'title': title,
        'goal': goal,
        'durationDays': durationDays,
        'targetPuffReduction': targetPuffReduction,
        'isCurrent': isCurrent,
        'isCompleted': isCompleted,
      };
}

class QuitPlan {
  final String id;
  final String title;
  final String subtitle;
  final String targetQuitDate;
  final int totalWeeks;
  final int currentWeek;
  final double currentDailyLimitPpm;
  final int currentDailyPuffLimit;
  final List<TreatmentPhase> phases;
  final List<PlanTask> tasks;
  String hardwareFeedbackMessage;
  final String mohAccreditation;
  final String fagerstromScore;
  final String aiPersonalizationReason;
  final String clinicalHotline;
  final String withdrawalProtocol;

  QuitPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetQuitDate,
    required this.totalWeeks,
    required this.currentWeek,
    required this.currentDailyLimitPpm,
    required this.currentDailyPuffLimit,
    required this.phases,
    required this.tasks,
    this.hardwareFeedbackMessage =
        'Device synchronized: baseline levels stable.',
    this.mohAccreditation =
        'معتمد من وزارة الصحة والسكان المصرية • الدليل الإكلينيكي لعيادات الإقلاع عن التدخين',
    this.fagerstromScore = 'مقياس فاجرستروم (FTND): اعتماد متوسط (5/10)',
    this.aiPersonalizationReason =
        'تم توليد هذه الخطة تلقائياً بالذكاء الاصطناعي وفق قياسات الإدمان الفسيولوجي والمحفزات السلوكية.',
    this.clinicalHotline = '16805',
    this.withdrawalProtocol = "بروتوكول الـ 4D's المعتمد لإدارة الرغبة الملحة",
  });

  double get completionRate {
    if (tasks.isEmpty) return 0.0;
    final done = tasks.where((t) => t.isCompleted).length;
    return done / tasks.length;
  }
}
