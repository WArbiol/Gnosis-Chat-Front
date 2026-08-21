import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';

part 'conversation_entity.freezed.dart';

@Freezed(toJson: false, fromJson: false)
class ConversationEntity with _$ConversationEntity {
  const ConversationEntity._();

  const factory ConversationEntity({
    required String id,
    required String title,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'is_pinned') @Default(false) bool isPinned,
    @Default([]) List<MessageEntity> messages,
    @Default(0) int messageCount,
    String? lastMessagePreview,
  }) = _ConversationEntity;

  factory ConversationEntity.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List?;
    final parsedMessages = rawMessages != null
        ? rawMessages
            .map((m) => MessageEntity.fromJson(m as Map<String, dynamic>))
            .toList()
        : <MessageEntity>[];

    return ConversationEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Nova conversa',
      createdAt: json['created_at'] != null
          ? (json['created_at'] is DateTime
              ? json['created_at'] as DateTime
              : DateTime.parse(json['created_at'].toString()))
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is DateTime
              ? json['updated_at'] as DateTime
              : DateTime.parse(json['updated_at'].toString()))
          : DateTime.now(),
      isPinned: json['is_pinned'] as bool? ?? false,
      messages: parsedMessages,
      messageCount: json['message_count'] as int? ?? parsedMessages.length,
      lastMessagePreview: json['last_message_preview'] as String? ??
          (parsedMessages.isNotEmpty ? parsedMessages.last.content : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_pinned': isPinned,
        'messages': messages.map((m) => m.toJson()).toList(),
        'message_count': messageCount,
        'last_message_preview': lastMessagePreview,
      };
}
