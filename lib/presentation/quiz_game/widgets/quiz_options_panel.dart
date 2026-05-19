import 'package:flutter/material.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';
import 'package:playingkorean/presentation/quiz_game/widgets/quiz_option_button.dart';

/// 보기 버튼 패널: 2~3개 세로, 4개 이상 2열 그리드
class QuizOptionsPanel extends StatelessWidget {
  final QuizQuestion question;
  final GameState state;
  final void Function(int index) onSelect;

  const QuizOptionsPanel({
    super.key,
    required this.question,
    required this.state,
    required this.onSelect,
  });

  String _safeRomaji(int i) =>
      question.romaji.length > i ? question.romaji[i] : '';

  String? _safeMeaning(int i) {
    if (question.englishMeanings.length > i) {
      final text = _cleanMeaning(question.englishMeanings[i]);
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  String _cleanMeaning(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';
    text = text.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim();
    text = text.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    if (text.isEmpty) return '';
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.length > 120 ? '${text.substring(0, 120).trim()}...' : text;
  }

  Widget _buildButton(int index) {
    return QuizOptionButton(
      text: question.options[index],
      romaji: _safeRomaji(index),
      english: _safeMeaning(index),
      type: ChoiceType.values[index % 4],
      onTap: () => onSelect(index),
      isCorrect: state.lastAnswerCorrect,
      isSelected: state.selectedOptionIndex == index,
      isAnswer: index == question.answerIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final optionCount = question.options.length;

    if (optionCount <= 3) {
      return Column(
        children: List.generate(optionCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < optionCount - 1 ? 12 : 0),
            child: SizedBox(width: double.infinity, child: _buildButton(i)),
          );
        }),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: optionCount,
      itemBuilder: (context, i) => _buildButton(i),
    );
  }
}
