import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class KTraditionalFrame extends StatelessWidget {
  final Widget child;
  final bool showKnot; 
  final bool blurKnot; // 게임 플레이 시 배경 매듭을 아주 흐리게 만들기 위한 옵션

  const KTraditionalFrame({
    super.key,
    required this.child,
    this.showKnot = true,
    this.blurKnot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 36.0),
          child: child,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: KTraditionalPainter(showKnot: showKnot, blurKnot: blurKnot),
            ),
          ),
        ),
      ],
    );
  }
}

class KTraditionalPainter extends CustomPainter {
  final bool showKnot;
  final bool blurKnot;

  KTraditionalPainter({required this.showKnot, this.blurKnot = false});

  @override
  void paint(Canvas canvas, Size size) {
    final double pad = 16.0; // 패딩을 약간 늘려 매듭 공간 확보

    // 1. 자개 그라데이션 (동일하게 유지)
    final Rect fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient holographicGradient = LinearGradient(
      colors: [
        const Color(0xFFE5D5FA).withOpacity(0.95), // 상단 은빛 연보라/라벤더
        const Color(0xFFA6E3E9).withOpacity(0.85), // 상중단 부드러운 옥색
        const Color(0xFF5ED8D4).withOpacity(0.90), // 중단 맑은 비취색
        const Color(0xFF4C6EF5).withOpacity(0.85), // 하단 딥 블루
        const Color(0xFF7B2CBF).withOpacity(0.95), // 극하단 깊은 보라빛
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    final Shader holographicShader = holographicGradient.createShader(fullRect);

    // 2. 선 두께를 첫 번째 사진처럼 대폭 증가
    final Paint outerFramePaint = Paint()
      ..shader = holographicShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 // 2.4에서 4.5로 대폭 증가 (크고 두껍게)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint innerFramePaint = Paint()
      ..shader = holographicShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 // 1.2에서 2.5로 증가
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 3. 배경 국화 매듭 (동일하게 유지)
    if (showKnot) {
      KKnotPainter(isBlurred: blurKnot).paint(canvas, size);
    }

    // 4. 외각 이중 테두리 패스 그리기
    // 매듭의 전체 크기를 첫 번째 사진처럼 크고 두껍게 확대
    final double cornerGap = 64.0; // 32.0에서 64.0으로 대폭 확대

    // [바깥쪽 메인 테두리] 직선 (모서리는 둥글게 그리기 위해 비워둡니다)
    canvas.drawLine(Offset(pad + cornerGap, pad), Offset(size.width - pad - cornerGap, pad), outerFramePaint);
    canvas.drawLine(Offset(pad + cornerGap, size.height - pad), Offset(size.width - pad - cornerGap, size.height - pad), outerFramePaint);
    canvas.drawLine(Offset(pad, pad + cornerGap), Offset(pad, size.height - pad - cornerGap), outerFramePaint);
    canvas.drawLine(Offset(size.width - pad, pad + cornerGap), Offset(size.width - pad, size.height - pad - cornerGap), outerFramePaint);

    // [안쪽 보조 테두리] 직선 (안쪽 테두리 간격 늘림)
    final double innerPad = pad + 16.0; // 6.5에서 16.0으로 늘려 선명하게
    final double innerCornerGap = cornerGap - 16.0; // 매듭 내부 공간 확보

    canvas.drawLine(Offset(innerPad + innerCornerGap, innerPad), Offset(size.width - innerPad - innerCornerGap, innerPad), innerFramePaint);
    canvas.drawLine(Offset(innerPad + innerCornerGap, size.height - innerPad), Offset(size.width - innerPad - innerCornerGap, size.height - innerPad), innerFramePaint);
    canvas.drawLine(Offset(innerPad, innerPad + innerCornerGap), Offset(innerPad, size.height - innerPad - innerCornerGap), innerFramePaint);
    canvas.drawLine(Offset(size.width - innerPad, innerPad + innerCornerGap), Offset(size.width - innerPad, size.height - innerPad - innerCornerGap), innerFramePaint);

    // 5. 귀퉁이의 정밀 복원형 전통 교차 매듭 그리기 (완전히 재작성)
    _drawTraditionalAuspiciousCorners(canvas, outerFramePaint, innerFramePaint, pad, cornerGap, innerPad, innerCornerGap, size);
  }

  // 첫 번째 사진 속 매듭을 '동심결' 모양으로 한 땀 한 땀 다시 그리는 메서드
  void _drawTraditionalAuspiciousCorners(
    Canvas canvas,
    Paint outerPaint,
    Paint innerPaint,
    double pad,
    double gap, // 매듭 전체 크기
    double innerPad, // 안쪽 테두리-매듭 간격
    double innerCornerGap, // 안쪽 매듭 내부 공간
    Size size,
  ) {
    final double w = size.width;
    final double h = size.height;

    // 하나의 매듭 Path를 그리는 함수
    // 각 모서리에 save/translate/scale로 적용합니다.
    void drawAuspiciousKnot(double cx, double cy, double signX, double signY, int trigramType) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(signX, signY);

      // --- [첫 번째 사진 매듭 트레이싱 및 재설계] ---

      // 1. **외부 루프 (Outer Loop, 두꺼운 선)**
      // 테두리의 'ㄱ'자형 모서리에서 시작하여 테두리 *안쪽*으로 둥글게 감싸 안는 더 큰 루프를 그립니다.
      final Path outerKnotPath = Path();
      outerKnotPath.moveTo(gap, 0);
      // 꼭짓점 방향으로 둥글게 모서리를 도는 아크
      outerKnotPath.quadraticBezierTo(0, 0, 0, gap);

      // 첫 번째 사진처럼 둥근 모서리가 테두리 안쪽으로 더 들어가 있으며, 매듭의 일부가 됩니다.
      // 이 루프는 테두리의 끝 단자와 연결되는 것이 아니라, 테두리 *안쪽*에 위치합니다.
      // 따라서 테두리 직선은 직선으로 유지하고, 이 루프는 그 안쪽에서 그립니다.

      // 2. **태극기 건곤감리 괘(Trigram) 디자인**
      void drawTrigram(int type, Offset center, double angleRad) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angleRad); // 모서리 대각선 45도 정렬

        final Paint fillPaint = Paint()
          ..shader = innerPaint.shader
          ..style = PaintingStyle.fill;

        // 하나의 괘(바)를 그리는 로컬 헬퍼
        void drawBar(double y, bool isBroken) {
          if (!isBroken) {
            // solid bar (통선 ☰)
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTRB(-13.0, y - 2.0, 13.0, y + 2.0),
                const Radius.circular(1.0),
              ),
              fillPaint,
            );
          } else {
            // broken bar (반선 ☷)
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTRB(-13.0, y - 2.0, -1.8, y + 2.0),
                const Radius.circular(1.0),
              ),
              fillPaint,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTRB(1.8, y - 2.0, 13.0, y + 2.0),
                const Radius.circular(1.0),
              ),
              fillPaint,
            );
          }
        }

        // 태극기 원형 배치 규격 준수: 바깥쪽(outer) -> 안쪽(inner) 순으로 3개 배치
        // Y축 오프셋: outer (-7.0), middle (0.0), inner (7.0)
        switch (type) {
          case 1: // 건 (☰ - Geon): 3선 모두 연결
            drawBar(-7.0, false);
            drawBar(0.0, false);
            drawBar(7.0, false);
            break;
          case 2: // 감 (☵ - Gam): 가운데만 연결 (상하 split)
            drawBar(-7.0, true);
            drawBar(0.0, false);
            drawBar(7.0, true);
            break;
          case 3: // 리 (☲ - Ri): 가운데만 갈라짐 (상하 solid)
            drawBar(-7.0, false);
            drawBar(0.0, true);
            drawBar(7.0, false);
            break;
          case 4: // 곤 (☷ - Gon): 3선 모두 갈라짐
            drawBar(-7.0, true);
            drawBar(0.0, true);
            drawBar(7.0, true);
            break;
        }

        canvas.restore();
      }

      // 3. **모서리에 해당하는 건곤감리 괘 배치 (모서리 쪽으로 더 밀어 넣어 배치)**
      final double centerCoord = innerPad + innerCornerGap / 2 - 10.0;
      drawTrigram(trigramType, Offset(centerCoord, centerCoord), -math.pi / 4);

      // 최종 드로잉 (외곽 코너 둥근 프레임선은 유지)
      canvas.drawPath(outerKnotPath, outerPaint);

      canvas.restore();
    }

    // 4개 모서리에 각각 태극기 건곤감리 배치하여 그리기
    drawAuspiciousKnot(pad, pad, 1, 1, 1);           // 좌측 상단 (건 - ☰)
    drawAuspiciousKnot(w - pad, pad, -1, 1, 2);       // 우측 상단 (감 - ☵)
    drawAuspiciousKnot(pad, h - pad, 1, -1, 3);       // 좌측 하단 (리 - ☲)
    drawAuspiciousKnot(w - pad, h - pad, -1, -1, 4);   // 우측 하단 (곤 - ☷)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// KKnotPainter는 첫 번째 사진 속 아름다운 전통 한국 단청 문양(연화/국화 단청문)을 정교하게 그리는 페인터입니다.
