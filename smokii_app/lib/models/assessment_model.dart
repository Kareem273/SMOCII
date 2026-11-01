enum QuestionType { singleChoice, multipleChoice, scale, text }

class QuestionOption {
  final String id;
  final String label;
  final int scoreWeight;

  const QuestionOption({
    required this.id,
    required this.label,
    this.scoreWeight = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'scoreWeight': scoreWeight,
      };

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
        id: json['id'] as String,
        label: json['label'] as String,
        scoreWeight: (json['scoreWeight'] as num?)?.toInt() ?? 1,
      );
}

class AssessmentQuestion {
  final String id;
  final String text;
  final String subtitle;
  final QuestionType type;
  final List<QuestionOption> options;
  final bool isRequired;
  final bool isAiFollowUp;
  final String? category;
  final String? reasonCode;

  const AssessmentQuestion({
    required this.id,
    required this.text,
    this.subtitle = '',
    required this.type,
    this.options = const [],
    this.isRequired = true,
    this.isAiFollowUp = false,
    this.category,
    this.reasonCode,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'subtitle': subtitle,
        'type': type.name,
        'options': options.map((e) => e.toJson()).toList(),
        'isRequired': isRequired,
        'isAiFollowUp': isAiFollowUp,
        'category': category,
        'reasonCode': reasonCode,
      };
}

class AssessmentAnswer {
  final String questionId;
  final dynamic value; // string or List<String> or int
  final String displayLabel;

  const AssessmentAnswer({
    required this.questionId,
    required this.value,
    required this.displayLabel,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'value': value,
        'displayLabel': displayLabel,
      };
}

class AssessmentSummary {
  final String dependenceLevel; // Mild, Moderate, High
  final int readinessScore; // 1 to 10
  final List<String> primaryTriggers;
  final int estimatedDailyCigarettes;
  final String recommendedPlan;
  final String keyInsight;

  const AssessmentSummary({
    required this.dependenceLevel,
    required this.readinessScore,
    required this.primaryTriggers,
    required this.estimatedDailyCigarettes,
    required this.recommendedPlan,
    required this.keyInsight,
  });

  Map<String, dynamic> toJson() => {
        'dependenceLevel': dependenceLevel,
        'readinessScore': readinessScore,
        'primaryTriggers': primaryTriggers,
        'estimatedDailyCigarettes': estimatedDailyCigarettes,
        'recommendedPlan': recommendedPlan,
        'keyInsight': keyInsight,
      };

  factory AssessmentSummary.fromJson(Map<String, dynamic> json) =>
      AssessmentSummary(
        dependenceLevel: json['dependenceLevel'] as String,
        readinessScore: (json['readinessScore'] as num).toInt(),
        primaryTriggers: (json['primaryTriggers'] as List<dynamic>)
            .map((e) => e.toString())
            .toList(),
        estimatedDailyCigarettes:
            (json['estimatedDailyCigarettes'] as num).toInt(),
        recommendedPlan: json['recommendedPlan'] as String,
        keyInsight: json['keyInsight'] as String,
      );
}
