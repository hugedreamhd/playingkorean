import 'dart:async';
import 'dart:math';
import 'package:playingkorean/core/audio/audio_manager.dart';
import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/get_quiz_use_case.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/user/user_wallet_repository.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';
import 'package:rxdart/rxdart.dart';

class GameViewModel {
  final GetQuizUseCase _getQuizUseCase;
  final AudioManager _audioManager;
  final UserWalletRepository _userWalletRepository;
  
  final _stateSubject = BehaviorSubject<GameState>.seeded(GameState());
  Stream<GameState> get state => _stateSubject.stream;
  
  Timer? _timer;

  GameViewModel(this._getQuizUseCase, this._audioManager, this._userWalletRepository) {
    _loadInitialWallet();
  }

  void _loadInitialWallet() async {
    final currentCoins = await _userWalletRepository.getCoins();
    _stateSubject.add(_stateSubject.value.copyWith(coins: currentCoins));
  }

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
      case UseMapaeChance():
        _useMapaeChance();
      case AdWatchedForMapae():
        _adWatchedForMapae();
      case ClaimDoubleReward():
        _claimDoubleReward();
      case UpdateWalletCoins(coins: var coins):
        _stateSubject.add(_stateSubject.value.copyWith(coins: coins));
      case PauseTimer():
        _timer?.cancel();
      case ResumeTimer():
        _startTimer(resume: true);
    }
  }

  void _loadQuizzes(String difficulty, int count) async {
    final walletCoins = await _userWalletRepository.getCoins();
    _stateSubject.add(_stateSubject.value.copyWith(
      isLoading: true,
      selectedLevel: difficulty,
      selectedCount: count,
      failedQuestions: [], // 게임 시작 시 초기화
      coins: walletCoins,
      earnedCoins: 0,
      isDoubleRewardClaimed: false,
      disabledOptionIndices: [],
      mapaeUsedCount: 0,
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
      failedQuestions: [], // 복습 시작 시 현재 틀린 목록은 비움
      earnedCoins: 0,
      isDoubleRewardClaimed: false,
      disabledOptionIndices: [],
    ));
    _audioManager.playBgm();
    _startTimer();
  }

  void _startTimer({bool resume = false}) {
    _timer?.cancel();
    if (!resume) {
      _stateSubject.add(_stateSubject.value.copyWith(
        remainingSeconds: 20,
        disabledOptionIndices: [], // 문제 바뀔 때 마패 비활성화 목록 초기화
      ));
    }
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
    final newScore = isCorrect ? currentState.score + 1 : currentState.score;
    
    // 정답 시 엽전 획득 (+5냥)
    int sessionEarned = currentState.earnedCoins;
    if (isCorrect) {
      sessionEarned += 5;
    }

    List<QuizQuestion> newFailed = List.from(currentState.failedQuestions);
    if (!isCorrect) {
      newFailed.add(currentQuestion);
      _audioManager.playFailure();
    } else {
      _audioManager.playSuccess();
    }

    _stateSubject.add(currentState.copyWith(
      score: newScore,
      earnedCoins: sessionEarned,
      lastAnswerCorrect: () => isCorrect,
      selectedOptionIndex: () => index,
      failedQuestions: newFailed,
    ));
  }

  void _nextQuestion() async {
    final currentState = _stateSubject.value;
    final nextIndex = currentState.currentQuestionIndex + 1;
    
    if (nextIndex >= currentState.questions.length) {
      _audioManager.stopBgm();
      _audioManager.playResult(currentState.score);

      // 만점 보너스 검사 (+20냥)
      int finalEarnedCoins = currentState.earnedCoins;
      final isPerfect = currentState.score == currentState.questions.length && currentState.questions.isNotEmpty;
      if (isPerfect) {
        finalEarnedCoins += 20;
      }

      // 최종 획득한 엽전을 리포지토리에 추가 저장
      await _userWalletRepository.addCoins(finalEarnedCoins);
      final newTotalCoins = await _userWalletRepository.getCoins();

      _stateSubject.add(currentState.copyWith(
        isFinished: true,
        earnedCoins: finalEarnedCoins,
        coins: newTotalCoins,
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

  void _useMapaeChance() async {
    final currentState = _stateSubject.value;
    final currentQuestion = currentState.currentQuestion;
    if (currentQuestion == null || currentState.lastAnswerCorrect != null) return;

    // 판당 최대 2회 제한 검사
    if (currentState.mapaeUsedCount >= 2) return;

    // 이미 보기를 다 지운 경우 리턴
    if (currentState.disabledOptionIndices.length >= currentQuestion.options.length - 1) return;

    // 엽전 차감 시도 (30냥)
    final success = await _userWalletRepository.deductCoins(30);
    if (success) {
      final updatedCoins = await _userWalletRepository.getCoins();
      _disableRandomIncorrectOption(updatedCoins);
    }
  }

  void _adWatchedForMapae() async {
    final currentState = _stateSubject.value;
    final currentQuestion = currentState.currentQuestion;
    if (currentQuestion == null || currentState.lastAnswerCorrect != null) return;
    
    // 판당 최대 2회 제한 검사
    if (currentState.mapaeUsedCount >= 2) return;

    if (currentState.disabledOptionIndices.length >= currentQuestion.options.length - 1) return;

    // 광고를 시청했으므로 코인 차감 없이 오답 제거를 적용
    _disableRandomIncorrectOption(currentState.coins);
  }

  void _disableRandomIncorrectOption(int newCoins) {
    final currentState = _stateSubject.value;
    final currentQuestion = currentState.currentQuestion;
    if (currentQuestion == null) return;

    final correctAnswerIndex = currentQuestion.answerIndex;
    final totalOptions = currentQuestion.options.length;

    // 제거 가능한 오답 인덱스 필터링
    final possibleIndices = <int>[];
    for (int i = 0; i < totalOptions; i++) {
      if (i != correctAnswerIndex && !currentState.disabledOptionIndices.contains(i)) {
        possibleIndices.add(i);
      }
    }

    if (possibleIndices.isNotEmpty) {
      final random = Random();
      final selectToRemove = possibleIndices[random.nextInt(possibleIndices.length)];
      
      final updatedDisabled = List<int>.from(currentState.disabledOptionIndices)..add(selectToRemove);
      _stateSubject.add(currentState.copyWith(
        coins: newCoins,
        disabledOptionIndices: updatedDisabled,
        mapaeUsedCount: currentState.mapaeUsedCount + 1,
      ));
    }
  }

  void _claimDoubleReward() async {
    final currentState = _stateSubject.value;
    if (currentState.isDoubleRewardClaimed) return;

    // 이미 적립된 기본 엽전(earnedCoins)만큼 지갑에 추가 적립
    await _userWalletRepository.addCoins(currentState.earnedCoins);
    final updatedCoins = await _userWalletRepository.getCoins();

    _stateSubject.add(currentState.copyWith(
      coins: updatedCoins,
      isDoubleRewardClaimed: true,
    ));
  }

  void _resetGame() {
    final currentState = _stateSubject.value;
    _loadQuizzes(currentState.selectedLevel, currentState.selectedCount);
  }

  void dispose() {
    _timer?.cancel();
    _audioManager.stopBgm();
    _stateSubject.close();
  }
}
