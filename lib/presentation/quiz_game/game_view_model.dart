import 'dart:async';
import 'package:playingkorean/core/audio/audio_manager.dart';
import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/get_quiz_use_case.dart';
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
      case LoadQuizzes():
        _loadQuizzes();
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

  void _loadQuizzes() async {
    _stateSubject.add(_stateSubject.value.copyWith(isLoading: true));
    
    final result = await _getQuizUseCase.execute();
    
    switch (result) {
      case Success(data: var data):
        _stateSubject.add(_stateSubject.value.copyWith(
          isLoading: false,
          questions: data,
          currentQuestionIndex: 0,
          isFinished: false,
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
    final newScore = isCorrect ? currentState.score + 10 : currentState.score;
    
    if (isCorrect) {
      _audioManager.playSuccess();
    } else {
      _audioManager.playFailure();
    }

    _stateSubject.add(currentState.copyWith(
      score: newScore,
      lastAnswerCorrect: () => isCorrect,
      selectedOptionIndex: () => index,
    ));
    
    // 2초 후 다음 문제로 자동 전환
    Future.delayed(const Duration(seconds: 2), () {
      onAction(NextQuestion());
    });
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
    _stateSubject.add(GameState());
    onAction(LoadQuizzes());
  }

  void dispose() {
    _timer?.cancel();
    _stateSubject.close();
  }
}
