// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MessageEntity _$MessageEntityFromJson(Map<String, dynamic> json) {
  return _MessageEntity.fromJson(json);
}

/// @nodoc
mixin _$MessageEntity {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  MessageRole get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get timestamp => throw _privateConstructorUsedError;
  List<CitationEntity> get citations => throw _privateConstructorUsedError;
  @JsonKey(name: 'suggested_followups')
  List<String> get suggestedFollowups => throw _privateConstructorUsedError;
  String get route => throw _privateConstructorUsedError;

  /// Serializes this MessageEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageEntityCopyWith<MessageEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageEntityCopyWith<$Res> {
  factory $MessageEntityCopyWith(
    MessageEntity value,
    $Res Function(MessageEntity) then,
  ) = _$MessageEntityCopyWithImpl<$Res, MessageEntity>;
  @useResult
  $Res call({
    String id,
    String content,
    MessageRole role,
    @JsonKey(name: 'created_at') DateTime timestamp,
    List<CitationEntity> citations,
    @JsonKey(name: 'suggested_followups') List<String> suggestedFollowups,
    String route,
  });
}

/// @nodoc
class _$MessageEntityCopyWithImpl<$Res, $Val extends MessageEntity>
    implements $MessageEntityCopyWith<$Res> {
  _$MessageEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? role = null,
    Object? timestamp = null,
    Object? citations = null,
    Object? suggestedFollowups = null,
    Object? route = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as MessageRole,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            citations: null == citations
                ? _value.citations
                : citations // ignore: cast_nullable_to_non_nullable
                      as List<CitationEntity>,
            suggestedFollowups: null == suggestedFollowups
                ? _value.suggestedFollowups
                : suggestedFollowups // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            route: null == route
                ? _value.route
                : route // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageEntityImplCopyWith<$Res>
    implements $MessageEntityCopyWith<$Res> {
  factory _$$MessageEntityImplCopyWith(
    _$MessageEntityImpl value,
    $Res Function(_$MessageEntityImpl) then,
  ) = __$$MessageEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String content,
    MessageRole role,
    @JsonKey(name: 'created_at') DateTime timestamp,
    List<CitationEntity> citations,
    @JsonKey(name: 'suggested_followups') List<String> suggestedFollowups,
    String route,
  });
}

/// @nodoc
class __$$MessageEntityImplCopyWithImpl<$Res>
    extends _$MessageEntityCopyWithImpl<$Res, _$MessageEntityImpl>
    implements _$$MessageEntityImplCopyWith<$Res> {
  __$$MessageEntityImplCopyWithImpl(
    _$MessageEntityImpl _value,
    $Res Function(_$MessageEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? role = null,
    Object? timestamp = null,
    Object? citations = null,
    Object? suggestedFollowups = null,
    Object? route = null,
  }) {
    return _then(
      _$MessageEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as MessageRole,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        citations: null == citations
            ? _value._citations
            : citations // ignore: cast_nullable_to_non_nullable
                  as List<CitationEntity>,
        suggestedFollowups: null == suggestedFollowups
            ? _value._suggestedFollowups
            : suggestedFollowups // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        route: null == route
            ? _value.route
            : route // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageEntityImpl implements _MessageEntity {
  const _$MessageEntityImpl({
    required this.id,
    required this.content,
    required this.role,
    @JsonKey(name: 'created_at') required this.timestamp,
    final List<CitationEntity> citations = const [],
    @JsonKey(name: 'suggested_followups')
    final List<String> suggestedFollowups = const [],
    this.route = '',
  }) : _citations = citations,
       _suggestedFollowups = suggestedFollowups;

  factory _$MessageEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
  @override
  final MessageRole role;
  @override
  @JsonKey(name: 'created_at')
  final DateTime timestamp;
  final List<CitationEntity> _citations;
  @override
  @JsonKey()
  List<CitationEntity> get citations {
    if (_citations is EqualUnmodifiableListView) return _citations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_citations);
  }

  final List<String> _suggestedFollowups;
  @override
  @JsonKey(name: 'suggested_followups')
  List<String> get suggestedFollowups {
    if (_suggestedFollowups is EqualUnmodifiableListView)
      return _suggestedFollowups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_suggestedFollowups);
  }

  @override
  @JsonKey()
  final String route;

  @override
  String toString() {
    return 'MessageEntity(id: $id, content: $content, role: $role, timestamp: $timestamp, citations: $citations, suggestedFollowups: $suggestedFollowups, route: $route)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(
              other._citations,
              _citations,
            ) &&
            const DeepCollectionEquality().equals(
              other._suggestedFollowups,
              _suggestedFollowups,
            ) &&
            (identical(other.route, route) || other.route == route));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    content,
    role,
    timestamp,
    const DeepCollectionEquality().hash(_citations),
    const DeepCollectionEquality().hash(_suggestedFollowups),
    route,
  );

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageEntityImplCopyWith<_$MessageEntityImpl> get copyWith =>
      __$$MessageEntityImplCopyWithImpl<_$MessageEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageEntityImplToJson(this);
  }
}

