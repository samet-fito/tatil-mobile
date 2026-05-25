import 'package:flutter/material.dart';

enum MessageType { text, card, quickReplies }

class CardData {
  final String title;
  final String subtitle;
  final String emoji;
  final String? price;
  final String? budgetNote;
  final String actionLabel;
  final Color color;

  const CardData({
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.price,
    this.budgetNote,
    this.actionLabel = 'İncele →',
    this.color = const Color(0xFF1D6B4E),
  });
}

class MessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final List<CardData>? cards;
  final List<String>? quickReplies;

  MessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.cards,
    this.quickReplies,
  });

  factory MessageModel.user(String text) => MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );

  factory MessageModel.bot(String text, {List<CardData>? cards}) => MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
        type: cards != null ? MessageType.card : MessageType.text,
        cards: cards,
      );
}