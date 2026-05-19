import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playingkorean/core/presentation/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLevel = '1';
  final int _fixedCount = 10; // 문항 수는 결정 피로가 없는 가장 이상적인 10문항으로 고정

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // 프리미엄 딥 옵시디언 블랙
      body: Stack(
        children: [
          // 1) 몽환적인 네온 발광 배경 오브제 (Glow Blobs)
          _buildBackgroundGlows(),

          // 2) 실제 UI 콘텐츠 영역
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 메인 헤더 & 타이틀
                    _buildHeader(),
                    const SizedBox(height: 56),

                    // 초강력 도파민 플레이 버튼
                    PremiumPlayButton(
                      onTap: () {
                        // 1초 만에 퀴즈 화면으로 다이렉트 진입 (10문항 고정)
                        context.go(
                          '/quiz?level=$_selectedLevel&count=$_fixedCount',
                        );
                      },
                    ),
                    const SizedBox(height: 56),

                    // 세련된 애니메이션 난이도 슬라이더
                    _buildLevelSelector(),
                    const SizedBox(height: 24),

                    // 가이드 힌트 텍스트
                    _buildGuideText(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 몽환적인 네온 배경 오브제 설계 (Glassmorphic Glow Effect)
  Widget _buildBackgroundGlows() {
    return Stack(
      children: [
        // 상단 우측 민트/그린 발광
        Positioned(
          top: -120,
          right: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF81ECE1).withValues(alpha: 0.15),
            ),
          ),
        ),
        // 하단 좌측 블루 발광
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.background.withValues(alpha: 0.20),
            ),
          ),
        ),
        // 전체 화면을 부드럽게 흐려주는 블러 필터 적용
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  /// 네온 그라데이션 타이틀 헤더 설계
  Widget _buildHeader() {
    return Column(
      children: [
        // 로고 서브 아이콘 효과
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, color: Color(0xFF81ECE1), size: 16),
              SizedBox(width: 6),
              Text(
                'PLAYING KOREAN',
                style: TextStyle(
                  color: Color(0xFF81ECE1),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 그라데이션 텍스트 타이틀
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF81ECE1), // 네온 민트
              Color(0xFF58D68D), // 비비드 그린
              Color(0xFF4C6EF5), // 일렉트릭 블루
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Playing Korean!',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Colors.white, // 그라데이션 적용을 위해 흰색 기본값 설정
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '재미있게 플레이하는 동음이의어 퀴즈',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  /// 세련된 글래스모피즘 캡슐 슬라이더 형태의 난이도 선택기
  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'CHOOSE DIFFICULTY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: Color(0xFF64748B), // 쿨그레이 색상으로 고급스러움 증대
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 60,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final toggleWidth = (constraints.maxWidth - 12) / 2;
              final isBeginner = _selectedLevel == '1';

              return Stack(
                children: [
                  // 슬라이딩 캡슐 배경 오브젝트
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack, // 쫀득한 튕김 모션
                    left: isBeginner ? 0 : toggleWidth,
                    child: Container(
                      width: toggleWidth,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isBeginner
                              ? [
                                  const Color(0xFF58D68D),
                                  const Color(0xFF81ECE1),
                                ]
                              : [
                                  const Color(0xFF4C6EF5),
                                  const Color(0xFF81ECE1),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(23),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isBeginner
                                        ? const Color(0xFF58D68D)
                                        : const Color(0xFF4C6EF5))
                                    .withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 두 가지 선택 버튼
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLevel = '1'),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                  color: isBeginner
                                      ? Colors.black87
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isBeginner
                                        ? Colors.black87
                                        : Colors.white54,
                                    letterSpacing: -0.3,
                                  ),
                                  child: const Text('초급 (Beginner)'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLevel = '2'),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 16,
                                  color: !isBeginner
                                      ? Colors.black87
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: !isBeginner
                                        ? Colors.black87
                                        : Colors.white54,
                                    letterSpacing: -0.3,
                                  ),
                                  child: const Text('중급 (Intermediate)'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// 하단 가이드 및 푸터 디자인
  Widget _buildGuideText() {
    return Text(
      '원터치로 간결하게 즐기는 학습 플레이!\n하루 10문항으로 재미있는 어휘 챌린지를 즐겨보세요.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.35),
        height: 1.5,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// 호흡 펄싱 효과와 쫀득한 3D 반응형 모션이 장착된 프리미엄 플레이 버튼
class PremiumPlayButton extends StatefulWidget {
  final VoidCallback onTap;

  const PremiumPlayButton({super.key, required this.onTap});

  @override
  State<PremiumPlayButton> createState() => _PremiumPlayButtonState();
}

class _PremiumPlayButtonState extends State<PremiumPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // 호흡하듯 부드럽게 무한 반복되는 애니메이션 컨트롤러
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // 터치 시 스케일 감소와 펄스 애니메이션 곱연산 처리
        final scale = (_isPressed ? 0.92 : 1.0) * _pulseAnimation.value;

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF58D68D), // 네온 그린
                    Color(0xFF4C6EF5), // 일렉트릭 블루
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  // 원형 외각의 몽환적인 발광 섀도우
                  BoxShadow(
                    color: const Color(0xFF4C6EF5).withValues(alpha: 0.35),
                    blurRadius: _isPressed ? 16 : 32,
                    spreadRadius: _isPressed ? 1 : 4,
                    offset: const Offset(0, 8),
                  ),
                  // 자연스러운 3D 질감을 표현하기 위한 하이라이트 섀도우
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(-3, -3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 154,
                height: 154,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0F172A), // 중앙에 어두운 코어를 뚫어 프리미엄 입체감 설계
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 네온 민트 색상의 거대한 플레이 아이콘
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 64,
                      color: Color(0xFF81ECE1),
                    ),
                    const SizedBox(height: 1),
                    // 플레이 텍스트와 세련된 그림자
                    Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.5,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: const Color(
                              0xFF81ECE1,
                            ).withValues(alpha: 0.7),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
