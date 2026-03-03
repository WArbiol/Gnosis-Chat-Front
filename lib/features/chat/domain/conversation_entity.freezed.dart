// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ConversationEntity {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<MessageEntity> get messages => throw _privateConstructorUsedError;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationEntityCopyWith<ConversationEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationEntityCopyWith<$Res> {
  factory $ConversationEntityCopyWith(
    ConversationEntity value,
    $Res Function(ConversationEntity) then,
  ) = _$ConversationEntityCopyWithImpl<$Res, ConversationEntity>;
  @useResult
  $Res call({
    String id,
    String title,
    DateTime createdAt,
    DateTime updatedAt,
    List<MessageEntity> messages,
  });
}

/// @nodoc
class _$ConversationEntityCopyWithImpl<$Res, $Val extends ConversationEntity>
    implements $ConversationEntityCopyWith<$Res> {
  _$ConversationEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? messages = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            messages: null == messages
                ? _value.messages
                : messages // ignore: cast_nullable_to_non_nullable
                      as List<MessageEntity>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConversationEntityImplCopyWith<$Res>
    implements $ConversationEntityCopyWith<$Res> {
  factory _$$ConversationEntityImplCopyWith(
    _$ConversationEntityImpl value,
    $Res Function(_$ConversationEntityImpl) then,
  ) = __$$ConversationEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    DateTime createdAt,
    DateTime updatedAt,
    List<MessageEntity> messages,
  });
}

/// @nodoc
class __$$ConversationEntityImplCopyWithImpl<$Res>
    extends _$ConversationEntityCopyWithImpl<$Res, _$ConversationEntityImpl>
    implements _$$ConversationEntityImplCopyWith<$Res> {
  __$$ConversationEntityImplCopyWithImpl(
    _$ConversationEntityImpl _value,
    $Res Function(_$ConversationEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? messages = null,
  }) {
    return _then(
      _$ConversationEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        messages: null == messages
            ? _value._messages
            : messages // ignore: cast_nullable_to_non_nullable
                  as List<MessageEntity>,
      ),
    );
  }
}

/// @nodoc

class _$ConversationEntityImpl implements _ConversationEntity {
  const _$ConversationEntityImpl({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    final List<MessageEntity> messages = const [],
  }) : _messages = messages;

  @override
  final String id;
  @override
  final String title;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final List<MessageEntity> _messages;
  @override
  @JsonKey()
  List<MessageEntity> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'ConversationEntity(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_messages),
  );

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationEntityImplCopyWith<_$ConversationEntityImpl> get copyWith =>
      __$$ConversationEntityImplCopyWithImpl<_$ConversationEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _ConversationEntity implements ConversationEntity {
  const factory _ConversationEntity({
    required final String id,
    required final String title,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final List<MessageEntity> messages,
  }) = _$ConversationEntityImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  List<MessageEntity> get messages;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationEntityImplCopyWith<_$ConversationEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
