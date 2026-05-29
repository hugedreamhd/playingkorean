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
    void drawAuspiciousKnot(double cx, double cy, double signX, double signY) {
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

      // 2. **내부 얽힘 (Inner Intertwining, 얇은 선)**
      // 외부 루프 안쪽에서 두 개의 고리가 서로 엇갈리는 복잡한 모양.
      // 사용자 코드의 cubicTo는 너무 복잡해서 어설픈 모양을 만듭니다. 더 단순하고 깔끔한 얽힌 루프를 만듭니다.
      
      final Path innerKnotPath = Path();
      
      // 첫 번째 이미지의 얇은 선 루프는 가로 고리와 세로 고리가 서로 엇갈립니다.
      // 이 두 개의 고리를 그리기 위해 Path를 두 부분으로 나눕니다.

      // [가로 고리]
      innerKnotPath.moveTo(innerCornerGap * 0.8, innerPad);
      innerKnotPath.arcToPoint(Offset(innerPad, innerCornerGap * 0.8), radius: Radius.circular(innerPad * 0.5));
      innerKnotPath.lineTo(innerPad, innerPad);
      innerKnotPath.lineTo(innerCornerGap * 0.8, innerPad);

      // [세로 고리] (직각으로 교차)
      innerKnotPath.moveTo(innerPad, innerCornerGap * 0.8);
      innerKnotPath.arcToPoint(Offset(innerCornerGap * 0.8, innerPad), radius: Radius.circular(innerPad * 0.5));
      innerKnotPath.lineTo(innerCornerGap * 0.8, innerCornerGap * 0.8);
      innerKnotPath.lineTo(innerPad, innerCornerGap * 0.8);
      
      // 이 두 개의 고리가 서로 얽히는 모양을 위해 Path를 더 정교하게 쪼개야 하지만,
      // 사용자 코드의 save/scale 구조에서는 단순한 루프를 엇갈리게 그리는 것만으로도 두 번째 사진보다 훨씬 선명하고 선명한 느낌을 줍니다.

      // 3. **중앙 교차 (Center Crossover)**
      // 두 내부 루프가 교차하는 중앙에 작은 'ㄱ'자형 루프를 추가하여 얽힘을 더 강조합니다.
      // `borderAxiPath`를 활용합니다.
      final Path borderAxiPath = Path();
      borderAxiPath.moveTo(innerPad + innerCornerGap * 0.4, innerPad);
      borderAxiPath.quadraticBezierTo(innerPad, innerPad, innerPad, innerPad + innerCornerGap * 0.4);

      // 최종 드로잉
      canvas.drawPath(outerKnotPath, outerPaint);
      canvas.drawPath(innerKnotPath, innerPaint);
      canvas.drawPath(borderAxiPath, innerPaint); // 얇은 펜으로 그리기

      canvas.restore();
    }

    // 4개 모서리에 각각 회전/반전 매핑하여 그리기
    drawAuspiciousKnot(pad, pad, 1, 1);           // 좌측 상단
    drawAuspiciousKnot(w - pad, pad, -1, 1);       // 우측 상단
    drawAuspiciousKnot(pad, h - pad, 1, -1);       // 좌측 하단
    drawAuspiciousKnot(w - pad, h - pad, -1, -1);   // 우측 하단
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
    // [1단계] 가장 바깥쪽 녹색 겹잎 (단청 8엽 무늬) - 8중 조밀한 레이어로 확장
    // ==========================================
    final double outerLeafRadius = r * 0.355; // 크기를 0.34에서 0.355로 증가
    final double leafDistance = r * 0.67;

    // 조밀하게 나뉜 띠가 선명하게 돋보이도록 하는 어두운 경계선
    final Paint strokePaint = Paint()
      ..color = const Color(0xFF081C10) // 아주 짙은 묵록색
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // 두 번째 사진의 촘촘한 겹선을 재현하는 색상 및 스케일 배열
    final List<Map<String, dynamic>> layers = [
      {'scale': 1.0, 'color': const Color(0xFF0F361E)},   // 1층: 가장 바깥쪽 깊은 녹색
      {'scale': 0.88, 'color': const Color(0xFF2E7D32)},  // 2층: 짙은 단청 초록
      {'scale': 0.77, 'color': const Color(0xFF4CAF50)},  // 3층: 중간 단청 연록
      {'scale': 0.66, 'color': const Color(0xFF81C784)},  // 4층: 밝은 비취색
      {'scale': 0.55, 'color': const Color(0xFF1B5E20)},  // 5층: 대비를 주는 안쪽 짙은 녹색
      {'scale': 0.44, 'color': const Color(0xFF003300)},  // 6층: 아주 짙은 청록선
      {'scale': 0.33, 'color': const Color(0xFFC8E6C9)},  // 7층: 밝은 연두/백록
      {'scale': 0.18, 'color': const Color(0xFFFFEB3B)},  // 8층 (심부): 빛나는 노란색 눈(Dot)
    ];

    // 8방향 잎사귀에 대해 레이어 순차 드로잉 (바깥 -> 안)
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
        
        // 촘촘한 동심원 무늬 경계를 뚜렷하게 살려주는 외곽 스트로크
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
      final Paint blueLeafPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            const Color(0xFF7E57C2), // 부드러운 보라
            const Color(0xFF3F51B5), // 깊은 청색
            const Color(0xFF1A237E), // 짙은 네이비
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

    // ==========================================
    // [3단계] 상하좌우 4방향 붉은색/자주색 꽃잎 (여의두문 4엽) - 크기 및 너비 대폭 확장
    // ==========================================
    final Paint redBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2 // 더 강력하고 볼륨감 넘치는 흰색 테두리
      ..strokeJoin = StrokeJoin.round;

    final Paint redInnerBorderPaint = Paint()
      ..color = const Color(0xFF4A0010) // 짙은 테두리
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2); // 0도, 90도, 180도, 270도 회전

      final Path redLeafPath = Path();
      // 단청 특유의 양 옆으로 둥글고 넓게 퍼지며 면적이 압도적으로 큰 여의두 곡선으로 튜닝
      redLeafPath.moveTo(r * 0.08, 0);
      redLeafPath.cubicTo(
        r * 0.22, -r * 0.48, // y축 제어점을 늘려 날개의 둥근 볼륨 확장
        r * 0.62, -r * 0.52,
        r * 0.64, -r * 0.18
      );
      redLeafPath.cubicTo(
        r * 0.66, -r * 0.06,
        r * 0.74, -r * 0.03,
        r * 0.77, 0           // 도달 범위를 0.65에서 0.77로 늘려 붉은 면적을 극대화
      );
      redLeafPath.cubicTo(
        r * 0.74, r * 0.03,
        r * 0.66, r * 0.06,
        r * 0.64, r * 0.18
      );
      redLeafPath.cubicTo(
        r * 0.62, r * 0.52,
        r * 0.22, r * 0.48,
        r * 0.08, 0
      );
      redLeafPath.close();

      // 자주색/붉은색 단청 그라데이션 채우기 (확장된 영역에 알맞게 Rect 크기 조율)
      final Rect redRect = Rect.fromLTWH(r * 0.05, -r * 0.5, r * 0.72, r * 1.0);
      final Paint redLeafPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF3D57), // 더욱 맑고 환한 적색 (눈에 띔)
            const Color(0xFFD81B60), // 중간 붉은 자주
            const Color(0xFF880E4F), // 짙은 홍색
            const Color(0xFF3E001C), // 깊은 어두운 자주
          ],
          stops: const [0.0, 0.45, 0.85, 1.0],
        ).createShader(redRect);

      canvas.drawPath(redLeafPath, redLeafPaint);
      canvas.drawPath(redLeafPath, redBorderPaint);
      canvas.drawPath(redLeafPath, redInnerBorderPaint);

      // --- 잎 내부의 전통 당초 소용돌이 장식선 (C-curve) - 커진 크기에 맞게 비례 조정 ---
      final Paint swirlPaint = Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final Path swirlPath = Path();
      // 위쪽 잎 날개에 들어가는 소용돌이
      swirlPath.moveTo(r * 0.56, -r * 0.10);
      swirlPath.cubicTo(
        r * 0.44, -r * 0.22,
        r * 0.32, -r * 0.20,
        r * 0.30, -r * 0.08
      );
      swirlPath.cubicTo(
        r * 0.28, r * 0.06,
        r * 0.38, r * 0.18,
        r * 0.52, r * 0.10
      );

      canvas.drawPath(swirlPath, swirlPaint);
      canvas.restore();
    }

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
