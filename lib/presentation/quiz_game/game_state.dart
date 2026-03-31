import 'package:playingkorean/domain/quiz/quiz_question.dart';

class GameState {
  final List<QuizQuestion> questions;
  final int currentQuestionIndex;
  final int score;
  final bool isLoading;
  final int remainingSeconds;
  final bool isFinished;
  final String? errorMessage;
  final bool? lastAnswerCorrect;
  final int? selectedOptionIndex;
  final String selectedLevel;
  final int selectedCount;
  final List<QuizQuestion> failedQuestions;

  GameState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.score = 0,
    this.isLoading = false,
    this.remainingSeconds = 20,
    this.isFinished = false,
    this.errorMessage,
    this.lastAnswerCorrect,
    this.selectedOptionIndex,
    this.selectedLevel = '1',
    this.selectedCount = 10,
    this.failedQuestions = const [],
  });

  QuizQuestion? get currentQuestion =>
      questions.isNotEmpty && currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;

  GameState copyWith({
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    int? score,
    bool? isLoading,
    int? remainingSeconds,
    bool? isFinished,
    String? errorMessage,
    bool? Function()? lastAnswerCorrect,
    int? Function()? selectedOptionIndex,
    String? selectedLevel,
    int? selectedCount,
    List<QuizQuestion>? failedQuestions,
  }) {
    return GameState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isFinished: isFinished ?? this.isFinished,
      errorMessage: errorMessage ?? this.errorMessage,
      lastAnswerCorrect: lastAnswerCorrect != null ? lastAnswerCorrect() : this.lastAnswerCorrect,
      selectedOptionIndex: selectedOptionIndex != null ? selectedOptionIndex() : this.selectedOptionIndex,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      selectedCount: selectedCount ?? this.selectedCount,
      failedQuestions: failedQuestions ?? this.failedQuestions,
    );
  }
}

sealed class GameAction {
  const GameAction();
}

class LoadQuizzes extends GameAction {
  final String difficulty;
  final int count;
  LoadQuizzes({required this.difficulty, required this.count});
}

class StartReview extends GameAction {}

class SelectOption extends GameAction {
  final int index;
  SelectOption(this.index);
}

class TickTimer extends GameAction {}

class NextQuestion extends GameAction {}

class ResetGame extends GameAction {}
