// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

QuizQuestion _$QuizQuestionFromJson(Map<String, dynamic> json) {
  return _QuizQuestion.fromJson(json);
}

/// @nodoc
mixin _$QuizQuestion {
  String get id => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get contextText => throw _privateConstructorUsedError;
  List<String> get options => throw _privateConstructorUsedError;
  List<String> get romaji => throw _privateConstructorUsedError;
  List<String> get englishMeanings => throw _privateConstructorUsedError;
  List<String> get optionImages => throw _privateConstructorUsedError;
  List<String> get explanations => throw _privateConstructorUsedError;
  List<String> get exampleSentences => throw _privateConstructorUsedError;
  String get difficulty => throw _privateConstructorUsedError;
  int get answerIndex => throw _privateConstructorUsedError;

  /// Serializes this QuizQuestion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizQuestionCopyWith<QuizQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizQuestionCopyWith<$Res> {
  factory $QuizQuestionCopyWith(
    QuizQuestion value,
    $Res Function(QuizQuestion) then,
  ) = _$QuizQuestionCopyWithImpl<$Res, QuizQuestion>;
  @useResult
  $Res call({
    String id,
    String imageUrl,
    String contextText,
    List<String> options,
    List<String> romaji,
    List<String> englishMeanings,
    List<String> optionImages,
    List<String> explanations,
    List<String> exampleSentences,
    String difficulty,
    int answerIndex,
  });
}

/// @nodoc
class _$QuizQuestionCopyWithImpl<$Res, $Val extends QuizQuestion>
    implements $QuizQuestionCopyWith<$Res> {
  _$QuizQuestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imageUrl = null,
    Object? contextText = null,
    Object? options = null,
    Object? romaji = null,
    Object? englishMeanings = null,
    Object? optionImages = null,
    Object? explanations = null,
    Object? exampleSentences = null,
    Object? difficulty = null,
    Object? answerIndex = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            contextText: null == contextText
                ? _value.contextText
                : contextText // ignore: cast_nullable_to_non_nullable
                      as String,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            romaji: null == romaji
                ? _value.romaji
                : romaji // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            englishMeanings: null == englishMeanings
                ? _value.englishMeanings
                : englishMeanings // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            optionImages: null == optionImages
                ? _value.optionImages
                : optionImages // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            explanations: null == explanations
                ? _value.explanations
                : explanations // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            exampleSentences: null == exampleSentences
                ? _value.exampleSentences
                : exampleSentences // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            difficulty: null == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                      as String,
            answerIndex: null == answerIndex
                ? _value.answerIndex
                : answerIndex // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuizQuestionImplCopyWith<$Res>
    implements $QuizQuestionCopyWith<$Res> {
  factory _$$QuizQuestionImplCopyWith(
    _$QuizQuestionImpl value,
    $Res Function(_$QuizQuestionImpl) then,
  ) = __$$QuizQuestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String imageUrl,
    String contextText,
    List<String> options,
    List<String> romaji,
    List<String> englishMeanings,
    List<String> optionImages,
    List<String> explanations,
    List<String> exampleSentences,
    String difficulty,
    int answerIndex,
  });
}

