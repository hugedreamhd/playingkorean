import 'package:flutter/material.dart';

enum ChoiceType { triangle, diamond, circle, square }

class KahootChoiceButton extends StatelessWidget {
  final String text;
  final String romaji;
  final String? english;
  final ChoiceType type;
  final VoidCallback onTap;
  final bool? isCorrect; // null: 선택 전, true: 정답, false: 오답
  final bool isSelected;
  final bool isAnswer;

  const KahootChoiceButton({
    super.key,
    required this.text,
    required this.romaji,
    this.english,
    required this.type,
    required this.onTap,
    this.isCorrect,
    this.isSelected = false,
    this.isAnswer = false,
  });

  Color _getBackground() {
    Color baseColor;
    switch (type) {
      case ChoiceType.triangle:
        baseColor = const Color(0xFFE21B3C);
        break;
      case ChoiceType.diamond:
        baseColor = const Color(0xFF1368CE);
        break;
      case ChoiceType.circle:
        baseColor = const Color(0xFFD89E00);
        break;
      case ChoiceType.square:
        baseColor = const Color(0xFF26890C);
        break;
    }

    if (isCorrect != null) {
      // 선택 기록이 있을 때
      if (isSelected) {
        return baseColor; // 내가 누른 건 원래 색
      } else {
        return baseColor.withOpacity(0.2); // 누르지 않은 건 흐리게
      }
    }

    return baseColor;
  }

  Widget _getIcon() {
    switch (type) {
      case ChoiceType.triangle:
        return const Icon(Icons.change_history, color: Colors.white, size: 32);
      case ChoiceType.diamond:
        return Transform.rotate(
          angle: 0.785,
          child: const Icon(Icons.stop, color: Colors.white, size: 32),
        );
      case ChoiceType.circle:
        return const Icon(Icons.circle, color: Colors.white, size: 32);
      case ChoiceType.square:
        return const Icon(Icons.stop, color: Colors.white, size: 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _getBackground(),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isCorrect != null ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _getIcon(),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$romaji ($english)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCorrect != null)
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    isAnswer ? Icons.check_circle : (isSelected ? Icons.cancel : null),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
