import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../constants.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content':
          'Merhaba! Ben Vizegoo AI asistaniyim. Seyahat planlamanizda, otel seciminde, saglik turizmi paketlerinde veya butce hesaplamada yardimci olabilirim. Ne ogrenebilirsiniz?',
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cityName': 'Genel',
          'userMessage': text,
          'remainingBudget': 0,
        'history': _messages
    .map((m) => {'role': m['role'], 'content': m['content']})
    .toList(),
        }),
      ).timeout(const Duration(seconds: 20));

      String reply = 'Bir hata olustu, tekrar deneyin.';
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['message'] != null) {
          reply = data['message'];
        }
      }

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Baglanti hatasi. Internet baglantinizi kontrol edin.',
          });
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFFFF3B41)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(CupertinoIcons.sparkles,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vizegoo AI',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Text('Seyahat Asistani',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _isTyping) {
                  return _buildTyping();
                }
                return _buildMessage(_messages[i]);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppTheme.accent, Color(0xFFFF3B41)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(CupertinoIcons.sparkles,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 6),
                const Text('Vizegoo AI',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.accent : AppTheme.bgSecondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border:
                  isUser ? null : Border.all(color: AppTheme.border),
            ),
            child: Text(
              msg['content'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color:
                    isUser ? Colors.white : AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.accent, Color(0xFFFF3B41)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(CupertinoIcons.sparkles,
              color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: List.generate(
              3,
              (i) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1.0),
                duration: Duration(milliseconds: 500 + i * 150),
                curve: Curves.easeInOut,
                builder: (_, v, __) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(v),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.bgTertiary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Seyahat hakkinda sor...',
                  hintStyle:
                      TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.accent, Color(0xFFFF3B41)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(CupertinoIcons.arrow_up,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}