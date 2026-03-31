import 'dart:async';
import 'package:playingkorean/core/audio/audio_manager.dart';
import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/get_quiz_use_case.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';
import 'package:rxdart/rxdart.dart';

class GameViewModel {
  final GetQuizUseCase _getQuizUseCase;
  final AudioManager _audioManager;
  
  final _stateSubject = BehaviorSubject<GameState>.seeded(GameState());
  Stream<GameState> get state => _stateSubject.stream;
  
  Timer? _timer;

  GameViewModel(this._getQuizUseCase, this._audioManager);

  void onAction(GameAction action) {
    switch (action) {
      case LoadQuizzes(difficulty: var d, count: var c):
        _loadQuizzes(d, c);
      case StartReview():
        _startReview();
      case SelectOption(index: var index):
        _selectOption(index);
      case TickTimer():
        _tickTimer();
      case NextQuestion():
        _nextQuestion();
      case ResetGame():
        _resetGame();
    }
  }

  void _loadQuizzes(String difficulty, int count) async {
    _stateSubject.add(_stateSubject.value.copyWith(
      isLoading: true,
      selectedLevel: difficulty,
      selectedCount: count,
      failedQuestions: [], // 게임 시작 시 초기화
    ));
    
    final result = await _getQuizUseCase.execute(difficulty: difficulty, count: count);
    
    switch (result) {
      case Success(data: var data):
        _stateSubject.add(_stateSubject.value.copyWith(
          isLoading: false,
          questions: data,
          currentQuestionIndex: 0,
          isFinished: false,
          score: 0,
        ));
        _audioManager.playBgm();
        _startTimer();
      case Failure(error: var error):
        _stateSubject.add(_stateSubject.value.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ));
    }
  }

  void _startReview() {
    final currentState = _stateSubject.value;
    if (currentState.failedQuestions.isEmpty) return;

    _stateSubject.add(currentState.copyWith(
      questions: currentState.failedQuestions,
      currentQuestionIndex: 0,
      isFinished: false,
      score: 0,
      failedQuestions: [], // 복습 시작 시 현재 틀린 목록은 비움 (새로 틀리는 걸 담기 위해)
    ));
    _audioManager.playBgm();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _stateSubject.add(_stateSubject.value.copyWith(remainingSeconds: 20));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      onAction(TickTimer());
    });
  }

  void _tickTimer() {
    final currentRemaining = _stateSubject.value.remainingSeconds;
    if (currentRemaining <= 5 && currentRemaining > 0) {
      _audioManager.playTimerTick();
    }

    if (currentRemaining <= 0) {
      _timer?.cancel();
      _selectOption(-1); // 시간 초과 시 오답 처리
    } else {
      _stateSubject.add(_stateSubject.value.copyWith(
        remainingSeconds: currentRemaining - 1,
      ));
    }
  }

  void _selectOption(int index) {
    _timer?.cancel();
    final currentState = _stateSubject.value;
    final currentQuestion = currentState.currentQuestion;
    
    if (currentQuestion == null) return;
    
    final isCorrect = index == currentQuestion.answerIndex;
    final newScore = isCorrect ? currentState.score + 1 : currentState.score; // 문항당 1점으로 변경
    
    List<QuizQuestion> newFailed = List.from(currentState.failedQuestions);
    if (!isCorrect) {
      newFailed.add(currentQuestion);
      _audioManager.playFailure();
    } else {
      _audioManager.playSuccess();
    }

    _stateSubject.add(currentState.copyWith(
      score: newScore,
      lastAnswerCorrect: () => isCorrect,
      selectedOptionIndex: () => index,
      failedQuestions: newFailed,
    ));
  }

  void _nextQuestion() {
    final currentState = _stateSubject.value;
    final nextIndex = currentState.currentQuestionIndex + 1;
    
    if (nextIndex >= currentState.questions.length) {
      _audioManager.stopBgm();
      _stateSubject.add(currentState.copyWith(
        isFinished: true,
        lastAnswerCorrect: () => null,
        selectedOptionIndex: () => null,
      ));
    } else {
      _stateSubject.add(currentState.copyWith(
        currentQuestionIndex: nextIndex,
        lastAnswerCorrect: () => null,
        selectedOptionIndex: () => null,
      ));
      _startTimer();
    }
  }

  void _resetGame() {
    final currentState = _stateSubject.value;
    _loadQuizzes(currentState.selectedLevel, currentState.selectedCount);
  }

  void dispose() {
    _timer?.cancel();
    _stateSubject.close();
  }
}
