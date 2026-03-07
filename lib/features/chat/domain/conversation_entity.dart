import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';

part 'conversation_entity.freezed.dart';
part 'conversation_entity.g.dart';

@freezed
class ConversationEntity with _$ConversationEntity {
  const factory ConversationEntity({
    required String id,
    required String title,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @Default([]) List<MessageEntity> messages,
    @Default(0) int messageCount,
    String? lastMessagePreview,
  }) = _ConversationEntity;

  factory ConversationEntity.fromJson(Map<String, dynamic> json) =>
      _$ConversationEntityFromJson(json);
}
