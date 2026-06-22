import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/message_model.dart';

/// Müşteri destek sohbeti — backend `/support/chat`.
abstract final class SupportChatService {
  static const _quickReplies = [
    'Rezervasyonlarımı nerede görürüm?',
    'Ödeme ne zaman aktif olacak?',
    'İptal veya değişiklik nasıl yapılır?',
    'İade süreci nasıl işler?',
  ];

  static List<String> get defaultQuickReplies => _quickReplies;

  static Future<MessageModel> getResponse({
    required String userMessage,
    String? sessionId,
    String? reservationId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/support/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sessionId': sessionId ?? 'support-mobile',
              'message': userMessage,
              if (reservationId != null)
                'context': {'reservationId': reservationId},
            }),
          )
          .timeout(AppConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          final text = nested['message']?.toString();
          if (text != null && text.trim().isNotEmpty) {
            return MessageModel.bot(text.trim());
          }
        }
      }
    } catch (_) {}

    return MessageModel.bot(
      'Şu an canlı desteğe bağlanamadık. '
      'destek@vizegoo.com adresine yazabilir veya WhatsApp hattımızı kullanabilirsiniz.',
    );
  }
}
