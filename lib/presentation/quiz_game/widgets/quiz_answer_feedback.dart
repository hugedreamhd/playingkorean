import 'package:flutter/material.dart';
import 'package:playingkorean/core/presentation/app_theme.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';

/// 정답/오답 확인 후 하단에 표시되는 피드백 패널
class QuizAnswerFeedback extends StatelessWidget {
  final GameState state;
  final QuizQuestion question;
  final VoidCallback onNext;

  const QuizAnswerFeedback({
    super.key,
    required this.state,
    required this.question,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
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
                onPressed: onNext,
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
          _buildMeaningCard(isCorrect),
        ],
      ),
    );
  }

  Widget _buildMeaningCard(bool isCorrect) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.pointGreen.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCorrect
              ? AppTheme.pointGreen.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.lightbulb : Icons.info_outline,
                size: 18,
                color: isCorrect ? AppTheme.pointGreen : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct Meaning' : "Let's check the meanings",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? AppTheme.pointGreen : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(question.options.length, (i) {
            final isThisAnswer = i == question.answerIndex;
            final isUserSelected = i == state.selectedOptionIndex;
            final romaji =
                question.romaji.length > i ? question.romaji[i] : '';
            final englishMeaning = (question.englishMeanings.length > i)
                ? question.englishMeanings[i]
                : '';
            final displayMeaning = englishMeaning.isNotEmpty
                ? englishMeaning
                : 'No English meaning.';
            final isHighlighted = isThisAnswer || isUserSelected;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? (isThisAnswer
                          ? AppTheme.pointGreen.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isThisAnswer
                        ? Icons.check_circle
                        : (isUserSelected
                              ? Icons.cancel
                              : Icons.circle_outlined),
                    size: 16,
                    color: isThisAnswer
                        ? AppTheme.pointGreen
                        : (isUserSelected ? Colors.red : Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: question.options[i],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (romaji.isNotEmpty)
                            TextSpan(
                              text: ' ($romaji)',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          TextSpan(
                            text: ' : $displayMeaning',
                            style: TextStyle(
                              color: isThisAnswer
                                  ? AppTheme.pointGreen
                                  : Colors.black54,
                              fontWeight: isThisAnswer
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
