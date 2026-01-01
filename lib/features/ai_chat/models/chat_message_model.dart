import 'package:equatable/equatable.dart';

/// نموذج رسالة الشات
class ChatMessageModel extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;
  final String? error;
  final int? postId; // معرف المنشور للرسائل النظام

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
    this.error,
    this.postId,
  });

  ChatMessageModel copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
    int? postId,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      postId: postId ?? this.postId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'error': error,
      'postId': postId,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
      postId: json['postId'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    content,
    role,
    timestamp,
    isLoading,
    error,
    postId,
  ];
}

/// دور المرسل
enum MessageRole { user, assistant, system }
