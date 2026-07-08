import 'package:flutter/material.dart';

enum ChoiceType { triangle, diamond, circle, square }

class QuizOptionButton extends StatefulWidget {
  final String text;
  final String romaji;
  final String? english;
  final ChoiceType type;
  final VoidCallback onTap;
  final bool? isCorrect; // null: 선택 전, true: 정답, false: 오답
  final bool isSelected;
  final bool isAnswer;
  final bool isDisabled;

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
    this.isDisabled = false,
  });

  @override
  State<QuizOptionButton> createState() => _QuizOptionButtonState();
}

class _QuizOptionButtonState extends State<QuizOptionButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _stampController;
  late Animation<double> _stampScaleAnimation;
  late Animation<double> _stampOpacityAnimation;
  bool _hasTriggeredStamp = false;

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 하늘에서 쾅 찍히는 듯한 스케일 모션 (스케일 3.0 -> 1.0)
    _stampScaleAnimation = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.bounceOut),
    );

    _stampOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.easeIn),
    );

    if (widget.isDisabled) {
      _stampController.value = 1.0; // 이미 비활성화되어 있는 보기는 바로 도장 고정 표시
      _hasTriggeredStamp = true;
    }
  }

  @override
  void didUpdateWidget(covariant QuizOptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDisabled && !oldWidget.isDisabled && !_hasTriggeredStamp) {
      _hasTriggeredStamp = true;
      _stampController.forward();
    } else if (!widget.isDisabled && oldWidget.isDisabled) {
      _hasTriggeredStamp = false;
      _stampController.reset();
    }
  }

  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }

  String? _buildMeaning() =>
      (widget.english != null && widget.english!.isNotEmpty)
          ? widget.english
          : null;

  /// K-네온 오방색(Taegeuk & Obangsek) 기반 고유 색상 추출
  Color _getKNeonColor() {
    switch (widget.type) {
      case ChoiceType.triangle:
        return const Color(0xFFFF3B30); // 태극 홍 (Vivid Taegeuk Red)
      case ChoiceType.diamond:
        return const Color(0xFF007AFF); // 태극 청 (Vivid Taegeuk Blue)
      case ChoiceType.circle:
        return const Color(0xFFFFCC00); // 오방 황 (Obangsek Gold/Yellow)
      case ChoiceType.square:
        return const Color(0xFF81ECE1); // 음양 조화의 청백색 (Neon White-Mint)
    }
  }

  /// K-전통 문양의 기하학적 형태를 재해석한 아이콘 빌드
  Widget _getIcon(Color color) {
    switch (widget.type) {
      case ChoiceType.triangle:
        // 하늘로 솟아오르는 불꽃(태극의 양기)을 닮은 세모
        return Icon(Icons.change_history_rounded, color: color, size: 28);
      case ChoiceType.diamond:
        // 사방으로 뻗는 동양의 기백을 표현한 다이아몬드
        return Transform.rotate(
          angle: 0.785,
          child: Icon(Icons.crop_square_rounded, color: color, size: 28),
        );
      case ChoiceType.circle:
        // 우주의 무한한 조화를 의미하는 태극 원
        return Icon(Icons.circle_outlined, color: color, size: 26);
      case ChoiceType.square:
        // 땅의 기초와 안정감을 나타내는 정방형 네모
        return Icon(Icons.crop_square_rounded, color: color, size: 28);
    }
  }

  @override
  Widget build(BuildContext context) {
    final neonColor = _getKNeonColor();
    final isRevealed = widget.isCorrect != null;

    // 1) 정오답 및 대기 상태별 렌더링 데코레이션 정의
    BoxDecoration decoration;
    double opacity = 1.0;

    if (isRevealed) {
      if (widget.isAnswer) {
        // 정답 공개: 오방색 황(Yellow/Gold) 또는 숲의 성장 청록색으로 발광
        decoration = BoxDecoration(
          color: const Color(0xFF58D68D).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF58D68D), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF58D68D).withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        );
      } else if (widget.isSelected) {
        // 내가 고른 오답: 태극의 홍(Red)색으로 경고 발광
        decoration = BoxDecoration(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFF3B30), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        );
      } else {
        // 선택되지 않은 들러리 보기들: 백의민족의 은은한 여백의 미(투명도 처리)
        opacity = 0.22;
        decoration = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
        );
      }
    } else {
      // 대기 모드: 은은한 깊이를 보여주는 딥 블랙 슬레이트 글래스모피즘
      decoration = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isPressed ? neonColor : neonColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: neonColor.withValues(alpha: _isPressed ? 0.20 : 0.04),
            blurRadius: _isPressed ? 14 : 5,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    // 2) 우측 상태 표시 아이콘
    Widget? stateIcon;
    if (isRevealed) {
      if (widget.isAnswer) {
        stateIcon = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF58D68D),
          size: 24,
        );
      } else if (widget.isSelected) {
        stateIcon = const Icon(
          Icons.cancel_rounded,
          color: Color(0xFFFF3B30),
          size: 24,
        );
      }
    }

    // 비활성화되었을 때 투명도 조절 (도장이 선명하게 강조될 수 있도록 투명도를 0.25 정도로 유지)
    final finalOpacity = widget.isDisabled ? 0.25 : opacity;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      opacity: finalOpacity,
      child: Transform.scale(
        scale: _isPressed ? 0.96 : 1.0,
        child: Container(
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: isRevealed || widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
              onTapUp: isRevealed || widget.isDisabled ? null : (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
              onTapCancel: isRevealed || widget.isDisabled ? null : () => setState(() => _isPressed = false),
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // 좌측 고유 K-네온 아이콘 영역
                        _getIcon(
                          isRevealed
                              ? (widget.isAnswer
                                  ? const Color(0xFF58D68D)
                                  : (widget.isSelected ? const Color(0xFFFF3B30) : neonColor.withValues(alpha: 0.35)))
                              : neonColor,
                        ),
                        const SizedBox(width: 14),

                        // 중앙 텍스트 영역 (단어 + 발음 + 뜻)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  if (widget.romaji.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.romaji,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (_buildMeaning() != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _buildMeaning()!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.40),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // 우측 정답/오답 확인 상태 아이콘
                        if (stateIcon != null) ...[
                          const SizedBox(width: 8),
                          stateIcon,
                        ]
                      ],
                    ),
                  ),
                  
                  // 붉은색 암행어사 마패 낙인 도장 애니메이션 오버레이
                  if (widget.isDisabled)
                    Positioned.fill(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _stampController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: -0.15, // 약간 비스듬히 찍히는 전통 전각 낙인 표현
                              child: Transform.scale(
                                scale: _stampScaleAnimation.value,
                                child: Opacity(
                                  opacity: _stampOpacityAnimation.value,
                                  child: CustomPaint(
                                    size: const Size(60, 60),
                                    painter: MapaeStampPainter(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 붉은색 전통 마패 도장 페인터
class MapaeStampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = w * 0.45;

    // 빈티지한 전각 인장의 붉은 낙인 색상
    final paint = Paint()
      ..color = const Color(0xFFC0392B).withValues(alpha: 0.85) // 전각 붉은색
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 도장 외곽 이중 동심원 테두리
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius - 3, paint);

    final fillPaint = Paint()
      ..color = const Color(0xFFC0392B).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // 중앙의 말(馬) 실루엣 드로잉
    final Path p = Path();
    final double scaleSize = radius * 0.95;
    
    final double sx = center.dx - scaleSize * 0.48;
    final double sy = center.dy - scaleSize * 0.36;

    p.moveTo(sx + scaleSize * 0.22, sy + scaleSize * 0.48);
    p.quadraticBezierTo(sx + scaleSize * 0.28, sy + scaleSize * 0.28, sx + scaleSize * 0.38, sy + scaleSize * 0.28);
    p.lineTo(sx + scaleSize * 0.41, sy + scaleSize * 0.20);
    p.lineTo(sx + scaleSize * 0.44, sy + scaleSize * 0.28);
    p.quadraticBezierTo(sx + scaleSize * 0.54, sy + scaleSize * 0.31, sx + scaleSize * 0.52, sy + scaleSize * 0.39);
    p.quadraticBezierTo(sx + scaleSize * 0.46, sy + scaleSize * 0.43, sx + scaleSize * 0.40, sy + scaleSize * 0.45);
    p.quadraticBezierTo(sx + scaleSize * 0.48, sy + scaleSize * 0.55, sx + scaleSize * 0.58, sy + scaleSize * 0.55);
    p.quadraticBezierTo(sx + scaleSize * 0.73, sy + scaleSize * 0.48, sx + scaleSize * 0.83, sy + scaleSize * 0.45);
    p.quadraticBezierTo(sx + scaleSize * 0.94, sy + scaleSize * 0.48, sx + scaleSize * 0.97, sy + scaleSize * 0.60);
    p.quadraticBezierTo(sx + scaleSize * 0.85, sy + scaleSize * 0.62, sx + scaleSize * 0.81, sy + scaleSize * 0.56);
    p.lineTo(sx + scaleSize * 0.79, sy + scaleSize * 0.75);
    p.lineTo(sx + scaleSize * 0.73, sy + scaleSize * 0.76);
    p.lineTo(sx + scaleSize * 0.75, sy + scaleSize * 0.58);
    p.quadraticBezierTo(sx + scaleSize * 0.58, sy + scaleSize * 0.65, sx + scaleSize * 0.45, sy + scaleSize * 0.60);
    p.lineTo(sx + scaleSize * 0.35, sy + scaleSize * 0.78);
    p.lineTo(sx + scaleSize * 0.29, sy + scaleSize * 0.76);
    p.lineTo(sx + scaleSize * 0.38, sy + scaleSize * 0.52);
    p.close();

    canvas.drawPath(p, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
