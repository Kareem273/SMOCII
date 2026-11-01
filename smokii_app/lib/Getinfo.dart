import 'package:flutter/material.dart';
import 'package:smokii/Dashboard.dart';
import 'package:smokii/const/constant.dart';
import 'package:smokii/models/assessment_model.dart';
import 'package:smokii/services/ai_agent_service.dart';
import 'package:smokii/services/app_state.dart';

class Getinfo extends StatefulWidget {
  const Getinfo({super.key});

  @override
  State<Getinfo> createState() => _GetinfoState();
}

class _GetinfoState extends State<Getinfo> {
  final AiAgentService _aiService = AiAgentService();
  final Map<String, AssessmentAnswer> _userAnswers = {};

  late List<AssessmentQuestion> _questionsQueue;
  int _currentIndex = 0;
  bool _isAssessing = true;
  AssessmentSummary? _summary;

  @override
  void initState() {
    super.initState();
    _questionsQueue = List.from(_aiService.baselineQuestions);
  }

  void _selectOption(AssessmentQuestion question, QuestionOption option) {
    setState(() {
      _userAnswers[question.id] = AssessmentAnswer(
        questionId: question.id,
        value: option.id,
        displayLabel: option.label,
      );
    });

    // Check if AI wants to insert a follow-up question
    final adaptiveQuestion =
        _aiService.evaluateNextAdaptiveQuestion(_userAnswers);
    if (adaptiveQuestion != null &&
        !_questionsQueue.any((q) => q.id == adaptiveQuestion.id)) {
      setState(() {
        _questionsQueue.insert(_currentIndex + 1, adaptiveQuestion);
      });
    }

    // Move next or finish
    if (_currentIndex < _questionsQueue.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishAssessment();
    }
  }

  void _finishAssessment() {
    final summary = _aiService.generateSummary(_userAnswers);
    setState(() {
      _summary = summary;
      _isAssessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryTextColor),
          onPressed: () {
            if (_currentIndex > 0 && _isAssessing) {
              setState(() {
                _currentIndex--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'AI Assessment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundColor),
        child: SafeArea(
          child: _isAssessing ? _buildQuestionView() : _buildSummaryView(),
        ),
      ),
    );
  }

  Widget _buildQuestionView() {
    final currentQ = _questionsQueue[_currentIndex];
    final progress = (_currentIndex + 1) / _questionsQueue.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar & step count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUESTION ${_currentIndex + 1} OF ${_questionsQueue.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.8,
                ),
              ),
              if (currentQ.isAiFollowUp)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                      SizedBox(width: 4),
                      Text(
                        'AI Adaptive Question',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFD3E5FD),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 30),

          // Question Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: pirmaryColorElementBG,
              borderRadius: BorderRadius.circular(24),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentQ.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    height: 1.3,
                  ),
                ),
                if (currentQ.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    currentQ.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Options List
                ...currentQ.options.map((option) {
                  final isSelected =
                      _userAnswers[currentQ.id]?.value == option.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectOption(currentQ, option),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.08)
                              : const Color(0xFFF7FAFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.black.withValues(alpha: 0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? primaryColor
                                  : secondaryTextColor,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? primaryColor
                                      : primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    if (_summary == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: successColor, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Assessment Completed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          ),
          Center(
            child: Text(
              'AI Agent prepared your custom treatment profile',
              style: TextStyle(fontSize: 13, color: secondaryTextColor),
            ),
          ),
          const SizedBox(height: 24),

          // MOHP Certified Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2B48),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF4DD0E1), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'بروتوكول عيادات الإقلاع عن التدخين • وزارة الصحة والسكان (16805)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: pirmaryColorElementBG,
              borderRadius: BorderRadius.circular(24),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryItem(
                  title: 'NICOTINE DEPENDENCE (فاجرستروم)',
                  value: _summary!.dependenceLevel,
                  color: primaryColor,
                  icon: Icons.speed,
                ),
                const Divider(height: 24),
                _buildSummaryItem(
                  title: 'READINESS SCORE (مؤشر الجاهزية)',
                  value: '${_summary!.readinessScore} / 10',
                  color: successColor,
                  icon: Icons.trending_up,
                ),
                const Divider(height: 24),
                _buildSummaryItem(
                  title: 'PRIMARY TRIGGERS IDENTIFIED',
                  value: _summary!.primaryTriggers.join(', '),
                  color: warningColor,
                  icon: Icons.psychology,
                ),
                const Divider(height: 24),
                _buildSummaryItem(
                  title: 'AUTOMATIC AI GENERATED PROTOCOL',
                  value: _summary!.recommendedPlan,
                  color: primaryColor,
                  icon: Icons.medical_services_outlined,
                ),
                const SizedBox(height: 20),

                // AI Insight Note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _summary!.keyInsight,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final newPlan = _aiService.buildPersonalizedPlan(_summary!);
                AppState().applyGeneratedPlan(newPlan);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تفعيل خطتك العلاجية الطبية المعتمدة من وزارة الصحة بنجاح!'),
                    backgroundColor: successColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'تفعيل خطة وزارة الصحة المخصصة لك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
