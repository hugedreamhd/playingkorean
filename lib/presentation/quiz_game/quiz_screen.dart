import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playingkorean/core/di/di_setup.dart';
import 'package:playingkorean/core/presentation/app_theme.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';
import 'package:playingkorean/presentation/quiz_game/game_view_model.dart';
import 'package:playingkorean/presentation/quiz_game/widgets/kahoot_choice_button.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final GameViewModel _viewModel = getIt<GameViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.onAction(LoadQuizzes());
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

        if (state.isFinished) {
          return _buildResult(context, state);
        }

        final question = state.currentQuestion;
        if (question == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: AppTheme.pointBlue,
          body: Column(
            children: [
              const SizedBox(height: 16),
              // 점수 표시
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: ${state.score}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    Text(
                      '${state.currentQuestionIndex + 1} / ${state.questions.length}',
                      style: TextStyle(fontSize: 18, color: AppTheme.text),
                    ),
                  ],
                ),
              ),
              // 질문 및 이미지
              Expanded(
                flex: 2,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 4,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              question.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(Icons.image, size: 100),
                                  ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              question.contextText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 숫자 카운트다운 오버레이
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: state.remainingSeconds <= 5
                                  ? Colors.red
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '${state.remainingSeconds}',
                            style: TextStyle(
                              color: state.remainingSeconds <= 5
                                  ? Colors.red
                                  : Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 4개의 보기
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      return KahootChoiceButton(
                        text: question.options[index],
                        romaji: question.romaji[index],
                        english: question.englishMeanings[index],
                        type: ChoiceType.values[index % 4],
                        onTap: () => _viewModel.onAction(SelectOption(index)),
                        isCorrect: state.lastAnswerCorrect,
                        isSelected: state.selectedOptionIndex == index,
                        isAnswer: index == question.answerIndex,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResult(BuildContext context, GameState state) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 100),
            Text(
              'Game Finished!',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Score: ${state.score}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 24),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => _viewModel.onAction(ResetGame()),
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(
                'Back to Home',
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
