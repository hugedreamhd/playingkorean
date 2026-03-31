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
            body: const Center(child: CircularProgressIndicator()),
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
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      '데이터 로딩 실패\n(Data Loading Failed)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14),
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
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 영어 문장 (문맥 힌트)
                          Text(
                            question.englishSentence,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.text.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 한국어 문장 (빈칸 포함)
                          Text(
                            question.contextText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // 타이머
                          _buildTimer(state),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 4개의 보기
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      final isCorrect = state.lastAnswerCorrect;
                      final isSelected = state.selectedOptionIndex == index;
                      final isAnswer = index == question.answerIndex;

                      return KahootChoiceButton(
                        text: question.options[index],
                        romaji: question.romaji[index],
                        english: isAnswer
                            ? question.englishDefinition
                            : null, // 정답에만 영문 정의 표시
                        type: ChoiceType.values[index % 4],
                        onTap: () => _viewModel.onAction(SelectOption(index)),
                        isCorrect: isCorrect,
                        isSelected: isSelected,
                        isAnswer: isAnswer,
                      );
                    },
                  ),
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
          // 상세 설명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation (상세 설명):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.englishDefinition,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
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
