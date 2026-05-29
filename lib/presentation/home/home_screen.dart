import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playingkorean/core/presentation/k_traditional_frame.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLevel = '1';
  final int _fixedCount = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1) 홀로그램 테두리 배경 (이미지의 베젤 바깥쪽 영롱한 색상)
          _buildHolographicBackground(),

          // 2) 메인 다크 네이비 컨테이너 (실제 게임 화면)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1224), // 프리미엄 딥 네이비
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: KTraditionalPainter(showKnot: false),
                        ),
                      ),

                      // 실제 콘텐츠 내용물
                      _buildContent(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE0C3FC),
            Color(0xFF8EC5FC),
            Color(0xFFE0C3FC),
            Color(0xFFB2FEFA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB2FEFA).withOpacity(0.8),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: 50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0C3FC).withOpacity(0.8),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 기기 너비에 따른 완벽한 반응형 크기 계산 (가로 오버플로우 예외 방지)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxAvailableWidth = screenWidth - 72; // 마진(12*2) + 패딩(24*2) 반영
    
    // 매듭 크기 및 플레이 버튼 크기 유동적 계산
    final double knotSize = maxAvailableWidth.clamp(200.0, 320.0);
    final double playButtonSize = (knotSize * 0.48).clamp(100.0, 150.0);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),

            // 매듭과 플레이 버튼을 한 스택에 묶어 정확히 정중앙에 겹치도록 정렬
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: knotSize,
                  height: knotSize,
                  child: CustomPaint(
                    painter: KKnotPainter(), 
                  ),
                ),
                PremiumPlayButton(
                  size: playButtonSize,
                  onTap: () {
                    context.go(
                      '/quiz?level=$_selectedLevel&count=$_fixedCount',
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            _buildLevelSelector(),
            const SizedBox(height: 24),
            _buildGuideText(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2436), // 상단 알약 컨테이너 색상
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, color: Color(0xFF5ED8D4), size: 14),
              SizedBox(width: 6),
              Text(
                'PLAYING KOREAN',
                style: TextStyle(
                  color: Color(0xFF5ED8D4),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF81ECE1), Color(0xFF5ED8D4), Color(0xFF4C6EF5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Playing Korean!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '재미있게 플레이하는 동음이의어 퀴즈',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8892A0),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'CHOOSE DIFFICULTY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            color: Color(0xFF8892A0),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2436), // 배경 다크 네이비 알약
            borderRadius: BorderRadius.circular(28),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // constraints.maxWidth는 Container의 padding(4*2=8)이 이미 제외된 실제 내부 가용 너비입니다.
              // 따라서 가용 너비를 정확히 2등분해야 좌우 대칭이 정밀하게 맞습니다.
              final toggleWidth = constraints.maxWidth / 2;
              final isBeginner = _selectedLevel == '1';

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: isBeginner ? 0 : toggleWidth,
                    child: Container(
                      width: toggleWidth,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5ED8D4), // 선택 시 민트/그린
                            Color(0xFF58D68D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
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
                                  size: 18,
                                  color: isBeginner
                                      ? Colors.black87
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '초급 (Beginner)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isBeginner
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isBeginner
                                        ? Colors.black87
                                        : Colors.white54,
                                  ),
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
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: !isBeginner
                                      ? Colors.black87
                                      : const Color(0xFF8892A0),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '중급 (Medium)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: !isBeginner
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: !isBeginner
                                        ? Colors.black87
                                        : const Color(0xFF8892A0),
                                  ),
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

  Widget _buildGuideText() {
    return const Text(
      '원터치로 간결하게 즐기는 학습 플레이!\n하루 10문항으로 재미있는 어휘 챌린지를 즐겨보세요.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: Color(0xFF64748B),
        height: 1.5,
        letterSpacing: -0.2,
      ),
    );
  }
}

class PremiumPlayButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size; // 반응형 스케일 조절을 위한 생성자 매개변수

  const PremiumPlayButton({super.key, required this.onTap, this.size = 150.0});

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
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
        final scale = (_isPressed ? 0.94 : 1.0) * _pulseAnimation.value;

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
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF5ED8D4), Color(0xFF4C6EF5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5ED8D4).withOpacity(0.3),
                    blurRadius: _isPressed ? 12 : 24,
                    spreadRadius: _isPressed ? 1 : 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: widget.size - 16, // 링의 두께 8px 유지
                height: widget.size - 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0D1224), // 내부 다크 네이비 원
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: widget.size * 0.05),
                    Icon(
                      Icons.play_arrow_rounded,
                      size: widget.size * 0.38, // 버튼 크기에 비례하여 아이콘 스케일링
                      color: const Color(0xFF5ED8D4),
                    ),
                    Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: widget.size * 0.1, // 버튼 크기에 비례하여 글씨 스케일링
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: Colors.white,
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
