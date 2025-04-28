import 'package:intl/intl.dart';

enum MessageType { user, system, loading }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
  });

  String get formattedTime => DateFormat('HH:mm').format(timestamp);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.system,
      ),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatSession {
  final String id;
  final String summary;
  final DateTime timestamp;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.summary,
    required this.timestamp,
    required this.messages,
  });

  String get formattedDate =>
      DateFormat('MMM dd, yyyy • HH:mm').format(timestamp);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'summary': summary,
      'timestamp': timestamp.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      summary: json['summary'],
      timestamp: DateTime.parse(json['timestamp']),
      messages:
          (json['messages'] as List)
              .map((msgJson) => ChatMessage.fromJson(msgJson))
              .toList(),
    );
  }
}