class KKnotPainter extends CustomPainter {
  final bool isBlurred;
  KKnotPainter({this.isBlurred = false});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double r = size.width * 0.43; // 문양 반지름
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // 블러 필터 적용 (게임 중 배경 묘사용)
    if (isBlurred) {
      canvas.saveLayer(
        null,
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..imageFilter = ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
      );
    }

    // ==========================================
    // [1단계 복원] 가장 바깥쪽 겹잎 (남색/딥 네이비 그라데이션 및 골드 포인트)
    // ==========================================
    final double outerLeafRadius = r * 0.355;
    final double leafDistance = r * 0.67;

    // 조밀하게 나뉜 띠가 선명하게 돋보이도록 하는 어두운 경계선 (홍벽에 맞춘 짙은 적갈색)
    final Paint strokePaint = Paint()
      ..color = const Color(0xFF3E1213) // 아주 짙은 묵회적색
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // 단청 홍벽(진흙 붉은색/테라코타/크림슨) 그라데이션 레이어
    final List<Map<String, dynamic>> layers = [
      {'scale': 1.0, 'color': const Color(0xFF4C1516)},   // 1층
      {'scale': 0.88, 'color': const Color(0xFF7A2022)},  // 2층
      {'scale': 0.77, 'color': const Color(0xFF9E2C2E)},  // 3층
      {'scale': 0.66, 'color': const Color(0xFFCD3C3F)},  // 4층
      {'scale': 0.55, 'color': const Color(0xFF852224)},  // 5층
      {'scale': 0.44, 'color': const Color(0xFF4E1012)},  // 6층
      {'scale': 0.33, 'color': const Color(0xFFE26F72)},  // 7층
      {'scale': 0.18, 'color': const Color(0xFFFFD54F)},  // 8층 (심부)
    ];

