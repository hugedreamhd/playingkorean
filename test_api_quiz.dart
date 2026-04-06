import 'package:playingkorean/data/services/api_service.dart';
import 'package:playingkorean/data/quiz/api_quiz_repository_impl.dart';

void main() async {
  final apiService = ApiService();
  final repository = ApiQuizRepositoryImpl(apiService);

  print('--- Testing Level 1 (Beginner) ---');
  final result = await repository.getQuizQuestions(difficulty: '1', count: 3);
  
  result.when(
    success: (questions) {
      print('Successfully fetched ${questions.length} questions.');
      for (var q in questions) {
        print('Word: ${q.options[q.answerIndex]}');
        print('Options: ${q.options}');
        print('Explanation: ${q.explanations[q.answerIndex]}');
        print('-------------------');
      }
    },
    failure: (error) {
      print('Error: $error');
    },
  );
}
