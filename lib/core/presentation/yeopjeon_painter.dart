import 'package:flutter/material.dart';

class YeopjeonWidget extends StatelessWidget {
  final double size;

  const YeopjeonWidget({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const YeopjeonPainter(),
      ),
    );
  }
}

class YeopjeonPainter extends CustomPainter {
  const YeopjeonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // 1) 황동/청동 느낌의 앤티크 그라데이션 브러시 정의
    final Paint coinBodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFD4AF37), // 밝은 황동
          Color(0xFFA57C1B), // 어두운 황동
          Color(0xFFE5C158), // 반사광
          Color(0xFF8E630D), // 그림자 황동
          Color(0xFFD4AF37),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // 동전 테두리 및 그림자용 짙은 브러시
    final Paint darkEdgePaint = Paint()
      ..color = const Color(0xFF5D4007)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;

    // 밝은 하이라이트용 브러시
    final Paint highlightPaint = Paint()
      ..color = const Color(0xFFFFF2AF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.04;

    // 2) 동전 몸체 그리기 (원)
    canvas.drawCircle(center, radius, coinBodyPaint);
    canvas.drawCircle(center, radius, darkEdgePaint);

    // 3) 외곽 안쪽에 미세한 입체감 테두리선 추가
    canvas.drawCircle(center, radius * 0.92, highlightPaint);

    // 4) 가운데 사각형 구멍 그리기
    final double holeHalfSize = radius * 0.25;
    final Rect holeRect = Rect.fromLTRB(
      center.dx - holeHalfSize,
      center.dy - holeHalfSize,
      center.dx + holeHalfSize,
      center.dy + holeHalfSize,
    );

    // 구멍 내부를 잘라내기(뚫기) 위해 클리핑 대신 어두운 색으로 채우고 사각 테두리 그리기
    final Paint holePaint = Paint()
      ..color = const Color(0xFF0D1224) // 배경색과 조화롭게 뚫린 느낌을 주기 위해 깊은 다크 네이비로 채움
      ..style = PaintingStyle.fill;

    canvas.drawRect(holeRect, holePaint);
    canvas.drawRect(holeRect, darkEdgePaint);

    // 5) 엽전 글자 새기기 (常 平 通 寶 - 상평통보)
    // 엽전의 네 방향에 한자 배치
    final double textDistance = radius * 0.58;
    final double fontSize = radius * 0.28;

    _drawCoinText(canvas, center, '常', Offset(0, -textDistance), fontSize);
    _drawCoinText(canvas, center, '平', Offset(0, textDistance), fontSize);
    _drawCoinText(canvas, center, '通', Offset(textDistance, 0), fontSize);
    _drawCoinText(canvas, center, '寶', Offset(-textDistance, 0), fontSize);
  }

  void _drawCoinText(Canvas canvas, Offset center, String text, Offset offset, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF3E2723), // 한문 특유의 먹물/짙은 갈색 각인 느낌
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'serif',
          shadows: [
            Shadow(
              color: const Color(0xFFFFF8E1).withOpacity(0.6),
              offset: const Offset(0.5, 0.5),
              blurRadius: 1,
            )
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final Offset textPos = Offset(
      center.dx + offset.dx - textPainter.width / 2,
      center.dy + offset.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textPos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
