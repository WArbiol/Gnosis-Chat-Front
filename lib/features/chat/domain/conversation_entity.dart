import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';

part 'conversation_entity.freezed.dart';

@freezed
class ConversationEntity with _$ConversationEntity {
  const factory ConversationEntity({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<MessageEntity> messages,
  }) = _ConversationEntity;
}
