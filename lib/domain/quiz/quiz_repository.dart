import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';

abstract interface class QuizRepository {
  Future<Result<List<QuizQuestion>, String>> getQuizQuestions();
  Future<Result<bool, String>> submitAnswer(String quizId, int selectedIndex);
}
