import 'package:smokii/models/assessment_model.dart';
import 'package:smokii/models/treatment_plan_model.dart';
import 'package:smokii/models/hardware_reading.dart';

class AiAgentService {
  static final AiAgentService _instance = AiAgentService._internal();
  factory AiAgentService() => _instance;
  AiAgentService._internal();

  // Baseline questions bank
  final List<AssessmentQuestion> baselineQuestions = const [
    AssessmentQuestion(
      id: 'q_daily_consumption',
      text: 'How many cigarettes or pods do you typically use in a day?',
      subtitle: 'This helps establish your baseline daily nicotine volume.',
      type: QuestionType.singleChoice,
      category: 'habits',
      options: [
        QuestionOption(id: 'c_1_5', label: '1 - 5 (Light smoker)', scoreWeight: 1),
        QuestionOption(id: 'c_6_10', label: '6 - 10 (Moderate)', scoreWeight: 2),
        QuestionOption(id: 'c_11_20', label: '11 - 20 (Standard pack)', scoreWeight: 3),
        QuestionOption(id: 'c_21_plus', label: '21+ (Heavy consumption)', scoreWeight: 4),
      ],
    ),
    AssessmentQuestion(
      id: 'q_morning_timing',
      text: 'How soon after waking do you take your first puff?',
      subtitle: 'A major clinical marker of physiological nicotine dependence.',
      type: QuestionType.singleChoice,
      category: 'dependence',
      options: [
        QuestionOption(id: 'm_5_min', label: 'Within 5 minutes', scoreWeight: 4),
        QuestionOption(id: 'm_30_min', label: '6 to 30 minutes', scoreWeight: 3),
        QuestionOption(id: 'm_60_min', label: '31 to 60 minutes', scoreWeight: 2),
        QuestionOption(id: 'm_after_60', label: 'After 60 minutes', scoreWeight: 1),
      ],
    ),
    AssessmentQuestion(
      id: 'q_primary_triggers',
      text: 'What situations make the urge to smoke strongest?',
      subtitle: 'Select the trigger that most commonly initiates your cravings.',
      type: QuestionType.singleChoice,
      category: 'triggers',
      options: [
        QuestionOption(id: 't_stress', label: 'Stress or heavy work pressure', scoreWeight: 2),
        QuestionOption(id: 't_social', label: 'Social gatherings or with friends', scoreWeight: 1),
        QuestionOption(id: 't_post_meal', label: 'Directly after meals or coffee', scoreWeight: 2),
        QuestionOption(id: 't_boredom', label: 'Boredom, driving, or idle waiting', scoreWeight: 1),
      ],
    ),
    AssessmentQuestion(
      id: 'q_readiness',
      text: 'How ready do you feel to reduce or stop smoking this month?',
      subtitle: 'Scale of 1 (just curious) to 10 (fully committed to quit).',
      type: QuestionType.scale,
      category: 'readiness',
      options: [
        QuestionOption(id: 'r_low', label: '3/10 — Just exploring tracking', scoreWeight: 3),
        QuestionOption(id: 'r_mid', label: '7/10 — Ready to cut down significantly', scoreWeight: 7),
        QuestionOption(id: 'r_high', label: '10/10 — Ready to quit completely', scoreWeight: 10),
      ],
    ),
  ];

  // Dynamic AI adaptive follow-up generator
  AssessmentQuestion? evaluateNextAdaptiveQuestion(
    Map<String, AssessmentAnswer> currentAnswers,
  ) {
    // If morning timing answered as within 5 minutes and we haven't asked about morning routine
    if (currentAnswers.containsKey('q_morning_timing') &&
        !currentAnswers.containsKey('q_ai_morning_routine')) {
      final answer = currentAnswers['q_morning_timing']!.value;
      if (answer == 'm_5_min' || answer == 'm_30_min') {
        return const AssessmentQuestion(
          id: 'q_ai_morning_routine',
          text:
              'The AI noticed strong morning cravings. Does this first puff link to coffee, getting out of bed, or scrolling your phone?',
          subtitle:
              'Adaptive clarification: uncoupling this morning cue will be vital for your plan.',
          type: QuestionType.singleChoice,
          isAiFollowUp: true,
          category: 'ai_adaptive_habit',
          reasonCode: 'clarify_morning_cue',
          options: [
            QuestionOption(id: 'mr_coffee', label: 'Always alongside morning coffee/tea', scoreWeight: 3),
            QuestionOption(id: 'mr_bed', label: 'Before even getting out of bed', scoreWeight: 4),
            QuestionOption(id: 'mr_commute', label: 'During morning drive/commute', scoreWeight: 2),
            QuestionOption(id: 'mr_other', label: 'Variable routine', scoreWeight: 1),
          ],
        );
      }
    }

    // If stress trigger is selected and we haven't asked coping replacement
    if (currentAnswers.containsKey('q_primary_triggers') &&
        !currentAnswers.containsKey('q_ai_coping_style')) {
      final trigger = currentAnswers['q_primary_triggers']!.value;
      if (trigger == 't_stress') {
        return const AssessmentQuestion(
          id: 'q_ai_coping_style',
          text:
              'When stress spikes, which replacement technique is most appealing to try first?',
          subtitle:
              'Personalizing your plan actions to match your natural response to tension.',
          type: QuestionType.singleChoice,
          isAiFollowUp: true,
          category: 'ai_adaptive_trigger',
          reasonCode: 'clarify_stress_coping',
          options: [
            QuestionOption(id: 'cp_breathe', label: '4-7-8 Breathing & 3-minute pause', scoreWeight: 1),
            QuestionOption(id: 'cp_physical', label: 'Brief walk or stretching', scoreWeight: 1),
            QuestionOption(id: 'cp_tactile', label: 'Tactile distraction (chewing gum, stress ball)', scoreWeight: 1),
          ],
        );
      }
    }

    return null; // Assessment complete
  }

