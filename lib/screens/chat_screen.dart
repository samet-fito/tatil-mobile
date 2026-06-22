import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/message_model.dart';
import '../services/ai_chat_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String cityName;
  final String destinationIata;
  final String sessionId;
  final double remainingBudget;

  const ChatScreen({
    super.key,
    required this.cityName,
    required this.destinationIata,
    required this.sessionId,
    required this.remainingBudget,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<MessageModel> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final budgetLine = widget.remainingBudget > 0
        ? 'Kalan butcen: ${widget.remainingBudget.toInt()} TL\n\n'
        : '';
    setState(() {
      _messages.add(MessageModel.bot(
        'Merhaba! Ben senin ${widget.cityName} yol arkadasinim.\n\n'
        '${budgetLine}Yemek, gezilecek yerler, ulasim veya acil durum hakkinda her seyi sorabilirsin!',
      ));
    });
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(MessageModel.user(text));
      _isTyping = true;
    });
    _scrollToBottom();

    final response = await AiChatService.getResponse(
      cityName: widget.cityName,
      userMessage: text,
      remainingBudget: widget.remainingBudget,
      destinationIata: widget.destinationIata,
    );

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(response);
    });
    _scrollToBottom();
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Center(
                child: Text('✈️', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yol Arkadasin',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Text(
                  '${widget.cityName} Rehberi · Cevrimici',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildQuickReplies(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: message.isUser ? 48 : 0,
        right: message.isUser ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('✈️', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Yol Arkadasin',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.isUser ? AppTheme.accent : AppTheme.bgSecondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                bottomRight: Radius.circular(message.isUser ? 4 : 18),
              ),
              border: message.isUser
                  ? null
                  : Border.all(color: AppTheme.border),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: message.isUser ? Colors.white : AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          if (message.cards != null && message.cards!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: message.cards!.map((c) => _buildRichCard(c)).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTime(message.timestamp),
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichCard(CardData card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: card.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(card.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: card.color)),
                      Text(card.subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (card.price != null)
                  Text(card.price!,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                if (card.budgetNote != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(card.budgetNote!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.teal)),
                  ),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${card.title} haritasi yakindan!'),
                        backgroundColor: AppTheme.teal),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: card.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(card.actionLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 48),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(14)),
            child:
                const Center(child: Text('✈️', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              children: List.generate(3, (i) => _buildDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 150)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(value),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies() {
    final replies = AiChatService.getQuickReplies(widget.cityName);
    return Container(
      height: 44,
      color: AppTheme.bgSecondary,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(replies[index]),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Text(replies[index],
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }

Widget _buildInputArea() {
  return Container(
    padding: EdgeInsets.fromLTRB(
        12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
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
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '${widget.cityName} hakkinda sor...',
                hintStyle: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _sendMessage(_controller.text),
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