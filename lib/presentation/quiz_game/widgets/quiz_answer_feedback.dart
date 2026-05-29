import 'package:flutter/material.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';

/// 정답/오답 확인 후 하단에 표시되는 프리미엄 K-네온 오방색 피드백 패널
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36), // 하단 여백 추가
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // 딥 옵시디언 블랙 (흑)
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08), // 상단 경계선 유리 질감
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? const Color(0xFF58D68D) : const Color(0xFFFF3B30))
                .withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 상태 타이틀 및 다음 버튼 라인
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? const Color(0xFF58D68D) : const Color(0xFFFF3B30),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? '정답입니다! (Correct)' : '아쉬워요... (Wrong)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isCorrect ? const Color(0xFF58D68D) : const Color(0xFFFF3B30),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              // 네온 다음 단계 버튼
              ElevatedButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Next',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? const Color(0xFF58D68D) : const Color(0xFFFF3B30),
                  foregroundColor: const Color(0xFF0F172A), // 텍스트는 가독성을 위해 어두운 흑색
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: (isCorrect ? const Color(0xFF58D68D) : const Color(0xFFFF3B30))
                      .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 상세 설명 카드 영역
          _buildMeaningCard(isCorrect),
        ],
      ),
    );
  }

  /// 단어 상세 해설 글래스모피즘 카드
  Widget _buildMeaningCard(bool isCorrect) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02), // 몽환적인 얇은 유광 코팅
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.lightbulb_rounded : Icons.info_outline_rounded,
                size: 18,
                color: isCorrect ? const Color(0xFFFFCC00) : const Color(0xFF81ECE1), // 황색 혹은 청백색
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? '정확한 뜻풀이' : "단어들의 뜻을 다시 확인해 볼까요?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? const Color(0xFFFFCC00) : const Color(0xFF81ECE1),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 각각의 보기 의미 노출
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
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? (isThisAnswer
                        ? const Color(0xFF58D68D).withValues(alpha: 0.08)
                        : const Color(0xFFFF3B30).withValues(alpha: 0.08))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isHighlighted
                    ? Border.all(
                        color: (isThisAnswer ? const Color(0xFF58D68D) : const Color(0xFFFF3B30))
                            .withValues(alpha: 0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(
                      isThisAnswer
                          ? Icons.check_circle_rounded
                          : (isUserSelected
                              ? Icons.cancel_rounded
                              : Icons.circle_outlined),
                      size: 16,
                      color: isThisAnswer
                          ? const Color(0xFF58D68D)
                          : (isUserSelected ? const Color(0xFFFF3B30) : Colors.white30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white, // 전체 화이트화
                        ),
                        children: [
                          // 한국어 단어 강조
                          TextSpan(
                            text: question.options[i],
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          if (romaji.isNotEmpty)
                            TextSpan(
                              text: ' [ $romaji ]',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          // 뜻풀이
                          TextSpan(
                            text: ' : $displayMeaning',
                            style: TextStyle(
                              color: isThisAnswer
                                  ? const Color(0xFF81ECE1) // 정답 뜻풀이는 청백색 강조
                                  : Colors.white54,
                              fontWeight: isThisAnswer
                                  ? FontWeight.w700
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
