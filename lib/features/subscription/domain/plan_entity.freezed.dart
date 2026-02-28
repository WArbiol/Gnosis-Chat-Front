// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlanEntity _$PlanEntityFromJson(Map<String, dynamic> json) {
  return _PlanEntity.fromJson(json);
}

/// @nodoc
mixin _$PlanEntity {
  PlanType get type => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  double get priceMonthly => throw _privateConstructorUsedError;
  int get questionLimit => throw _privateConstructorUsedError;
  int get interestLimit => throw _privateConstructorUsedError;
  int get chamberLevel => throw _privateConstructorUsedError;

  /// Serializes this PlanEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlanEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlanEntityCopyWith<PlanEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlanEntityCopyWith<$Res> {
  factory $PlanEntityCopyWith(
    PlanEntity value,
    $Res Function(PlanEntity) then,
  ) = _$PlanEntityCopyWithImpl<$Res, PlanEntity>;
  @useResult
  $Res call({
    PlanType type,
    String displayName,
    double priceMonthly,
    int questionLimit,
    int interestLimit,
    int chamberLevel,
  });
}

/// @nodoc
class _$PlanEntityCopyWithImpl<$Res, $Val extends PlanEntity>
    implements $PlanEntityCopyWith<$Res> {
  _$PlanEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlanEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? displayName = null,
    Object? priceMonthly = null,
    Object? questionLimit = null,
    Object? interestLimit = null,
    Object? chamberLevel = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as PlanType,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            priceMonthly: null == priceMonthly
                ? _value.priceMonthly
                : priceMonthly // ignore: cast_nullable_to_non_nullable
                      as double,
            questionLimit: null == questionLimit
                ? _value.questionLimit
                : questionLimit // ignore: cast_nullable_to_non_nullable
                      as int,
            interestLimit: null == interestLimit
                ? _value.interestLimit
                : interestLimit // ignore: cast_nullable_to_non_nullable
                      as int,
            chamberLevel: null == chamberLevel
                ? _value.chamberLevel
                : chamberLevel // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlanEntityImplCopyWith<$Res>
    implements $PlanEntityCopyWith<$Res> {
  factory _$$PlanEntityImplCopyWith(
    _$PlanEntityImpl value,
    $Res Function(_$PlanEntityImpl) then,
  ) = __$$PlanEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PlanType type,
    String displayName,
    double priceMonthly,
    int questionLimit,
    int interestLimit,
    int chamberLevel,
  });
}

/// @nodoc
class __$$PlanEntityImplCopyWithImpl<$Res>
    extends _$PlanEntityCopyWithImpl<$Res, _$PlanEntityImpl>
    implements _$$PlanEntityImplCopyWith<$Res> {
  __$$PlanEntityImplCopyWithImpl(
    _$PlanEntityImpl _value,
    $Res Function(_$PlanEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlanEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? displayName = null,
    Object? priceMonthly = null,
    Object? questionLimit = null,
    Object? interestLimit = null,
    Object? chamberLevel = null,
  }) {
    return _then(
      _$PlanEntityImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as PlanType,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        priceMonthly: null == priceMonthly
            ? _value.priceMonthly
            : priceMonthly // ignore: cast_nullable_to_non_nullable
                  as double,
        questionLimit: null == questionLimit
            ? _value.questionLimit
            : questionLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        interestLimit: null == interestLimit
            ? _value.interestLimit
            : interestLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        chamberLevel: null == chamberLevel
            ? _value.chamberLevel
            : chamberLevel // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlanEntityImpl implements _PlanEntity {
  const _$PlanEntityImpl({
    required this.type,
    required this.displayName,
    required this.priceMonthly,
    required this.questionLimit,
    required this.interestLimit,
    required this.chamberLevel,
  });

  factory _$PlanEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlanEntityImplFromJson(json);

  @override
  final PlanType type;
  @override
  final String displayName;
  @override
  final double priceMonthly;
  @override
  final int questionLimit;
  @override
  final int interestLimit;
  @override
  final int chamberLevel;

  @override
  String toString() {
    return 'PlanEntity(type: $type, displayName: $displayName, priceMonthly: $priceMonthly, questionLimit: $questionLimit, interestLimit: $interestLimit, chamberLevel: $chamberLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlanEntityImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.priceMonthly, priceMonthly) ||
                other.priceMonthly == priceMonthly) &&
            (identical(other.questionLimit, questionLimit) ||
                other.questionLimit == questionLimit) &&
            (identical(other.interestLimit, interestLimit) ||
                other.interestLimit == interestLimit) &&
            (identical(other.chamberLevel, chamberLevel) ||
                other.chamberLevel == chamberLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    displayName,
    priceMonthly,
    questionLimit,
    interestLimit,
    chamberLevel,
  );

  /// Create a copy of PlanEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlanEntityImplCopyWith<_$PlanEntityImpl> get copyWith =>
      __$$PlanEntityImplCopyWithImpl<_$PlanEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlanEntityImplToJson(this);
  }
}

abstract class _PlanEntity implements PlanEntity {
  const factory _PlanEntity({
    required final PlanType type,
    required final String displayName,
    required final double priceMonthly,
    required final int questionLimit,
    required final int interestLimit,
    required final int chamberLevel,
  }) = _$PlanEntityImpl;

  factory _PlanEntity.fromJson(Map<String, dynamic> json) =
      _$PlanEntityImpl.fromJson;

  @override
  PlanType get type;
  @override
  String get displayName;
  @override
  double get priceMonthly;
  @override
  int get questionLimit;
  @override
  int get interestLimit;
  @override
  int get chamberLevel;

  /// Create a copy of PlanEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlanEntityImplCopyWith<_$PlanEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