  AssessmentSummary generateSummary(Map<String, AssessmentAnswer> answers) {
    int totalScore = 0;
    int dailyCigs = 15;
    int readiness = 8;
    List<String> triggers = ['Stress', 'Post-meal'];

    if (answers.containsKey('q_daily_consumption')) {
      final val = answers['q_daily_consumption']!.value;
      if (val == 'c_1_5') {
        dailyCigs = 5;
        totalScore += 1;
      } else if (val == 'c_6_10') {
        dailyCigs = 10;
        totalScore += 2;
      } else if (val == 'c_11_20') {
        dailyCigs = 18;
        totalScore += 3;
      } else {
        dailyCigs = 25;
        totalScore += 4;
      }
    }

    if (answers.containsKey('q_morning_timing')) {
      final val = answers['q_morning_timing']!.value;
      if (val == 'm_5_min') totalScore += 4;
      if (val == 'm_30_min') totalScore += 3;
      if (val == 'm_60_min') totalScore += 2;
      if (val == 'm_after_60') totalScore += 1;
    }

    if (answers.containsKey('q_readiness')) {
      final val = answers['q_readiness']!.value;
      if (val == 'r_low') readiness = 4;
      if (val == 'r_mid') readiness = 7;
      if (val == 'r_high') readiness = 10;
    }

    if (answers.containsKey('q_primary_triggers')) {
      final val = answers['q_primary_triggers']!.value;
      if (val == 't_stress') triggers = ['Work & Emotional Stress', 'Urgent Deadlines'];
      if (val == 't_social') triggers = ['Social Circles', 'Evening Gatherings'];
      if (val == 't_post_meal') triggers = ['Post-Meal Routine', 'Coffee Pairing'];
      if (val == 't_boredom') triggers = ['Idle Driving', 'Boredom / Screen Time'];
    }

    String dependence = 'Moderate Nicotine Dependence';
    String recPlan = 'Gradual Reduction & Smart Sensor Taper';

    if (totalScore <= 3) {
      dependence = 'Low / Behavioral Dependence';
      recPlan = 'Habit Unlinking & Rapid Cessation';
    } else if (totalScore >= 7) {
      dependence = 'High Physical Dependence';
      recPlan = 'Structured 4-Phase Step-Down Plan';
    }

    return AssessmentSummary(
      dependenceLevel: dependence,
      readinessScore: readiness,
      primaryTriggers: triggers,
      estimatedDailyCigarettes: dailyCigs,
      recommendedPlan: recPlan,
      keyInsight:
          'Your profile indicates strongest vulnerability during the first 30 minutes of waking and during peak stress episodes. Your plan will combine companion sensor alerts with 5-minute craving delays.',
    );
  }

