import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';

class GetQuizUseCase {
  final QuizRepository _quizRepository;

  GetQuizUseCase(this._quizRepository);

  Future<Result<List<QuizQuestion>, String>> execute() async {
    return await _quizRepository.getQuizQuestions();
  }
}
