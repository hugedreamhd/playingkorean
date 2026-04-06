import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playingkorean/core/di/di_setup.dart';
import 'package:playingkorean/core/presentation/app_theme.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';
import 'package:playingkorean/presentation/quiz_game/game_view_model.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/presentation/quiz_game/widgets/kahoot_choice_button.dart';

class QuizScreen extends StatefulWidget {
  final String level;
  final int count;

  const QuizScreen({super.key, required this.level, required this.count});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final GameViewModel _viewModel = getIt<GameViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.onAction(
      LoadQuizzes(difficulty: widget.level, count: widget.count),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameState>(
      stream: _viewModel.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? GameState();

        if (state.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    '동음이의어 문제를 찾는 중...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '처음 실행 시 잠시 시간이 걸릴 수 있습니다.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '데이터 로딩 실패\n(Data Loading Failed)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pointGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('홈으로 돌아가기 (Back to Home)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state.isFinished) {
          return _buildResult(context, state);
        }

        final question = state.currentQuestion;

        // questions 자체가 비어있는 경우 (로딩은 완료됐지만 동음이의어가 없음)
        if (state.questions.isEmpty && !state.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, color: Colors.white70, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      '이 레벨에 동음이의어 문제가\n없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pointGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('홈으로 돌아가기'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (question == null) return const SizedBox.shrink();


        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: AppTheme.text),
              onPressed: () => context.go('/'),
            ),
            title: Text(
              'Level ${widget.level} - ${state.currentQuestionIndex + 1}/${state.questions.length}',
              style: TextStyle(color: AppTheme.text, fontSize: 16),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    'Score: ${state.score}',
                    style: TextStyle(
                      color: AppTheme.pointGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value:
                    (state.currentQuestionIndex + 1) / state.questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.pointGreen),
              ),
              const SizedBox(height: 16),
              // 질문 카드
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 영어 문장 (문맥 힌트)
                            Text(
                              question.exampleSentences[question.answerIndex],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.text.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 한국어 문장 (빈칸 포함)
                            Text(
                              _formatContextText(question.contextText),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 타이머
                            _buildTimer(state),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 보기 버튼 (개수에 따라 레이아웃 가변)
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildOptions(context, state, question),
                ),
              ),
              // 하단 액션 (정답 확인 후)
              if (state.lastAnswerCorrect != null)
                _buildPostAnswerActions(context, state, question),
            ],
          ),
        );
      },
    );
  }

  /// 보기 버튼 렌더링 - 2개/3개: 세로, 4개+: 2x2 그리드
  /// - Column 안에 Expanded 사용 금지 (Exception 원인)
  /// - 보기에는 영문뜻(englishMeanings)만 표시
  Widget _buildOptions(BuildContext context, GameState state, QuizQuestion question) {
    final optionCount = question.options.length;

    // 안전한 값 추출 헬퍼
    String safeRomaji(int i) =>
        question.romaji.length > i ? question.romaji[i] : '';
    String? safeEnglish(int i) {
      // 영문뜻이 있으면 우선 표시, 없으면 한국어 설명으로 폴백
      if (question.englishMeanings.length > i) {
        final em = question.englishMeanings[i];
        if (em.isNotEmpty) return em;
      }
      if (question.explanations.length > i) {
        final exp = question.explanations[i];
        if (exp.isNotEmpty) return exp;
      }
      return null;
    }

    Widget buildButton(int index) {
      final isCorrect = state.lastAnswerCorrect;
      final isSelected = state.selectedOptionIndex == index;
      final isAnswer = index == question.answerIndex;
      return KahootChoiceButton(
        text: question.options[index],
        romaji: safeRomaji(index),
        english: safeEnglish(index),
        type: ChoiceType.values[index % 4],
        onTap: () => _viewModel.onAction(SelectOption(index)),
        isCorrect: isCorrect,
        isSelected: isSelected,
        isAnswer: isAnswer,
      );
    }

    if (optionCount <= 3) {
      // 2개 또는 3개: 균일 높이 세로 배치
      return Column(
        children: List.generate(optionCount, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: i < optionCount - 1 ? 10 : 0),
              child: SizedBox(
                width: double.infinity,
                child: buildButton(i),
              ),
            ),
          );
        }),
      );
    } else {
      // 4개+: 2x2 그리드
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemCount: optionCount,
        itemBuilder: (context, i) => buildButton(i),
      );
    }
  }

  /// {(      )로} 또는 (      ) 형태의 빈칸을 (    ) 형태로 정규화
  String _formatContextText(String text) {
    // { ( ) } 패턴을 찾아서 ( ) 형태로 변환
    // 예: {(      )을} → (    )을 / {(      )로} → (    )로
    return text.replaceAllMapped(
      RegExp(r'\{\s*\(\s*\)\s*([가-힣]*)\}'),
      (match) => '(    )${match.group(1) ?? ''}',
    ).replaceAllMapped(
      // 남은 { ( ) } 패턴 처리 (조사 없는 경우)
      RegExp(r'\{[\s]*\([\s]*\)[\s]*\}'),
      (match) => '(    )',
    ).replaceAllMapped(
      // plain (      ) 형태 처리 (공백 4개 이상)
      RegExp(r'\(\s{4,}\)([가-힣]*)'),
      (match) => '(    )${match.group(1) ?? ''}',
    );
  }


  Widget _buildTimer(GameState state) {
    final isCritical = state.remainingSeconds <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isCritical ? Colors.red : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${state.remainingSeconds}s',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCritical ? Colors.red : AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAnswerActions(
    BuildContext context,
    GameState state,
    QuizQuestion question,
  ) {
    final isCorrect = state.lastAnswerCorrect ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppTheme.pointGreen : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct! (정답입니다)' : 'Wrong... (틀렸습니다)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppTheme.pointGreen : Colors.red,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _viewModel.onAction(NextQuestion()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pointGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next (다음)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 상세 설명 - 틀렸을 때 모든 동음이의어 의미 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? '✓ 정답 설명' : '✗ 오답 - 단어의 뜻을 확인하세요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                // 모든 보기의 의미 나열
                ...List.generate(question.options.length, (i) {
                  final isThisAnswer = i == question.answerIndex;
                  final isUserSelected = i == state.selectedOptionIndex;
                  final romaji = question.romaji.length > i ? question.romaji[i] : '';
                  final englishMeaning = question.englishMeanings.length > i
                      ? question.englishMeanings[i]
                      : '';
                  final explanation = question.explanations.length > i
                      ? question.explanations[i]
                      : '';
                  // 표시할 뜻: 영문뜻 우선, 없으면 한국어 설명
                  final meaningText = englishMeaning.isNotEmpty ? englishMeaning : explanation;
                  
                  Color iconColor;
                  IconData iconData;
                  if (isThisAnswer) {
                    iconData = Icons.check_circle;
                    iconColor = Colors.green.shade600;
                  } else if (isUserSelected && !isCorrect) {
                    iconData = Icons.cancel;
                    iconColor = Colors.red.shade400;
                  } else {
                    iconData = Icons.circle_outlined;
                    iconColor = Colors.grey.shade400;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(iconData, size: 16, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: question.options[i],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isThisAnswer
                                            ? Colors.green.shade700
                                            : (isUserSelected && !isCorrect
                                                ? Colors.red.shade600
                                                : Colors.black87),
                                      ),
                                    ),
                                    if (romaji.isNotEmpty)
                                      TextSpan(
                                        text: '  $romaji',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (meaningText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    meaningText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isThisAnswer
                                          ? Colors.green.shade800
                                          : Colors.black54,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, GameState state) {
    final isPerfect = state.score == state.questions.length;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPerfect ? Icons.emoji_events : Icons.stars,
                size: 100,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              const Text(
                'Game Finished!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                '결과 (Result)',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.text.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 48),
              _buildResultStat(
                'Correct Answers (정답)',
                '${state.score} / ${state.questions.length}',
              ),
              const SizedBox(height: 16),
              _buildResultStat(
                'Accuracy (정확도)',
                '${((state.score / state.questions.length) * 100).toInt()}%',
              ),
              const SizedBox(height: 48),
              if (state.failedQuestions.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _viewModel.onAction(StartReview()),
                    icon: const Icon(Icons.replay),
                    label: Text(
                      'Review Missed Qs (${state.failedQuestions.length})',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pointGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Home (처음으로)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.pointGreen,
            ),
          ),
        ],
      ),
    );
  }
}
