/**
 * SMOCII Empathetic AI Coach Engine
 * Provides compassionate, active-listening, CBT-informed coaching
 * for individuals overcoming nicotine dependence.
 */

class AiCoachEngine {
  constructor() {
    this.geminiApiKey = process.env.GEMINI_API_KEY || null;
  }

  async generateResponse({
    userMessage,
    userName = 'حسين',
    latestReading = { nicotinePpm: 11.2, level: 'low' },
    streakDays = 14,
    currentPhase = 'Phase 1: Baseline Awareness & Delay',
    recentTasks = [],
  }) {
    // If Gemini API Key is configured, attempt LLM call
    if (this.geminiApiKey) {
      try {
        const llmReply = await this._callGeminiAPI({
          userMessage,
          userName,
          latestReading,
          streakDays,
          currentPhase,
        });
        if (llmReply) return llmReply;
      } catch (err) {
        console.error('Gemini API call failed, falling back to local empathetic engine:', err.message);
      }
    }

    // Default: High-Empathy Local Natural Language Engine
    return this._generateLocalEmpatheticReply({
      userMessage,
      userName,
      latestReading,
      streakDays,
      currentPhase,
    });
  }

  _generateLocalEmpatheticReply({
    userMessage,
    userName,
    latestReading,
    streakDays,
    currentPhase,
  }) {
    const text = userMessage.trim().toLowerCase();
    const isArabic = /[\u0600-\u06FF]/.test(userMessage);

    // 0. Timeline / Duration ("ابطل في قد ايه", "المدة", "كام يوم")
    if (
      text.includes('قد ايه') ||
      text.includes('كام يوم') ||
      text.includes('المدة') ||
      text.includes('وقت') ||
      text.includes('ابطل في') ||
      text.includes('how long') ||
      text.includes('duration')
    ) {
      if (isArabic) {
        return `سؤال مهم جداً يا ${userName}، وعشان تكون مطمن وعارف أنت ماشي إزاي:\n\n` +
          `1. ⏳ **أول 72 ساعة (ذروة النيكوتين الكيميائي):** دي المرحلة الأصعب، لأن جسمك بيطرد النيكوتين بالكامل. بعد 3 أيام، بينتهي الإدمان الكيميائي في الدم بنسبة 100%!\n\n` +
          `2. 🫁 **من أسبوع لأسبوعين (التعافي السلوكي):** تبدأ أهداب الرئة تتنظف، والدورة الدموية ترجع طبيعية، ونوبات الرغبة تقل وتتحول لمجرد موجات مدتها 3 دقائق بس.\n\n` +
          `3. 🎯 **من أسبوعين لـ 4 أسابيع (D-Day والتحرر التام):** المخ بيستعيد توازن الدوبامين الطبيعي، وبتكون أنجزت خطة وزارة الصحة وحققت صفر تدخين مستدام!\n\n` +
          `خطتك الطبية الحالية مصممة ومضبوطة ليك على مدار **4 أسابيع** لحمايتك من أي صدمة انسحابية. كل يوم صمود هو خطوة عملاقة.. إيه أكتر مرحلة حاسس إنك قلقان منها؟`;
      }
      return `Great question, ${userName}! The recovery journey breaks down into:\n\n` +
        `1. ⏳ **First 72 Hours:** 100% of physical nicotine clears your blood.\n` +
        `2. 🫁 **Weeks 1-2:** Cravings drop to brief 3-minute waves and lung cilia regenerate.\n` +
        `3. 🎯 **Weeks 3-4 (D-Day):** Dopamine receptors normalize and permanent smoke-free freedom is reached.\n\n` +
        `Your personalized plan is calibrated for 4 weeks. How do you feel about this timeline?`;
    }

    // 1. Extreme Craving / Panic / Urge ("عايز اشرب", "مش قادر", "هموت واشرب", "craving")
    if (
      text.includes('مش قادر') ||
      text.includes('عايز اشرب') ||
      text.includes('هتجنن') ||
      text.includes('هموت واشرب') ||
      text.includes('شهوة') ||
      text.includes('رغبة') ||
      text.includes('craving') ||
      text.includes('urge') ||
      text.includes('need a smoke')
    ) {
      if (isArabic) {
        return `أنا حاسس بيك جداً يا ${userName}، وعارف قد إيه اللحظة دي صعبة والتوتر بيكون عالي.. بس اسمعني بهدوء:

أنت مش لوحدك، والرغبة القوية دي مش هتفضل مستمرة.. علمياً دي "موجة" بتوصل لذروتها في 3 لـ 5 دقائق بس وبعدها بتنكسر تماماً.

عايزك تاخد نفس عميق معايا دلوقتي:
🫁 **شهيق عميق من الأنف (4 ثوانٍ)**.. 
⏸️ **اكتم نفسك بهدوء (7 ثوانٍ)**.. 
💨 **زفير طويل وبطيء من الفم (8 ثوانٍ)**..

حساس جهازك دلوقتي مسجل **${latestReading.nicotinePpm} ppm (${latestReading.level})**، يعني جسمك بدأ فعلاً ينضف. افتكر إنك صمدت **${streakDays} يوم** كاملين! متخليش سيجارة مدتها 5 دقائق تسرق تعب أسبوعين.

قم حالاً اشرب كوباية مية متلجة، واغسل وشك، وقولي حسيت بإيه بعد ما تشرب؟ أنا مستنيك هنا ومش هسيبك.`;
      }
      return `I hear you loud and clear, ${userName}. That wave of craving feels intense right now, but please take a deep breath with me.

Remember: cravings are neurochemical waves that peak within 3 to 5 minutes, then fade. You don't have to fight it — just ride it out.

Take a 4-7-8 breath with me right now:
Inhale slowly for 4s... Hold for 7s... Exhale smoothly for 8s.

Your sensor confirms you are at **${latestReading.nicotinePpm} ppm (${latestReading.level})**. Your ${streakDays}-day streak is proof that you are winning this battle. Drink a full glass of cold water right now. I am right here with you.`;
    }

    // 2. Slip-up / Guilt / Relapse ("شربت سيجارة", "ضعفت", "انتكست", "relapse", "failed")
    if (
      text.includes('شربت سيجارة') ||
      text.includes('ضعفت') ||
      text.includes('انتكست') ||
      text.includes('لخبطت') ||
      text.includes('حاسس بالذنب') ||
      text.includes('حاسس بإحباط') ||
      text.includes('relapse') ||
      text.includes('slipped') ||
      text.includes('smoked')
    ) {
      if (isArabic) {
        return `يا ${userName}، أول حاجة عايزك تعملها: **بلاش تجلد نفسك إطلاقاً**. 

الإقلاع عن عادة بقالها سنين رحلة صعبة، والتعثر خطوة واردة جداً وبتحصل لكل الأبطال اللي قدروا يبطلوا في النهاية. دي مش نقطة النهاية، دي مجرد "كبوة" في طريق طويل.

السؤال المهم مش "ليه أنا فشلت؟" (لأنك ما فشلتش)، السؤال هو:
**إيه الموقف أو الشعور اللي حصل وخلاك تضعف؟** 
هل كان ضغط شغل مفاجئ؟ زعل من حد؟ قعدة مع صحاب مدخنين؟

ارمِ العلبة أو الولاعة دلوقتي، خد شاور دافي أو اشرب شاي بالنعناع، وخلينا نكمل خطتنا فوراً. الـ ${streakDays} يوم اللي فاتوا مضاعوش وجسمك استفاد منهم بكل تأكيد. احكيلي، إيه اللي ضايقك النهاردة؟`;
      }
      return `Please pause and take a gentle breath, ${userName}. Do not beat yourself up or feel ashamed.

Recovery from nicotine is rarely a straight line. A slip-up does NOT erase your ${streakDays} days of clean progress. Your body still benefited immensely from every smoke-free hour.

Instead of self-criticism, let's treat this with curiosity: what was the trigger? Was it stress, loneliness, fatigue, or social pressure?

Extinguish it, wash your face, and let's get right back on track. I believe in your resilience. How are you feeling right now emotionally?`;
    }

    // 3. Stress / Anxiety / Depression / Overwhelm ("مخنوق", "مضغوط", "تعبان", "stress", "anxious")
    if (
      text.includes('مخنوق') ||
      text.includes('مضغوط') ||
      text.includes('قلقان') ||
      text.includes('تعبان') ||
      text.includes('متوتر') ||
      text.includes('مشاكل') ||
      text.includes('stress') ||
      text.includes('anxious') ||
      text.includes('depressed')
    ) {
      if (isArabic) {
        return `سلامتك من كل ضيق يا ${userName}.. أنا حاسس بحجم الضغط والتوتر اللي عليك. 

المخ في أوقات التوتر متعود يطلب سيجارة لأنه رابط النيكوتين بجرعة دوبامين سريعة تخدّر الإحساس، بس في الحقيقة النيكوتين بيرفع ضربات القلب وبيزود هرمونات التوتر (الكورتيزول). يعني السيجارة بتوهمك بالهدوء وهي بتزود التوتر الفسيولوجي.

إيه رأيك نفك الضغط ده بطريقة تانية؟
1. احكيلي إيه أكتر حاجة مسببالك توتر النهاردة، الفضفضة بتفرغ الحمل.
2. انزل اتمشى 10 دقائق في الهواء، الحركة بتفرز إندورفين طبيعي يهديك.
3. امسك حاجة في إيدك (مسبحة، قلم، كورة ضغط) عشان تبدد طاقة التوتر العصبية.

أنا سامعك وبجانبك دايماً، إيه اللي شاغل تفكيرك؟`;
      }
      return `I hear the exhaustion and tension in your words, ${userName}. When stress mounts, our brains trick us into believing nicotine relieves anxiety — but clinically, nicotine is a stimulant that raises heart rate and cortisol.

Let's ground your nervous system together:
Try naming 3 things you can see around you right now, 2 things you can touch, and 1 sound you can hear.

Tell me what's causing this intense pressure today? Talking it out often relieves the burden far more than smoke ever could.`;
    }

    // 4. Hardware Sensor & Health Inquiries ("الجهاز", "قراءة", "حساس", "النيكوتين", "sensor", "reading")
    if (
      text.includes('الجهاز') ||
      text.includes('الحساس') ||
      text.includes('قراءة') ||
      text.includes('النيكوتين') ||
      text.includes('sensor') ||
      text.includes('device') ||
      text.includes('reading')
    ) {
      const isLow = latestReading.level === 'low';
      if (isArabic) {
        return `بخصوص قراءات جهاز الـ SMOCII Companion Sensor بتاعك يا ${userName}:

📊 **آخر قراءة رصدها الحساس:** ${latestReading.nicotinePpm} ppm (${isLow ? 'مستوى منخفض ومثالي 🟢' : 'مستوى مرتفع 🔴'})
🔋 **شحن بطارية الحساس:** 88%
🔥 **سلسلة الأيام النظيفة (Streak):** ${streakDays} يوم

${
  isLow
    ? 'النتيجة دي تدعو للفخر! جسمك ورئتيك بيتخلصوا من ترسبات النيكوتين بشكل ملموس، والدورة الدموية بتتحسن كل ساعة.'
    : 'الحساس رصد ارتفاع طفيف، وده تنبيه ذكي لينا عشان نوقف أي سحبات وندي فرصة للكبد والكلى يصفوا النيكوتين في الساعتين الجايين.'
}

تحب نسجل فحص جديد مع بعض ونشوف التطور؟`;
      }
      return `Here is your companion sensor breakdown, ${userName}:

📊 **Latest Reading:** ${latestReading.nicotinePpm} ppm (${latestReading.level.toUpperCase()})
🔋 **Battery:** 88%
🔥 **Current Streak:** ${streakDays} smoke-free days

${
  isLow
    ? 'This is incredible! Your circulatory system and lungs are healing steadily.'
    : 'The sensor noted elevated nicotine. Let us use this reading to prevent further puffs for the next 2 hours and hydrate well.'
}

Would you like to run a fresh breath check together?`;
    }

    // 5. General Caring & Friendly Fallback
    if (isArabic) {
      return `يا هلا بيك يا ${userName}، دايماً بكون سعيد لما بتكلمني! 

أنا هنا كصديق ومدرب شخصي ليك في رحلتك للتعافي من التدخين، ومهمتي الأساسية إني أسمعك، أشجعك، وأقف جنبك في أصعب الأوقات ومن غير أي أحكام مسبقة.

قولي، يومك ماشي إزاي لحد دلوقتي؟ هل واجهت أي رغبة في التدخين، ولا محتاج نصيحة في خطة معينة؟`;
    }

    return `Hello ${userName}! It is always a pleasure to hear from you. 

I am here as your dedicated, non-judgmental quit companion. Whether you need immediate craving relief, want to understand your sensor trends, or just need to vent about a stressful day — I am listening.

How is your day going so far?`;
  }

