import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_question.freezed.dart';
part 'quiz_question.g.dart';

@freezed
class QuizQuestion with _$QuizQuestion {
  const factory QuizQuestion({
    required String id,
    required String imageUrl,
    required String contextText,
    required List<String> options,
    required List<String> romaji,
    required List<String> englishMeanings,
    required List<String> optionImages,
    required List<String> explanations,
    required List<String> exampleSentences,
    required String difficulty,
    required int answerIndex,
  }) = _QuizQuestion;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);
}
