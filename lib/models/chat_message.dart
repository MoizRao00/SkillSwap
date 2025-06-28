// lib/models/chat_message.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String exchangeId; // ⭐ This field is needed for the exchange
  final String senderId;
  final String text; // ⭐ Use this field consistently for the message content
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.exchangeId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  // ⭐ Correct toMap() method to save data to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exchangeId': exchangeId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp, // Firestore automatically handles DateTime objects
      'isRead': isRead,
    };
  }

  // ⭐ Correct fromMap() factory to read data from Firestore
  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      exchangeId: map['exchangeId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '', // ⭐ This correctly reads the 'text' field
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }
}