  async _callGeminiAPI({ userMessage, userName, latestReading, streakDays, currentPhase }) {
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${this.geminiApiKey}`;

    const systemPrompt = `You are SMOCII AI Coach, an extraordinarily empathetic, compassionate, and warm companion helping ${userName} quit smoking.
User Context:
- Name: ${userName}
- Current Clean Streak: ${streakDays} days
- Latest Companion Sensor Reading: ${latestReading.nicotinePpm} ppm (${latestReading.level})
- Treatment Roadmap: ${currentPhase}

Instructions:
1. Speak with genuine warmth, deep psychological empathy, and compassionate validation.
2. Acknowledge and validate feelings first before offering practical tools.
3. Use the 4 D's (Delay, Deep Breathe, Drink Water, Distract) for acute cravings.
4. If the user mentions a slip-up/relapse, never shame or judge. Frame it as learning data.
5. Answer in the same language as the user (Egyptian Arabic if they write in Arabic, English if they write in English).
6. Keep formatting clean with friendly emojis.`;

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [{ text: `${systemPrompt}\n\nUser Message: "${userMessage}"` }],
          },
        ],
      }),
    });

    if (!response.ok) {
      throw new Error(`Gemini HTTP error ${response.status}`);
    }

    const data = await response.json();
    const candidate = data.candidates?.[0]?.content?.parts?.[0]?.text;
    return candidate || null;
  }
}

module.exports = new AiCoachEngine();
