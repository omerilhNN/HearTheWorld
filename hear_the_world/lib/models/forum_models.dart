import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ForumMemory {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final DateTime timestamp;
  final String? audioUrl;
  final int? durationSeconds;
  final int likeCount;
  final int commentCount;
  final List<ForumComment> comments;
  final String? imageUrl;
  final String? imageDescription;

  ForumMemory({
    String? id,
    required this.title,
    required this.description,
    required this.authorName,
    DateTime? timestamp,
    this.audioUrl,
    this.durationSeconds,
    int? likeCount,
    int? commentCount,
    List<ForumComment>? comments,
    this.imageUrl,
    this.imageDescription,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       likeCount = likeCount ?? 0,
       commentCount = commentCount ?? 0,
       comments = comments ?? [];

  String get formattedDate =>
      DateFormat('MMM dd, yyyy • HH:mm').format(timestamp);

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final minutes = (durationSeconds! ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get accessibilityLabel {
    String label =
        'Memory: $title by $authorName, posted on ${DateFormat('MMMM dd, yyyy').format(timestamp)}. ';

    // Add image information if available
    if (imageDescription != null && imageDescription!.isNotEmpty) {
      label += 'Contains image: $imageDescription. ';
    }

    // Add description (truncated if too long)
    label +=
        '${description.length > 100 ? description.substring(0, 100) + "..." : description}';

    return label;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'authorName': authorName,
      'timestamp': timestamp.toIso8601String(),
      'audioUrl': audioUrl,
      'durationSeconds': durationSeconds,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'imageUrl': imageUrl,
      'imageDescription': imageDescription,
    };
  }

  factory ForumMemory.fromJson(Map<String, dynamic> json) {
    return ForumMemory(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      authorName: json['authorName'],
      timestamp: DateTime.parse(json['timestamp']),
      audioUrl: json['audioUrl'],
      durationSeconds: json['durationSeconds'],
      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
      comments:
          (json['comments'] as List?)
              ?.map((commentJson) => ForumComment.fromJson(commentJson))
              .toList() ??
          [],
      imageUrl: json['imageUrl'],
      imageDescription: json['imageDescription'],
    );
  }
  ForumMemory copyWith({
    String? title,
    String? description,
    String? authorName,
    String? audioUrl,
    int? durationSeconds,
    int? likeCount,
    int? commentCount,
    List<ForumComment>? comments,
    String? imageUrl,
    String? imageDescription,
  }) {
    return ForumMemory(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      timestamp: timestamp,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      comments: comments ?? List.from(this.comments),
      imageUrl: imageUrl ?? this.imageUrl,
      imageDescription: imageDescription ?? this.imageDescription,
    );
  }
}

class ForumComment {
  final String id;
  final String content;
  final String authorName;
  final DateTime timestamp;
  final String? audioUrl;

  ForumComment({
    String? id,
    required this.content,
    required this.authorName,
    DateTime? timestamp,
    this.audioUrl,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  String get formattedDate =>
      DateFormat('MMM dd, yyyy • HH:mm').format(timestamp);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'authorName': authorName,
      'timestamp': timestamp.toIso8601String(),
      'audioUrl': audioUrl,
    };
  }

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      id: json['id'],
      content: json['content'],
      authorName: json['authorName'],
      timestamp: DateTime.parse(json['timestamp']),
      audioUrl: json['audioUrl'],
    );
  }
}
