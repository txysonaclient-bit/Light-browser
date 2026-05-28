import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

// ── AI ENGINE ─────────────────────────────────────────────
class AIEngine {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  // Replace with your API key or leave empty (user enters in settings)
  static String apiKey = '';

  static Future<String> ask({
    required String question,
    String? pageContent,
    String? pageUrl,
  }) async {
    if (apiKey.isEmpty) {
      return '⚠️ AI Key not set. Go to Settings → AI to add your Claude API key.';
    }

    final systemPrompt = pageContent != null
        ? 'You are a helpful browser assistant. The user is on: $pageUrl\n\nPage content:\n${pageContent.substring(0, pageContent.length.clamp(0, 3000))}\n\nAnswer user questions about this page concisely.'
        : 'You are Light Browser\'s AI assistant. Answer concisely and helpfully.';

    try {
      final res = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 500,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': question}
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['content'][0]['text'] as String;
      } else {
        return '❌ Error: ${res.statusCode}. Check your API key.';
      }
    } catch (e) {
      return '❌ Network error. Check connection.';
    }
  }

  static Future<String> summarizePage(String content, String url) =>
      ask(
        question: 'Summarize this page in 5 bullet points.',
        pageContent: content,
        pageUrl: url,
      );

  static Future<String> translatePage(String content, String lang) =>
      ask(
        question: 'Translate the main content to $lang.',
        pageContent: content,
      );
}

// ── AI PANEL WIDGET ───────────────────────────────────────
class AiAssistantPanel extends StatefulWidget {
  final String currentUrl;
  final Future<String> Function() getPageText;
  final VoidCallback onClose;

  const AiAssistantPanel({
    super.key,
    required this.currentUrl,
    required this.getPageText,
    required this.onClose,
  });

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  late AnimationController _anim;
  late Animation<Offset> _slide;

  List<_Msg> _msgs = [];
  bool _loading = false;
  String? _pageText;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
    _loadPage();
  }

  Future<void> _loadPage() async {
    _pageText = await widget.getPageText();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(text: text, isUser: true));
      _loading = true;
    });
    _scrollDown();

    final reply = await AIEngine.ask(
      question: text,
      pageContent: _pageText,
      pageUrl: widget.currentUrl,
    );

    setState(() {
      _msgs.add(_Msg(text: reply, isUser: false));
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _quickAction(String action) {
    switch (action) {
      case 'summarize':
        _send('Summarize this page in 5 bullet points');
        break;
      case 'translate':
        _send('Translate the main content to Hindi');
        break;
      case 'facts':
        _send('What are the key facts on this page?');
        break;
      case 'safe':
        _send('Is this website safe and trustworthy?');
        break;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: LightTheme.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: LightTheme.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: LightGradients.brand,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Light AI', style: TextStyle(
                    color: LightTheme.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
                  Text('Ask anything about this page', style: TextStyle(
                    color: LightTheme.darkTextSec,
                    fontSize: 11,
                  )),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close, color: LightTheme.darkTextSec, size: 18),
              ),
            ]),
          ),

          // Quick Actions
          if (_msgs.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                _QuickBtn('📋 Summarize', () => _quickAction('summarize')),
                _QuickBtn('🌐 Translate', () => _quickAction('translate')),
                _QuickBtn('📌 Key Facts', () => _quickAction('facts')),
                _QuickBtn('🛡️ Is Safe?', () => _quickAction('safe')),
              ]),
            ),

          const Divider(color: LightTheme.darkBorder, height: 1),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _msgs.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _msgs.length) return const _TypingIndicator();
                return _MsgBubble(msg: _msgs[i]);
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: LightTheme.darkBorder)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: LightTheme.darkText, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ask about this page...',
                    hintStyle: const TextStyle(color: LightTheme.darkTextSec),
                    filled: true,
                    fillColor: LightTheme.darkSurface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10,
                    ),
                  ),
                  onSubmitted: _send,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _send(_ctrl.text),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LightGradients.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ]),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LightTheme.darkSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LightTheme.darkBorder),
      ),
      child: Text(label, style: const TextStyle(
        color: LightTheme.darkText, fontSize: 12,
      )),
    ),
  );
}

class _Msg {
  final String text;
  final bool isUser;
  _Msg({required this.text, required this.isUser});
}

class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  const _MsgBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: msg.isUser ? LightGradients.brand : null,
          color: msg.isUser ? null : LightTheme.darkSurface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : LightTheme.darkText,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LightTheme.darkSurface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        _Dot(delay: 0),
        SizedBox(width: 4),
        _Dot(delay: 200),
        SizedBox(width: 4),
        _Dot(delay: 400),
      ]),
    ),
  );
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _a = Tween(begin: 0.4, end: 1.0).animate(_c);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(
      width: 6, height: 6,
      decoration: const BoxDecoration(
        color: LightTheme.primary,
        shape: BoxShape.circle,
      ),
    ),
  );
}