abstract class _MessageEntity implements MessageEntity {
  const factory _MessageEntity({
    required final String id,
    required final String content,
    required final MessageRole role,
    @JsonKey(name: 'created_at') required final DateTime timestamp,
    final List<CitationEntity> citations,
    @JsonKey(name: 'suggested_followups') final List<String> suggestedFollowups,
    final String route,
  }) = _$MessageEntityImpl;

  factory _MessageEntity.fromJson(Map<String, dynamic> json) =
      _$MessageEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  MessageRole get role;
  @override
  @JsonKey(name: 'created_at')
  DateTime get timestamp;
  @override
  List<CitationEntity> get citations;
  @override
  @JsonKey(name: 'suggested_followups')
  List<String> get suggestedFollowups;
  @override
  String get route;

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageEntityImplCopyWith<_$MessageEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CitationEntity _$CitationEntityFromJson(Map<String, dynamic> json) {
  return _CitationEntity.fromJson(json);
}

/// @nodoc
mixin _$CitationEntity {
  @JsonKey(name: 'pdf_name')
  String get pdfName => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  String get snippet => throw _privateConstructorUsedError;

  /// Serializes this CitationEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CitationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CitationEntityCopyWith<CitationEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CitationEntityCopyWith<$Res> {
  factory $CitationEntityCopyWith(
    CitationEntity value,
    $Res Function(CitationEntity) then,
  ) = _$CitationEntityCopyWithImpl<$Res, CitationEntity>;
  @useResult
  $Res call({
    @JsonKey(name: 'pdf_name') String pdfName,
    int page,
    String snippet,
  });
}

/// @nodoc
class _$CitationEntityCopyWithImpl<$Res, $Val extends CitationEntity>
    implements $CitationEntityCopyWith<$Res> {
  _$CitationEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CitationEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfName = null,
    Object? page = null,
    Object? snippet = null,
  }) {
    return _then(
      _value.copyWith(
            pdfName: null == pdfName
                ? _value.pdfName
                : pdfName // ignore: cast_nullable_to_non_nullable
                      as String,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            snippet: null == snippet
                ? _value.snippet
                : snippet // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CitationEntityImplCopyWith<$Res>
    implements $CitationEntityCopyWith<$Res> {
  factory _$$CitationEntityImplCopyWith(
    _$CitationEntityImpl value,
    $Res Function(_$CitationEntityImpl) then,
  ) = __$$CitationEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'pdf_name') String pdfName,
    int page,
    String snippet,
  });
}

/// @nodoc
class __$$CitationEntityImplCopyWithImpl<$Res>
    extends _$CitationEntityCopyWithImpl<$Res, _$CitationEntityImpl>
    implements _$$CitationEntityImplCopyWith<$Res> {
  __$$CitationEntityImplCopyWithImpl(
    _$CitationEntityImpl _value,
    $Res Function(_$CitationEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CitationEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfName = null,
    Object? page = null,
    Object? snippet = null,
  }) {
    return _then(
      _$CitationEntityImpl(
        pdfName: null == pdfName
            ? _value.pdfName
            : pdfName // ignore: cast_nullable_to_non_nullable
                  as String,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        snippet: null == snippet
            ? _value.snippet
            : snippet // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CitationEntityImpl implements _CitationEntity {
  const _$CitationEntityImpl({
    @JsonKey(name: 'pdf_name') required this.pdfName,
    required this.page,
    this.snippet = '',
  });

  factory _$CitationEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$CitationEntityImplFromJson(json);

  @override
  @JsonKey(name: 'pdf_name')
  final String pdfName;
  @override
  final int page;
  @override
  @JsonKey()
  final String snippet;

  @override
  String toString() {
    return 'CitationEntity(pdfName: $pdfName, page: $page, snippet: $snippet)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CitationEntityImpl &&
            (identical(other.pdfName, pdfName) || other.pdfName == pdfName) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.snippet, snippet) || other.snippet == snippet));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pdfName, page, snippet);

  /// Create a copy of CitationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CitationEntityImplCopyWith<_$CitationEntityImpl> get copyWith =>
      __$$CitationEntityImplCopyWithImpl<_$CitationEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CitationEntityImplToJson(this);
  }
}

abstract class _CitationEntity implements CitationEntity {
  const factory _CitationEntity({
    @JsonKey(name: 'pdf_name') required final String pdfName,
    required final int page,
    final String snippet,
  }) = _$CitationEntityImpl;

  factory _CitationEntity.fromJson(Map<String, dynamic> json) =
      _$CitationEntityImpl.fromJson;

  @override
  @JsonKey(name: 'pdf_name')
  String get pdfName;
  @override
  int get page;
  @override
  String get snippet;

  /// Create a copy of CitationEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CitationEntityImplCopyWith<_$CitationEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