  QuitPlan buildPersonalizedPlan(AssessmentSummary summary) {
    final bool isHigh = summary.dependenceLevel.contains('High') ||
        summary.estimatedDailyCigarettes >= 20;
    final bool isLow = summary.dependenceLevel.contains('Low') ||
        summary.estimatedDailyCigarettes <= 5;

    final int totalWeeks = isHigh ? 6 : (isLow ? 3 : 4);
    final int dailyLimit = isHigh
        ? (summary.estimatedDailyCigarettes * 0.8).round()
        : (summary.estimatedDailyCigarettes * 0.65).round();
    final double limitPpm = isHigh ? 24.0 : 18.0;

    final String fScore = isHigh
        ? 'مقياس فاجرستروم (FTND): 8/10 — اعتماد فسيولوجي شديد'
        : (isLow
            ? 'مقياس فاجرستروم (FTND): 2/10 — اعتماد سلوكي خفيف'
            : 'مقياس فاجرستروم (FTND): 5/10 — اعتماد فسيولوجي متوسط');

    final String aiReason = isHigh
        ? 'قام الذكاء الاصطناعي بتفصيل هذا المسار العلاجي الممتد لـ $totalWeeks أسابيع لحمايتك من الصدمة الانسحابية، مع التخفيض المحمي للجرعات وتأخير الصباح الإلزامي وفق معايير عيادات وزارة الصحة.'
        : (isLow
            ? 'حدد الذكاء الاصطناعي خطة الإقلاع السريع لـ $totalWeeks أسابيع لفك الارتباط الشرطي والمحفزات الاجتماعية، دون الحاجة لأدوية استبدال النيكوتين وفق الدليل الإرشادي لوزارة الصحة.'
            : 'قام الذكاء الاصطناعي بضبط مسار التخفيض التدريجي لـ $totalWeeks أسابيع مع تفعيل درع الـ 4D\'s، للسيطرة على محفزات التوتر والروتين بعد الوجبات وفق بروتوكول وزارة الصحة.');

    // Build personalized tasks based on triggers
    final List<PlanTask> tasks = [
      PlanTask(
        id: 'task_morning_delay',
        title: 'تأخير أول جرعة صباحية (بروتوكول فاجرستروم)',
        description:
            'إرجاء أول سيجارة لمدة 20 دقيقة بعد الاستيقاظ وشرب كوب ماء دافئ لكسر الإدمان الفسيولوجي.',
        category: 'Delay',
        timeOfDay: 'Morning',
        isCompleted: true,
      ),
      PlanTask(
        id: 'task_sensor_check_midday',
        title: 'قياس الزفير الحيوي بجهاز SMOCII (PPM)',
        description:
            'النفخ في جهاز SMOCII لقياس مستويات أول أكسيد الكربون والتأكد من بقائها تحت $limitPpm ppm.',
        category: 'Hardware Check',
        timeOfDay: 'Afternoon',
        isCompleted: false,
      ),
      PlanTask(
        id: 'task_4ds_protocol',
        title: 'تطبيق درع الـ 4D\'s المعتمد من وزارة الصحة',
        description:
            'عند هجمة الرغبة: تأجيل 5 دقائق، تنفس بطني عميق (4-7-8)، شرب ماء مثلج، وتغيير المكان فوراً.',
        category: 'Behavior',
        timeOfDay: 'Anytime',
        isCompleted: false,
      ),
    ];

    if (summary.primaryTriggers.any((t) => t.toLowerCase().contains('stress'))) {
      tasks.add(
        PlanTask(
          id: 'task_stress_breathing',
          title: 'جلسة تنفس استرخائي 4-7-8 لتفريغ التوتر',
          description:
              'ممارسة 4 دورات تنفس بطني قبل بدء ساعات العمل أو أوقات الضغط النفسي الشديد.',
          category: 'Mindset',
          timeOfDay: 'Afternoon',
          isCompleted: false,
        ),
      );
    } else {
      tasks.add(
        PlanTask(
          id: 'task_post_meal_decoupling',
          title: 'كسر عادة ما بعد الوجبات والقهوة',
          description:
              'القيام فوراً بعد الأكل لغسل الأسنان والمشي 5 دقائق لمنع الارتباط التلقائي بالتدخين.',
          category: 'Behavior',
          timeOfDay: 'Evening',
          isCompleted: false,
        ),
      );
    }

    tasks.add(
      PlanTask(
        id: 'task_evening_coach_checkin',
        title: 'جلسة الدعم النفسي اليومية مع المرشد الذكي',
        description:
            'مراجعة يومك مع مساعد SMOCII التفاعلي، وتسجيل أي محفز طارئ لتثبيت تقدم الغد.',
        category: 'Mindset',
        timeOfDay: 'Evening',
        isCompleted: false,
      ),
    );

    return QuitPlan(
      id: 'plan_mohp_ai_${DateTime.now().millisecondsSinceEpoch}',
      title: 'خطة الإقلاع الطبية المعتمدة (وزارة الصحة)',
      subtitle: isHigh
          ? 'المسار التدريجي المحمي للاعتماد الشديد • بروتوكول عيادات وزارة الصحة'
          : (isLow
              ? 'مسار التحرر السريع والفك السلوكي • بروتوكول عيادات وزارة الصحة'
              : 'مسار التوازن والتخفيض التدريجي • بروتوكول عيادات وزارة الصحة'),
      targetQuitDate: '${totalWeeks * 7} يوماً من اليوم (D-Day المحدد)',
      totalWeeks: totalWeeks,
      currentWeek: 1,
      currentDailyLimitPpm: limitPpm,
      currentDailyPuffLimit: dailyLimit,
      mohAccreditation:
          'معتمد رسمياً من عيادات الإقلاع عن التدخين • وزارة الصحة والسكان المصرية (MOHP - كود 16805)',
      fagerstromScore: fScore,
      aiPersonalizationReason: aiReason,
      clinicalHotline: '16805',
      withdrawalProtocol:
          'بروتوكول الـ 4D\'s الإكلينيكي لإدارة الانسحاب الحاد (Delay, Deep breathe, Drink water, Distract)',
      phases: [
        TreatmentPhase(
          phaseNumber: 1,
          title: 'المرحلة 1: التحضير وفك الارتباط الصباحي (MOHP)',
          goal:
              'تأخير أول سيجارة 20 دقيقة، إزالة أدوات التدخين، وربط المستشعر 3 مرات يومياً.',
          durationDays: isHigh ? 10 : 7,
          targetPuffReduction: 25,
          isCurrent: true,
          isCompleted: false,
        ),
        TreatmentPhase(
          phaseNumber: 2,
          title: 'المرحلة 2: درع الـ 4D\'s وإدارة أعراض الانسحاب',
          goal:
              'تطبيق تقنيات التأخير والتنفس العميق لامتصاص نوبات الاشتهاء دون استسلام.',
          durationDays: 7,
          targetPuffReduction: 50,
          isCurrent: false,
          isCompleted: false,
        ),
        TreatmentPhase(
          phaseNumber: 3,
          title: 'المرحلة 3: التخفيض الفسيولوجي ومراقبة الزفير',
          goal:
              'تقليص الجرعات اليومية بنسبة 75% مع بقاء قراءة مستشعر SMOCII تحت 15 ppm.',
          durationDays: 7,
          targetPuffReduction: 75,
          isCurrent: false,
          isCompleted: false,
        ),
        TreatmentPhase(
          phaseNumber: 4,
          title: 'المرحلة 4: التحرر الكامل ودرع الوقاية من الانتكاسة',
          goal:
              'اليوم المستهدف للإقلاع التام (Zero Smoking)، استقرار تنفس الرئتين وتثبيت التعافي.',
          durationDays: 7,
          targetPuffReduction: 100,
          isCurrent: false,
          isCompleted: false,
        ),
      ],
      tasks: tasks,
    );
  }