    for (var layer in layers) {
      final double scale = layer['scale'] as double;
      final Color color = layer['color'] as Color;
      final Paint fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 8; i++) {
        final double angle = i * math.pi / 4;
        final double lx = math.cos(angle) * leafDistance;
        final double ly = math.sin(angle) * leafDistance;
        canvas.drawCircle(Offset(lx, ly), outerLeafRadius * scale, fillPaint);
        
        if (scale == 1.0 || scale == 0.77 || scale == 0.55 || scale == 0.44) {
          canvas.drawCircle(Offset(lx, ly), outerLeafRadius * scale, strokePaint);
        }
      }
    }

    // ==========================================
    // [2단계] 대각선 45도 방향 청보라색 잎 (4엽 무늬)
    // ==========================================
    final double blueLeafDistance = r * 0.46;
    final double blueLeafRadius = r * 0.26;

    for (int i = 0; i < 4; i++) {
      final double angle = (i * 90 + 45) * math.pi / 180;
      final double bx = math.cos(angle) * blueLeafDistance;
      final double by = math.sin(angle) * blueLeafDistance;

      final Rect leafRect = Rect.fromCircle(center: Offset(bx, by), radius: blueLeafRadius);
      // 전통 단청 담록(연두색/연비취색/담록) 그라데이션
      final Paint blueLeafPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            const Color(0xFFBCE7C6), // 밝은 담록색
            const Color(0xFF78C48C), // 중간 담록색
            const Color(0xFF2C6B43), // 짙은 녹청색 (그림자)
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        ).createShader(leafRect);

      canvas.drawCircle(Offset(bx, by), blueLeafRadius, blueLeafPaint);

      // 청보라색 잎의 흰색 외곽선
      final Paint blueBorder = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(bx, by), blueLeafRadius, blueBorder);
    }

    // [3단계 제거됨] 태극 문양에 밀착되어 사방으로 뻗어 나가던 붉은색/비취색 여의두문 4엽 문양을 제거하여 코어 간섭을 최소화했습니다.


    // ==========================================
    // [4단계] 중앙 금색/노란색 원 (구형 3D 효과)
    // ==========================================
    final double goldRadius = r * 0.19;
    final Rect goldRect = Rect.fromCircle(center: Offset.zero, radius: goldRadius);

    final Paint goldPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFFFF176), // 밝은 황토
          const Color(0xFFFBC02D), // 금색
          const Color(0xFFC59B27), // 짙은 금빛 단청 황
          const Color(0xFF5D4037), // 그림자 어두운 갈색
        ],
        stops: const [0.0, 0.25, 0.6, 0.85, 1.0],
        center: const Alignment(-0.25, -0.25), // 광원이 좌상단에 있는 입체 구체 느낌
      ).createShader(goldRect);

    canvas.drawCircle(Offset.zero, goldRadius, goldPaint);

    // 중앙 노란색 원의 흰색 하이라이트 라인과 어두운 테두리
    final Paint goldBorder = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, goldRadius, goldBorder);

    final Paint goldHighlight = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, goldRadius * 0.9, goldHighlight);

    if (isBlurred) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
