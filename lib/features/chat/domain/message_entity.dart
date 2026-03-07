import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

enum MessageRole { user, assistant }

@freezed
class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String id,
    required String content,
    required MessageRole role,
    @JsonKey(name: 'created_at') required DateTime timestamp,
    @Default([]) List<CitationEntity> citations,
    @Default('') String route,
  }) = _MessageEntity;

  factory MessageEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageEntityFromJson(json);
}

@freezed
class CitationEntity with _$CitationEntity {
  const factory CitationEntity({
    @JsonKey(name: 'pdf_name') required String pdfName,
    required int page,
    @Default('') String snippet,
  }) = _CitationEntity;

  factory CitationEntity.fromJson(Map<String, dynamic> json) =>
      _$CitationEntityFromJson(json);
}