/// @nodoc
class __$$QuizQuestionImplCopyWithImpl<$Res>
    extends _$QuizQuestionCopyWithImpl<$Res, _$QuizQuestionImpl>
    implements _$$QuizQuestionImplCopyWith<$Res> {
  __$$QuizQuestionImplCopyWithImpl(
    _$QuizQuestionImpl _value,
    $Res Function(_$QuizQuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imageUrl = null,
    Object? contextText = null,
    Object? options = null,
    Object? romaji = null,
    Object? englishMeanings = null,
    Object? optionImages = null,
    Object? explanations = null,
    Object? exampleSentences = null,
    Object? difficulty = null,
    Object? answerIndex = null,
  }) {
    return _then(
      _$QuizQuestionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        contextText: null == contextText
            ? _value.contextText
            : contextText // ignore: cast_nullable_to_non_nullable
                  as String,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        romaji: null == romaji
            ? _value._romaji
            : romaji // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        englishMeanings: null == englishMeanings
            ? _value._englishMeanings
            : englishMeanings // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        optionImages: null == optionImages
            ? _value._optionImages
            : optionImages // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        explanations: null == explanations
            ? _value._explanations
            : explanations // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        exampleSentences: null == exampleSentences
            ? _value._exampleSentences
            : exampleSentences // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        difficulty: null == difficulty
            ? _value.difficulty
            : difficulty // ignore: cast_nullable_to_non_nullable
                  as String,
        answerIndex: null == answerIndex
            ? _value.answerIndex
            : answerIndex // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizQuestionImpl implements _QuizQuestion {
  const _$QuizQuestionImpl({
    required this.id,
    required this.imageUrl,
    required this.contextText,
    required final List<String> options,
    required final List<String> romaji,
    required final List<String> englishMeanings,
    required final List<String> optionImages,
    required final List<String> explanations,
    required final List<String> exampleSentences,
    required this.difficulty,
    required this.answerIndex,
  }) : _options = options,
       _romaji = romaji,
       _englishMeanings = englishMeanings,
       _optionImages = optionImages,
       _explanations = explanations,
       _exampleSentences = exampleSentences;

  factory _$QuizQuestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizQuestionImplFromJson(json);

  @override
  final String id;
  @override
  final String imageUrl;
  @override
  final String contextText;
  final List<String> _options;
  @override
  List<String> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  final List<String> _romaji;
  @override
  List<String> get romaji {
    if (_romaji is EqualUnmodifiableListView) return _romaji;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_romaji);
  }

  final List<String> _englishMeanings;
  @override
  List<String> get englishMeanings {
    if (_englishMeanings is EqualUnmodifiableListView) return _englishMeanings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_englishMeanings);
  }

  final List<String> _optionImages;
  @override
  List<String> get optionImages {
    if (_optionImages is EqualUnmodifiableListView) return _optionImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_optionImages);
  }

  final List<String> _explanations;
  @override
  List<String> get explanations {
    if (_explanations is EqualUnmodifiableListView) return _explanations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_explanations);
  }

  final List<String> _exampleSentences;
  @override
  List<String> get exampleSentences {
    if (_exampleSentences is EqualUnmodifiableListView)
      return _exampleSentences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exampleSentences);
  }

  @override
  final String difficulty;
  @override
  final int answerIndex;

  @override
  String toString() {
    return 'QuizQuestion(id: $id, imageUrl: $imageUrl, contextText: $contextText, options: $options, romaji: $romaji, englishMeanings: $englishMeanings, optionImages: $optionImages, explanations: $explanations, exampleSentences: $exampleSentences, difficulty: $difficulty, answerIndex: $answerIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizQuestionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.contextText, contextText) ||
                other.contextText == contextText) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            const DeepCollectionEquality().equals(other._romaji, _romaji) &&
            const DeepCollectionEquality().equals(
              other._englishMeanings,
              _englishMeanings,
            ) &&
            const DeepCollectionEquality().equals(
              other._optionImages,
              _optionImages,
            ) &&
            const DeepCollectionEquality().equals(
              other._explanations,
              _explanations,
            ) &&
            const DeepCollectionEquality().equals(
              other._exampleSentences,
              _exampleSentences,
            ) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.answerIndex, answerIndex) ||
                other.answerIndex == answerIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    imageUrl,
    contextText,
    const DeepCollectionEquality().hash(_options),
    const DeepCollectionEquality().hash(_romaji),
    const DeepCollectionEquality().hash(_englishMeanings),
    const DeepCollectionEquality().hash(_optionImages),
    const DeepCollectionEquality().hash(_explanations),
    const DeepCollectionEquality().hash(_exampleSentences),
    difficulty,
    answerIndex,
  );

  /// Create a copy of QuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizQuestionImplCopyWith<_$QuizQuestionImpl> get copyWith =>
      __$$QuizQuestionImplCopyWithImpl<_$QuizQuestionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizQuestionImplToJson(this);
  }
}

abstract class _QuizQuestion implements QuizQuestion {
  const factory _QuizQuestion({
    required final String id,
    required final String imageUrl,
    required final String contextText,
    required final List<String> options,
    required final List<String> romaji,
    required final List<String> englishMeanings,
    required final List<String> optionImages,
    required final List<String> explanations,
    required final List<String> exampleSentences,
    required final String difficulty,
    required final int answerIndex,
  }) = _$QuizQuestionImpl;

  factory _QuizQuestion.fromJson(Map<String, dynamic> json) =
      _$QuizQuestionImpl.fromJson;

  @override
  String get id;
  @override
  String get imageUrl;
  @override
  String get contextText;
  @override
  List<String> get options;
  @override
  List<String> get romaji;
  @override
  List<String> get englishMeanings;
  @override
  List<String> get optionImages;
  @override
  List<String> get explanations;
  @override
  List<String> get exampleSentences;
  @override
  String get difficulty;
  @override
  int get answerIndex;

  /// Create a copy of QuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizQuestionImplCopyWith<_$QuizQuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
