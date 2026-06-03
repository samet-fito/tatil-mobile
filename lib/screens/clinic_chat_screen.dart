import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ClinicChatScreen extends StatefulWidget {
  final String clinicId;
  final String clinicName;

  const ClinicChatScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
  });

  @override
  State<ClinicChatScreen> createState() => _ClinicChatScreenState();
}

class _ClinicChatScreenState extends State<ClinicChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initConversation() async {
    final supabase = Supabase.instance.client;
    final userId = await AuthService.getSessionId();

    final existing = await supabase
        .from('conversations')
        .select()
        .eq('user_id', userId)
        .eq('clinic_id', widget.clinicId)
        .eq('status', 'active')
        .maybeSingle();

    if (existing != null) {
      _conversationId = existing['id'];
    } else {
      final newConv = await supabase
          .from('conversations')
          .insert({
            'user_id': userId,
            'clinic_id': widget.clinicId,
            'subject': '${widget.clinicName} ile gorusme',
          })
          .select()
          .single();
      _conversationId = newConv['id'];

      await supabase.from('messages').insert({
        'conversation_id': _conversationId,
        'sender_id': widget.clinicId,
        'sender_type': 'ai',
        'content':
            'Merhaba! ${widget.clinicName} adina sizi karsiliyoruz. Size nasil yardimci olabiliriz?',
      });
    }

    await _loadMessages();
    _subscribeToMessages();
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    final result = await Supabase.instance.client
        .from('messages')
        .select()
        .eq('conversation_id', _conversationId!)
        .order('created_at', ascending: true);

    if (mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(result);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _subscribeToMessages() {
    if (_conversationId == null) return;
    Supabase.instance.client
        .channel('clinic_chat:$_conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: _conversationId!,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                _messages.add(Map<String, dynamic>.from(payload.newRecord));
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
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

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    final supabase = Supabase.instance.client;
    final userId = await AuthService.getSessionId();

    await supabase.from('messages').insert({
      'conversation_id': _conversationId,
      'sender_id': userId,
      'sender_type': 'user',
      'content': text,
    });

    await supabase.from('conversations').update({
      'last_message': text,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', _conversationId!);

    await Future.delayed(const Duration(seconds: 1));
    await supabase.from('messages').insert({
      'conversation_id': _conversationId,
      'sender_id': widget.clinicId,
      'sender_type': 'ai',
      'content': _generateReply(text),
    });

    if (mounted) setState(() => _isSending = false);
  }

  String _generateReply(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('fiyat') || m.contains('ucret')) {
      return 'Fiyatlarimiz tedavinin kapsamina gore degismektedir. Size ozel teklif icin iletisim bilgilerinizi paylasir misiniz?';
    } else if (m.contains('randevu') || m.contains('tarih')) {
      return 'En yakin musait tarihimiz bu hafta sonu. Size uygun mu?';
    } else if (m.contains('doktor') || m.contains('hekim')) {
      return 'Ekibimizde 10+ yil deneyimli uzman doktorlar bulunmaktadir.';
    } else if (m.contains('paket') || m.contains('dahil')) {
      return 'Paketimize ucus karsilama, VIP transfer, konaklama ve tedavi dahildir.';
    }
    return 'Tesekkur ederiz! Uzman ekibimiz en kisa surede size donecektir.';
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(CupertinoIcons.building_2_fill,
                  color: AppTheme.teal, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.clinicName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF22C55E), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Cevrimici',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ]),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Henuz mesaj yok.',
                            style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) => _buildMessage(_messages[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['sender_type'] == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(CupertinoIcons.sparkles,
                  size: 14, color: AppTheme.teal),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.teal : AppTheme.bgSecondary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg['content'] ?? '',
                      style: TextStyle(
                          fontSize: 14,
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg['created_at'] ??
                        DateTime.now().toIso8601String()),
                    style: TextStyle(
                        fontSize: 10,
                        color: isUser
                            ? Colors.white.withOpacity(0.7)
                            : AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(CupertinoIcons.person_fill,
                  size: 14, color: AppTheme.teal),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
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
                controller: _msgCtrl,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                maxLines: 3,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Mesajinizi yazin...',
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
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.teal,
                borderRadius: BorderRadius.circular(22),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.arrow_up,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}