import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';

class MockQuizRepositoryImpl implements QuizRepository {
  @override
  Future<Result<List<QuizQuestion>, String>> getQuizQuestions({
    String? difficulty,
    int? count,
  }) async {
    // 목(Mock) 데이터를 반환하거나 실제 로직을 시뮬레이션합니다.
    final mockQuestions = [
      QuizQuestion(
        id: '1',
        imageUrl: 'https://cdn.pixabay.com/photo/2016/11/14/04/45/elephant-1822636_1280.jpg',
        contextText: '그는 학교에 [가요].',
        englishSentence: 'He goes to school.',
        options: ['가요', '가요 (song)', '가요 (request)', '가요 (price)'],
        romaji: ['gayo', 'gayo', 'gayo', 'gayo'],
        answerIndex: 0,
        englishDefinition: 'to go',
        difficulty: '1',
      ),
      // 필요한 만큼 더 추가할 수 있습니다.
    ];

    var questions = mockQuestions;
    if (difficulty != null) {
      questions = questions.where((q) => q.difficulty == difficulty).toList();
    }
    if (count != null && count < questions.length) {
      questions = questions.take(count).toList();
    }

    return Result.success(questions);
  }

  @override
  Future<Result<bool, String>> submitAnswer(String quizId, int selectedIndex) async {
    return Result.success(true);
  }
}
