import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smokii/const/constant.dart';
import 'package:smokii/services/ai_agent_service.dart';
import 'package:smokii/services/app_state.dart';
import 'package:smokii/widgets/craving_sos_dialog.dart';

class AiCoachPage extends StatefulWidget {
  const AiCoachPage({super.key});

  @override
  State<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends State<AiCoachPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiTyping = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text':
          'أهلاً بك يا حسين! أنا صديقك ومدربك الشخصي في SMOCII AI Coach. 💙\n\nأنا بتابع معاك قراءات حساس النيكوتين، وهدفي أكون جنبك في كل لحظة ضعف أو توتر عشان نعديها سوا من غير أي لوم أو ضغط.\n\nطمني، حاسس بإيه النهاردة؟',
      'time': 'Just now',
    }
  ];

  final List<String> _quickPrompts = [
    'انا ممكن ابطل في قد ايه؟',
    'عندي رغبة قوية في التدخين دلوقتي (Craving)',
    'اشرحلي قراءة الحساس ومستوى النيكوتين',
    'ايه اعراض الانسحاب اللي هحس بيها؟',
    'أنا متوتر ومضغوط وعايز افضفض',
    'أنا ضعفت وشربت سيجارة وحاسس بإحباط',
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text.trim(),
        'time': 'Now',
      });
      _isAiTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    String reply = '';

    // 1. Direct Gemini API if user has configured an API key
    final geminiKey = AppState().geminiApiKey;
    if (geminiKey != null && geminiKey.trim().isNotEmpty) {
      try {
        reply = await _callGeminiDirect(geminiKey.trim(), text);
      } catch (err) {
        debugPrint('Direct Gemini API error: $err');
      }
    }

    // 2. Local Backend Server if running
    if (reply.isEmpty) {
      try {
        final backendUrl = kIsWeb
            ? 'http://localhost:5000/api/v1/ai/chat'
            : 'http://127.0.0.1:5000/api/v1/ai/chat';

        reply = await _fetchBackendAiReply(backendUrl, text);
      } catch (err) {
        debugPrint('Backend fetch error: $err');
      }
    }

    // 3. Fallback to deeply empathetic local engine
    if (reply.isEmpty) {
      reply = AiAgentService().generateCoachingReply(
        text,
        AppState().latestReading,
      );
    }

    if (!mounted) return;

    setState(() {
      _isAiTyping = false;
      _messages.add({
        'isUser': false,
        'text': reply,
        'time': 'Now',
      });
    });
    _scrollToBottom();
  }

  Future<String> _callGeminiDirect(String apiKey, String userMessage) async {
    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );
    final appState = AppState();
    final systemPrompt =
        'أنت مدرب ذكي فائق التعاطف والدفء في تطبيق SMOCII لمساعدة ${appState.userName} في الإقلاع عن التدخين.\n'
        'مرجعيتك الإكلينيكية: بروتوكول عيادات الإقلاع عن التدخين بوزارة الصحة المصرية وقاعدة الـ 4D\'s.\n'
        'حالة المستخدم الحالية: قراءة حساس النيكوتين ${appState.latestReading.nicotinePpm} ppm (${appState.latestReading.levelLabel})، '
        'سلسلة الأيام النظيفة: ${appState.streakDays} يوماً.\n'
        'تحدث بلغة عربية دافئة ومتفهمة مثل طبيب نفسي وصديق مخلص، بدون أي لوم، وركز على التطمين العملي الإنساني والخطوات الملموسة.';

    final response = await http
        .post(
          endpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': '$systemPrompt\n\nسؤال المستخدم: "$userMessage"'}
                ]
              }
            ]
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidate =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        return candidate.toString().trim();
      }
    }
    throw Exception('Gemini status: ${response.statusCode}');
  }

  Future<String> _fetchBackendAiReply(String url, String message) async {
    final appState = AppState();
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userMessage': message,
            'userName': appState.userName,
            'latestReading': appState.latestReading.toJson(),
            'streakDays': appState.streakDays,
            'currentPhase': appState.currentPlan.title,
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['reply'] != null) {
        return data['reply'].toString().trim();
      }
    }
    throw Exception('Backend HTTP ${response.statusCode}');
  }

  void _showAiKeyDialog() {
    final textEdit =
        TextEditingController(text: AppState().geminiApiKey ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: primaryColor),
            SizedBox(width: 8),
            Text(
              'إعدادات الذكاء الاصطناعي',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'محرك SMOCII الطبي الإنساني يعمل حالياً تلقائياً. إذا رغبت في تفعيل ذكاء Google Gemini السحابي المباشر، أدخل الـ API Key أدناه (مجاني من aistudio.google.com):',
              style: TextStyle(fontSize: 12, color: secondaryTextColor, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textEdit,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                labelText: 'Gemini API Key (اختياري)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppState().setGeminiApiKey(null);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تفعيل المحرك الطبي الداخلي.')),
              );
            },
            child: const Text('استخدام المحرك الداخلي'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              AppState().setGeminiApiKey(textEdit.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ مفتاح Gemini بنجاح!'),
                  backgroundColor: successColor,
                ),
              );
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMOCII AI Coach',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'متصل بالحساس • مدرب داعم ومتعاطف',
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: primaryColor),
            tooltip: 'إعدادات الذكاء الاصطناعي',
            onPressed: _showAiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: dangerColor),
            tooltip: 'Craving SOS',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CravingSosDialog(),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundColor),
        child: SafeArea(
          child: Column(
            children: [
              // Compassionate guardrail banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite, size: 16, color: primaryColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مساحة آمنة تماماً، خالية من أي لوم أو أحكام. هدفنا دعمك خطوة بخطوة.',
                        style: TextStyle(fontSize: 11, color: secondaryTextColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isAiTyping) {
                      return _buildTypingBubble();
                    }

                    final msg = _messages[index];
                    final isUser = msg['isUser'] as bool;
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.82,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? primaryColor : pirmaryColorElementBG,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 20),
                          ),
                          boxShadow: cardShadow,
                        ),
                        child: Text(
                          msg['text'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isUser ? Colors.white : primaryTextColor,
                            height: 1.45,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Quick suggestion prompt chips
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickPrompts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final prompt = _quickPrompts[index];
                    return ActionChip(
                      backgroundColor: pirmaryColorElementBG,
                      elevation: 1,
                      label: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _sendMessage(prompt),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Text input bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pirmaryColorElementBG,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: _sendMessage,
                        decoration: InputDecoration(
                          hintText: 'اكتب ما تشعر به، أنا هنا لأسمعك وأساعدك...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor.withValues(alpha: 0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F5FB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: () => _sendMessage(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: pirmaryColorElementBG,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'المدرب الذكي يفكر ويكتب لك...',
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