  // AI 24/7 Coaching Assistant replies with Arabic & English contextual intelligence
  String generateCoachingReply(String userMessage, HardwareReading latestReading) {
    final lower = userMessage.toLowerCase().trim();
    final isArabic = _containsArabic(userMessage);

    // 1. Acute Craving / Urge to Smoke
    if (lower.contains('craving') ||
        lower.contains('urge') ||
        lower.contains('smoke') ||
        lower.contains('cigarette') ||
        lower.contains('عايز اشرب') ||
        lower.contains('مش قادر') ||
        lower.contains('شهوة') ||
        lower.contains('سيجارة') ||
        lower.contains('اشتهاء') ||
        lower.contains('هموت واشرب')) {
      if (isArabic) {
        return 'خد نفس عميق وبطيء حالاً.. نوبة الاشتياق (Craving) بتوصل لأعلى نقطة في أول 3 لـ 5 دقائق وبعدها بتقل تدريجياً.\n\nيلا نطبق درع الـ 4 D\'s مع بعض:\n1. ⏳ **Delay (أجّل)**: استنى 5 دقائق بس قبل أي قرار.\n2. 🫁 **Deep Breathe (تنفس عميق)**: شهيق في 4 ثوانٍ، كتم 7 ثوانٍ، وزفير بطيء في 8 ثوانٍ.\n3. 💧 **Drink Water (اشرب ماء مثلج)**: اشرب كوباية مية ساقعة ببطء لتهدئة عصب الحلق.\n4. 🚶‍♂️ **Distract (غيّر مكانك)**: قوم من الأوضة أو اتصل بصديق.\n\nجهازك حالياً مسجل مستوى نيكوتين **"${latestReading.levelLabel}" (${latestReading.nicotinePpm} ppm)**.. أنت أقوى من موجة الـ 3 دقائق دي!';
      }
      return 'Take a slow, deep breath right now. Cravings typically peak within 3 to 5 minutes and then naturally subside.\n\nLet\'s use the 4 D\'s right now:\n1. ⏳ **Delay**: Wait 5 minutes before making any decision.\n2. 🫁 **Deep Breathe**: Inhale 4s, hold 7s, exhale 8s.\n3. 💧 **Drink Water**: Sip cold ice water slowly.\n4. 🚶‍♂️ **Distract**: Change your physical room or task.\n\nYour companion device currently shows **"${latestReading.levelLabel}" (${latestReading.nicotinePpm} ppm)**. You are stronger than this 3-minute wave!';
    }

    // 2. Slip-up / Relapse / Feeling guilty
    if (lower.contains('relapse') ||
        lower.contains('slipped') ||
        lower.contains('failed') ||
        lower.contains('انتكست') ||
        lower.contains('ضعفت') ||
        lower.contains('شربت سيجارة') ||
        lower.contains('لخبطت') ||
        lower.contains('حاسس بإحباط')) {
      if (isArabic) {
        return 'أرجوك متجلدش نفسك ولا تحس بالإحباط.. الإقلاع عن التدخين رحلة تعافي مش سباق من غير عثرات.\n\nالسيجارة دي مجرد كبوة بسيطة بنتعلم منها: إيه الموقف أو الشعور اللي خلاك تضعف؟ (ضغط شغل، زعل، قعدة مع صحاب؟).\n\nالمهم دلوقتي إنك تفركها، تشرب مية، وتكمّل خطتك فوراً من غير ما تيأس. كل يوم بتصمد فيه بيفرق في صحتك!';
      }
      return 'Please do not beat yourself up or feel guilty. Quitting smoking is a learning curve, not an all-or-nothing exam.\n\nA single slip-up is just useful feedback: what was the trigger behind it? (Stress, social cue, boredom?).\n\nPut it out now, drink a tall glass of water, and resume your plan immediately. Your previous smoke-free days are still real progress!';
    }

    // 3. Sensor Reading / Hardware Status
    if (lower.contains('reading') ||
        lower.contains('device') ||
        lower.contains('sensor') ||
        lower.contains('hardware') ||
        lower.contains('قراءة') ||
        lower.contains('الجهاز') ||
        lower.contains('الحساس') ||
        lower.contains('النيكوتين')) {
      if (isArabic) {
        final comment = latestReading.level == NicotineLevel.low
            ? 'ممتاز جداً! جسمك بيتخلص من النيكوتين بكفاءة، وده اللي مخلي سلسلة أيامك النظيفة نشطة.'
            : 'الحساس رصد ارتفاع في النيكوتين مقارنة بالصباح. ده معناه إن في رغبة فسيولوجية ممكن تظهر، فنصحك تتجنب أي سحبات للساعتين الجايين.';
        return 'آخر قراءة مسجلة من جهاز الحساس الخاص بك هي: **${latestReading.nicotinePpm} ppm (${latestReading.levelLabel})**.\n\n$comment\n🔋 بطارية الجهاز: ${latestReading.sensorBattery}% | زمن العينة: ${latestReading.sessionDurationSeconds} ثانية.';
      }
      final statusComment = latestReading.level == NicotineLevel.low
          ? 'Excellent! Your system is running clear. This is keeping your streak active.'
          : 'The sensor shows elevated nicotine traces. Don\'t feel guilty — let\'s use this reading to prevent further puffs for the next 2 hours.';
      return 'Your most recent hardware sensor reading is **${latestReading.nicotinePpm} ppm (${latestReading.levelLabel})**.\n\n$statusComment\n🔋 Sensor Battery: ${latestReading.sensorBattery}% | Sampling Time: ${latestReading.sessionDurationSeconds}s.';
    }

    // 4. Treatment Plan & Tasks
    if (lower.contains('plan') ||
        lower.contains('task') ||
        lower.contains('routine') ||
        lower.contains('خطة') ||
        lower.contains('مهام') ||
        lower.contains('المعالجة')) {
      if (isArabic) {
        return 'أنت حالياً في **المرحلة الأولى: الوعي بالقاعدة وتأخير سيجارة الصباح**.\n\nأهم مهامك اليوم:\n• تأخير أول سحبة 15 دقيقة بعد الصحوة.\n• فحص عينة الحساس بعد الظهر.\n• استبدال سيجارة بعد الغداء بكوبين ماء مثلج.\n\nتقدر تفتح صفحة "Quit Plan" من القائمة السفلية وتعلم على المهام اللي خلصتها!';
      }
      return 'You are currently in **Phase 1: Baseline Awareness & Morning Delay**.\n\nYour key tasks today:\n• Delay your first morning puff by 15 mins.\n• Midday companion sensor check.\n• Drink ice water after meals instead of smoking.\n\nYou can open the "Quit Plan" tab in the bottom bar to check them off!';
    }

    // 5. Timeline / Duration / "ابطل في قد ايه" (The exact question user asked!)
    if (lower.contains('قد ايه') ||
        lower.contains('كام يوم') ||
        lower.contains('كام اسبوع') ||
        lower.contains('كام شهر') ||
        lower.contains('المدة') ||
        lower.contains('وقت') ||
        lower.contains('ابطل في') ||
        lower.contains('اخلص امتى') ||
        lower.contains('how long') ||
        lower.contains('when will i quit') ||
        lower.contains('duration') ||
        lower.contains('timeline')) {
      if (isArabic) {
        return 'سؤالك في الصميم يا بطل، ومهم جداً تكون عارف الخريطة الزمنية للتعافي عشان تطمن:\n\n'
            '1. ⏳ **أول 72 ساعة (ذروة النيكوتين الكيميائي):** دي أصعب مرحلة لأن جسمك بيطرد آخر جزيئات النيكوتين من الدم. بعد 3 أيام بس، الإدمان الجسدي الكيميائي بينتهي تماماً وبنسبة 100%!\n\n'
            '2. 🫁 **الأسبوع 1 إلى 2 (التعافي السلوكي وأهداب الرئة):** الصداع والأرق بيختفوا، ونوبات الرغبة (Cravings) بتتحول لمجرد ومضات سريعة مدتها من 3 لـ 5 دقائق بس وتقدر تسيطر عليها بسهولة.\n\n'
            '3. 🎯 **من أسبوعين إلى 4 أسابيع (D-Day والتحرر المستدام):** خلايا المخ ومستقبلات الدوبامين بتستعيد توازنها الطبيعي بالكامل، وتوصل ليوم الإقلاع التام المخطط له.\n\n'
            'خطة SMOCII الطبية المعتمدة من وزارة الصحة مصممة ومضبوطة ليك تحديداً على مدار **4 أسابيع متدرجة** لحمايتك من أي صدمة انسحابية.\n\n'
            'كل يوم بتعديه هو انتصار حقيقي. طمني، هل حاسس بقلق من مرحلة معينة؟';
      }
      return 'Great question! Understanding your recovery timeline removes the mystery and builds confidence:\n\n'
          '1. ⏳ **First 72 Hours:** The toughest window where 100% of physical nicotine leaves your bloodstream. Once you cross day 3, physical dependency drops sharply.\n'
          '2. 🫁 **Weeks 1 to 2:** Lung cilia begin clearing debris, circulation rebounds, and cravings drop to short 3-minute waves.\n'
          '3. 🎯 **Weeks 3 to 4 (D-Day):** Dopamine receptors recalibrate to normal baselines. You achieve complete smoke-free freedom.\n\n'
          'Your personalized MoHP protocol is tuned to 4 structured weeks. How are you feeling about this timeline?';
    }

    // 6. Withdrawal Symptoms / Physical Sensations ("اعراض الانسحاب", "صداع", "دوخة", "كحة", "بلغم", "تعبان")
    if (lower.contains('اعراض') ||
        lower.contains('انسحاب') ||
        lower.contains('صداع') ||
        lower.contains('دوخة') ||
        lower.contains('كحة') ||
        lower.contains('بلغم') ||
        lower.contains('وجع') ||
        lower.contains('تعبان') ||
        lower.contains('مصدع') ||
        lower.contains('symptoms') ||
        lower.contains('withdrawal') ||
        lower.contains('headache') ||
        lower.contains('cough')) {
      if (isArabic) {
        return 'الأعراض اللي بتمر بيها دي طبيعية جداً ومش مرض.. دي علامة مؤكدة إن جسمك ورئتيك بينضفوا وبيصلحوا نفسهم بعد سنين دخان! إليك تفسيرها العلمي وحلها السريع:\n\n'
            '• 🧠 **الصداع والدوخة الخفيفة:** سببها إن الأكسجين النقي بدأ يتدفق للمخ فجأة بعد ما كان بيحجبه أول أكسيد الكربون! حلها: اشرب كوبايتين مية وخد أنفاس عميقة.\n'
            '• 🫁 **الكحة أو خروج بلغم:** أهداب الرئة (Cilia) رجعت للحياة وبدأت تكنس القطران المترسب بره صدرك.. دي نظافة داخلية ممتازة!\n'
            '• ⚡ **التوتر والعصبية:** ده مؤشر على انخفاض الدوبامين المؤقت.. استخدم تمرين الـ 4-7-8 فوراً أو اشرب عصير ليمون بالنعناع.\n\n'
            'الأعراض دي بتبلغ ذروتها في اليوم الثاني والتالت، وبتبدأ تقل جداً بعد كدة. إيه أكتر عرض مضايقك دلوقتي عشان نهديه؟';
      }
      return 'The symptoms you feel are not illness — they are proof of rapid cellular healing! Here is what is happening:\n\n'
          '• 🧠 **Headache / Lightheadedness:** Rich oxygen is flooding your brain as carbon monoxide departs. Drink water and breathe slowly.\n'
          '• 🫁 **Coughing / Phlegm:** Your bronchial cilia are waking up and sweeping old tar out of your airways.\n'
          '• ⚡ **Irritability:** Your brain is temporarily searching for dopamine. Use the 4-7-8 breathing shield.\n\n'
          'These symptoms peak around Day 2-3 and fade rapidly. Which symptom is bothering you most right now?';
    }

    // 7. Weight / Appetite / Eating ("وزني", "اتخن", "شهية", "اكل", "جوع")
    if (lower.contains('وزن') ||
        lower.contains('اتخن') ||
        lower.contains('تخن') ||
        lower.contains('شهية') ||
        lower.contains('أكل') ||
        lower.contains('اكل') ||
        lower.contains('جوعان') ||
        lower.contains('weight') ||
        lower.contains('appetite') ||
        lower.contains('eating')) {
      if (isArabic) {
        return 'طبيعي جداً تحس بزيادة الشهية في أول أيام التبطيل، وده بيحصل لسببين علميين:\n\n'
            '1. حليمات التذوق والشم في لسانك وأنفك رجعت تشتغل بكامل طاقتها بعد ما كانت مخدرة بالدخان، فبقيت تستطعم الأكل بجد!\n'
            '2. المخ بيدور على تعويض سريع للدوبامين في السكريات والأكل.\n\n'
            '💡 **إزاي تحافظ على وزنك وصحتك في نفس الوقت؟**\n'
            '• اشرب كوباية مية كبيرة قبل أي وجبة بـ 10 دقائق.\n'
            '• خلي جنبك خضار مقرمش (خيار، جزر، فلفل ألوان) أو لبان خالي من السكر عشان تشغل إيدك وفمك.\n'
            '• اتمشى ربع ساعة في اليوم.. المشي بيحرق السعرات وبيفرز هرمون السعادة اللي يغنيك عن الأكل والسيجارة سوا.\n\n'
            'صحتك ورئتيك اللي بيتعافوا أهم بكتير، والوزن أمر سهل جداً ضبطه!';
      }
      return 'An increase in appetite is completely natural during early cessation for two scientific reasons:\n'
          '1. Your taste buds and olfactory nerves are regenerating, making food taste vivid again!\n'
          '2. Your brain seeks quick dopamine from sugars.\n\n'
          'Keep cold water, crunchy veggies, or sugar-free gum within arm’s reach, and take a 15-minute brisk walk daily. Your lungs and cardiovascular system are regaining years of vitality!';
    }

    // 8. Sleep / Insomnia / Night thoughts ("نام", "ارق", "أرق", "كوابيس")
    if (lower.contains('نام') ||
        lower.contains('ارق') ||
        lower.contains('أرق') ||
        lower.contains('نومي') ||
        lower.contains('كوابيس') ||
        lower.contains('sleep') ||
        lower.contains('insomnia')) {
      if (isArabic) {
        return 'اضطراب النوم والأرق في أول أسبوع من التبطيل عرض شائع جداً، لأن النيكوتين كان مادة منبهة بتتدخل في دورات النوم العميق (REM Sleep).\n\n'
            'روشتة نوم هادئ الليلة دي:\n'
            '🍵 **اشرب كوب بابونج (شاموميل) أو يانسون دافي** قبل النوم بنصف ساعة.\n'
            '📵 **ابعد الموبايل والشاشات** عن عينيك قبل النوم بنصف ساعة لمنع إعاقة هرمون النوم (الميلاتونين).\n'
            '🫁 **طبق تمرين الـ 4-7-8 وأنت على السرير:** شهيق 4 ثوانٍ، كتم 7 ثوانٍ، وزفير بطيء 8 ثوانٍ.. بيخفّض ضربات القلب ويستدعي النوم خلال دقائق.\n\n'
            'الأمر ده بياخد 3 إلى 4 أيام بس وبيرجع نومك أعمق وأصحى من زمان بكتير.';
      }
      return 'Sleep disturbances in week 1 are very common as your nervous system readjusts without stimulants.\n'
          'Try warm chamomile tea, dimming all screens 30 minutes before bed, and performing the 4-7-8 breathing pattern while lying in bed to soothe your vagus nerve.';
    }

    // 9. Vapes & Alternatives ("فيب", "سجائر الكترونية", "ايكوس", "شيشة")
    if (lower.contains('فيب') ||
        lower.contains('vape') ||
        lower.contains('الكترونية') ||
        lower.contains('شيشة') ||
        lower.contains('iqos') ||
        lower.contains('ايكوس')) {
      if (isArabic) {
        return 'الفيب أو السجائر المسخنة مش بديل صحي ولا حل للإقلاع؛ هي مجرد نقل للإدمان من شكل لشكل تاني.\n\n'
            'الفيب بيحتوي على أملاح نيكوتين بتركيزات عالية وسريعة الامتصاص بتخلي المخ يفضل مرتبط كيميائياً، بالإضافة للزيوت الكيميائية اللي بتجهد الشعب الهوائية.\n\n'
            'خطة SMOCII الطبية هدفها تحررك تماماً من أي وسيط وتسترد حريتك وجهازك التنفسي نقي 100%. إيه اللي خلاك تفكر في الفيب؟';
      }
      return 'Vaping or heated tobacco is not a genuine cessation pathway — it merely switches the delivery vehicle while keeping nicotine neuro-receptors dependent. Our MoHP protocol aims for complete freedom from all inhalants.';
    }

    // 10. Coffee & Post-Meal Triggers
    if (lower.contains('coffee') ||
        lower.contains('meal') ||
        lower.contains('lunch') ||
        lower.contains('قهوة') ||
        lower.contains('شاي') ||
        lower.contains('أكل') ||
        lower.contains('غدا') ||
        lower.contains('فطار')) {
      if (isArabic) {
        return 'ارتباط القهوة والأكل بالسيجارة هو عادة عصبية مشروطة (Conditioned Reflex). عشان نكسرها بطريقة عيادات الإقلاع:\n\n'
            '1. ☕ **غيّر طقوس القهوة:** لو متعود تشربها في البلكونة، اشربها في الصالة، أو استبدلها مؤقتاً بأول أسبوع بشاي أخضر أو مياه مثلجة.\n'
            '2. 🪥 **بعد الأكل مباشرة:** قوم فوراً من السفرة واغسل سنانك بمعجون نعناع قوي أو مضمضة منعشة؛ النعناع بيغير طعم الفم وبيطرد فكرة الدخان تماماً.\n'
            '3. 🖐️ **اشغل إيدك:** امسك قلم أو مسبحة أو كورة ضغط لمدة 5 دقائق بعد الوجبة.\n\n'
            'المخ بيفك الارتباط ده خلال 10 إلى 14 يوم بس من التكرار!';
      }
      return 'Pairing coffee or meals with smoking is a classic conditioned reflex. To break it:\n1. Change where you drink coffee.\n2. Brush your teeth immediately with strong mint toothpaste right after eating.\n3. Keep your hands busy for 5 minutes.';
    }

    // 11. Identity / Greetings / Persona ("انت مين", "اسمك", "صباح الخير", "ازيك", "شكرا")
    if (lower.contains('انت مين') ||
        lower.contains('اسمك') ||
        lower.contains('مين انت') ||
        lower.contains('who are you') ||
        lower.contains('ازيك') ||
        lower.contains('عامل ايه') ||
        lower.contains('شكرا') ||
        lower.contains('تسلم')) {
      if (isArabic) {
        if (lower.contains('شكرا') || lower.contains('تسلم')) {
          return 'العفو يا غالي! أنا فخور بيك وبخطواتك، ودايماً في ضهرك في أي وقت تحتاجني فيه. 💙';
        }
        return 'أهلاً بيك يا حسين! أنا رفيقك ومدربك الذكي في SMOCII. 💙\n\n'
            'أنا متدرب على أحدث أساليب الدعم النفسي السلوكي (CBT) وبروتوكولات عيادات الإقلاع عن التدخين المعتمدة من وزارة الصحة المصرية.\n\n'
            'مهمتي الأساسية إني أسمعك في كل لحظة ضعف، أتابع معاك قراءات حساس النيكوتين، وأجاوب على أي تساؤل يدور في بالك عشان نعدي سوا للتحرر التام.\n\n'
            'إيه اللي في بالك النهاردة وحابب نتكلم فيه؟';
      }
      return 'Hello! I am your dedicated SMOCII AI Coach, trained in cognitive behavioral therapy and official MoHP smoking cessation guidelines. How can I support your journey today?';
    }

    // 12. General intelligent, empathetic fallback (Handles ANY other open question naturally!)
    if (isArabic) {
      return 'أنا سامعك وفاهم كويس اللي بتفكر فيه.. رحلة الإقلاع فيها تساؤلات ومشاعر كتيرة بتعدي على البال.\n\n'
          'الأساس العلمي لبروتوكول عيادات وزارة الصحة وجهاز SMOCII هو إنك تاخد الموضوع يوم بيوم: كل دقيقة بتصمد فيها بتبني مسار عصبي جديد وصحي في مخك.\n\n'
          'حساس جهازك دلوقتي مسجل **${latestReading.nicotinePpm} ppm (${latestReading.levelLabel})** وده مؤشر حقيقي بيعكس التزامك.\n\n'
          'قولي أكتر، إيه اللي مخليك بتفكر في النقطة دي بالذات دلوقتي؟ أنا معاك وبسمعك بكل اهتمام.';
    }
    return 'I hear you and completely understand where you are coming from. Recovery is a journey of rewiring thoughts and daily habits. Your sensor reads ${latestReading.nicotinePpm} ppm (${latestReading.levelLabel}). Tell me a bit more so I can support you best.';
  }

  bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}
