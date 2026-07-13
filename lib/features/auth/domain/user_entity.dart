import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @Default('free') String plan,
    @JsonKey(name: 'chamber_level') @Default(1) int chamberLevel,
    @JsonKey(name: 'question_count') @Default(0) int questionCount,
    @JsonKey(name: 'subscription_status') @Default('free') String subscriptionStatus,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}
