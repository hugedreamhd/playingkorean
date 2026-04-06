import 'package:flutter/material.dart';

enum ChoiceType { triangle, diamond, circle, square }

class QuizOptionButton extends StatelessWidget {
  final String text;
  final String romaji;
  final String? english;
  final ChoiceType type;
  final VoidCallback onTap;
  final bool? isCorrect; // null: 선택 전, true: 정답, false: 오답
  final bool isSelected;
  final bool isAnswer;

  const QuizOptionButton({
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

  String? _buildMeaning() => (english != null && english!.isNotEmpty) ? english : null;

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
      if (isAnswer || isSelected) {
        return baseColor;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 좌측 아이콘 영역
              SizedBox(
                width: 32,
                child: Center(child: _getIcon()),
              ),
              const SizedBox(width: 8),
              // 중앙 텍스트 영역
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (romaji.isNotEmpty || _buildMeaning() != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${romaji.isNotEmpty ? romaji : ''}${_buildMeaning() != null ? ' [${_buildMeaning()}]' : ''}',
                          textAlign: TextAlign.center,
                          maxLines: 2, // 2줄까지 허용
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 우측 정답/오답 표시 영역
              SizedBox(
                width: 32,
                child: isCorrect != null
                    ? Center(
                        child: Icon(
                          isAnswer
                              ? Icons.check_circle
                              : (isSelected ? Icons.cancel : null),
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
