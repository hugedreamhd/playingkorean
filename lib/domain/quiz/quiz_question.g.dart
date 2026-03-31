// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizQuestionImpl _$$QuizQuestionImplFromJson(
  Map<String, dynamic> json,
) => _$QuizQuestionImpl(
  id: json['id'] as String,
  imageUrl: json['imageUrl'] as String,
  contextText: json['contextText'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  romaji: (json['romaji'] as List<dynamic>).map((e) => e as String).toList(),
  englishDefinition: json['englishDefinition'] as String,
  englishSentence: json['englishSentence'] as String,
  difficulty: json['difficulty'] as String,
  answerIndex: (json['answerIndex'] as num).toInt(),
);

Map<String, dynamic> _$$QuizQuestionImplToJson(_$QuizQuestionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'contextText': instance.contextText,
      'options': instance.options,
      'romaji': instance.romaji,
      'englishDefinition': instance.englishDefinition,
      'englishSentence': instance.englishSentence,
      'difficulty': instance.difficulty,
      'answerIndex': instance.answerIndex,
    };
