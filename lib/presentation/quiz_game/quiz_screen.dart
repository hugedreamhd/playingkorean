import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playingkorean/core/ads/google_ad_manager.dart';
import 'package:playingkorean/core/di/di_setup.dart';
import 'package:playingkorean/core/presentation/yeopjeon_painter.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';
import 'package:playingkorean/presentation/quiz_game/game_view_model.dart';
import 'package:playingkorean/presentation/quiz_game/widgets/ad_simulation_dialog.dart';
import 'package:playingkorean/presentation/quiz_game/widgets/quiz_answer_feedback.dart';
import 'package:playingkorean/presentation/quiz_game/widgets/quiz_options_panel.dart';
import 'package:playingkorean/presentation/quiz_game/widgets/quiz_skeleton_loader.dart';

class QuizScreen extends StatefulWidget {
  final String level;
  final int count;

  const QuizScreen({super.key, required this.level, required this.count});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final GameViewModel _viewModel = getIt<GameViewModel>();

  // 족자 배너 관련 상태
  bool _showMapaeScrollBanner = false;
  String _mapaeScrollBannerText = '';
  Timer? _scrollBannerTimer;

  void _triggerMapaeScrollBanner(String message) {
    _scrollBannerTimer?.cancel();
    setState(() {
      _mapaeScrollBannerText = message;
      _showMapaeScrollBanner = true;
    });

    _scrollBannerTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() {
          _showMapaeScrollBanner = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _viewModel.onAction(
      LoadQuizzes(difficulty: widget.level, count: widget.count),
    );
  }

  @override
  void dispose() {
    _scrollBannerTimer?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameState>(
      stream: _viewModel.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? GameState();

        // 1) 데이터 로딩 상태 화면 (K-네온 다크 테마 적용)
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Stack(
              children: [
                _buildBackgroundGlows(),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF81ECE1),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '동음이의어 문제를 찾는 중...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '처음 실행 시 데이터 로딩에 잠시 시간이 걸릴 수 있습니다.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 2) 데이터 로딩 에러 상태 화면
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Stack(
              children: [
                _buildBackgroundGlows(),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFFF3B30),
                            size: 64,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '데이터 로딩 실패\n(Data Loading Failed)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 36),
                          ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF3B30),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('홈으로 돌아가기 (Back to Home)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 3) 모든 퀴즈 완료 시 결과 화면 송출
        if (state.isFinished) {
          return _buildResult(context, state);
        }

        final question = state.currentQuestion;

        // 4) 로딩은 끝났으나 퀴즈 문항이 없을 때
        if (state.questions.isEmpty && !state.isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Stack(
              children: [
                _buildBackgroundGlows(),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            color: Colors.white38,
                            size: 64,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '이 난이도에 동음이의어 문제가\n존재하지 않습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 36),
                          ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF81ECE1),
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('홈으로 돌아가기'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 5) 문제 로딩 대기 뼈대(Skeleton)
        if (question == null || state.questions.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Stack(
              children: [
                _buildBackgroundGlows(),
                const SafeArea(child: QuizSkeletonLoader()),
              ],
            ),
          );
        }

        // 6) 본 퀴즈 풀이 화면 (K-네온 오방색 스타일 적용)
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // 딥 옵시디언 흑
          body: Stack(
            children: [
              _buildBackgroundGlows(),
              SafeArea(
                child: Column(
                  children: [
                    // 커스텀 네온 상단 바
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildAppBar(context, state),
                          _buildProgressBar(state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 중간 콘텐츠 영역 (개방감 향상을 위해 프레임 제거)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            // 3D 홀로그램식 문제 카드
                            _buildQuestionCard(state, question),
                            const SizedBox(height: 12),

                            // 암행어사 마패 찬스 버튼 추가
                            _buildMapaeButton(context, state),
                            const SizedBox(height: 16),

                            // K-네온 오방색 보기 리스트 패널
                            QuizOptionsPanel(
                              question: question,
                              state: state,
                              onSelect: (i) =>
                                  _viewModel.onAction(SelectOption(i)),
                            ),
                            const SizedBox(height: 120), // 하단 피드백 시트 공간 확보
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 정/오답 제출 시 하단 네온 피드백 패널 슬라이드인
              if (state.lastAnswerCorrect != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value * 300),
                        child: child,
                      );
                    },
                    child: QuizAnswerFeedback(
                      state: state,
                      question: question,
                      onNext: () => _viewModel.onAction(NextQuestion()),
                    ),
                  ),
                ),

              // 전통 족자 알림 배너 슬라이드다운
              AnimatedPositioned(
                duration: const Duration(milliseconds: 650),
                curve: Curves.fastOutSlowIn,
                top: _showMapaeScrollBanner
                    ? (MediaQuery.of(context).padding.top + 12)
                    : -120,
                left: 16,
                right: 16,
                child: _buildScrollBanner(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollBanner() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScrollRoller(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFBF8EE), // 한지 텍스처 느낌의 베이지톤
                    Color(0xFFF1E9D2),
                    Color(0xFFFBF8EE),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: Color(0xFFC0392B), // 전통 붉은 매듭 실선 테두리
                    width: 2.2,
                  ),
                ),
              ),
              child: ClipRect(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 애니메이션 없이 정적으로 렌더링하는 미니 마패
                        SizedBox(
                          width: 32,
                          height: 36,
                          child: CustomPaint(
                            painter: MapaePainter(animationValue: 0.0),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mapaeScrollBannerText,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '암행어사 출두의 힘으로 오답이 소멸하였습니다.',
                              style: TextStyle(
                                color: Color(0xFF7A6B58),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildScrollRoller(),
        ],
      ),
    );
  }

  Widget _buildScrollRoller() {
    return Container(
      width: 14,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A3403), // 짙은 나무 기둥
            Color(0xFF8A6615), // 밝은 나무 무늬결
            Color(0xFF4A3403),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFD4AF37), // 위아래 금박 장식 느낌 마감 테두리
          width: 1.2,
        ),
      ),
    );
  }

  /// 몽환적인 K-네온 배경 오브제 (홈 화면과 완벽 일치로 브랜딩 통일)
  Widget _buildBackgroundGlows() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF81ECE1).withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF007AFF).withValues(alpha: 0.15), // 오방 청색
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  /// 커스텀 네온 앱 바
  Widget _buildAppBar(BuildContext context, GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => context.go('/'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              '난이도 ${widget.level == '1' ? '초급' : '중급'}  •  ${state.currentQuestionIndex + 1}/${state.questions.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            children: [
              const YeopjeonWidget(size: 16),
              const SizedBox(width: 4),
              Text(
                '${state.coins}',
                style: const TextStyle(
                  color: Color(0xFFE5C158),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFCC00),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${state.score * 10}',
                style: const TextStyle(
                  color: Color(0xFFFFCC00), // 오방 황색으로 점수 강조
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 그라데이션 게이밍 게이지 바
  Widget _buildProgressBar(GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Stack(
        children: [
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final progress =
                  (state.currentQuestionIndex + 1) / state.questions.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuad,
                height: 10,
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF81ECE1), Color(0xFF58D68D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF58D68D).withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 3D 반투명 홀로그램식 문제 카드 빌드
  Widget _buildQuestionCard(GameState state, dynamic question) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(state.currentQuestionIndex),
        tween: Tween(begin: 0.94, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02), // 극도로 얇은 다크 유리 코팅
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), // 미세한 림 하이라이트
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // 영어 문맥 가이드 텍스트 (여백의 미를 살린 폰트)
              Text(
                question.exampleSentences[question.answerIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.40),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              // 거대한 빈칸 채우기 한국어 문장 (주목도 최대화)
              Text(
                _formatContextText(question.contextText),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.5,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              // 네온 타이머 바
              _buildTimer(state),
            ],
          ),
        ),
      ),
    );
  }

  /// {(      )로} 또는 (      ) 형태의 빈칸을 (    ) 형태로 정규화
  String _formatContextText(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'\{\s*\(\s*\)\s*([가-힣]*)\}'),
          (match) => '(  ?  )${match.group(1) ?? ''}',
        )
        .replaceAllMapped(
          RegExp(r'\{[\s]*\([\s]*\)[\s]*\}'),
          (match) => '(  ?  )',
        )
        .replaceAllMapped(
          RegExp(r'\(\s{4,}\)([가-힣]*)'),
          (match) => '(  ?  )${match.group(1) ?? ''}',
        );
  }

  /// 네온 타이머 (시간 임박 시 태극 적색 발광 깜빡임 적용)
  Widget _buildTimer(GameState state) {
    final isCritical = state.remainingSeconds <= 5;
    final timerColor = isCritical ? const Color(0xFFFF3B30) : Colors.white70;

    return TweenAnimationBuilder<double>(
      key: ValueKey(state.remainingSeconds),
      duration: const Duration(milliseconds: 250),
      tween: isCritical
          ? Tween(begin: 1.12, end: 1.0)
          : Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isCritical
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCritical
                    ? const Color(0xFFFF3B30)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: isCritical
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.alarm_rounded, color: timerColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${state.remainingSeconds}s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: timerColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultHeader(bool isPerfect, bool isGood) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFCC00).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Icon(
              isPerfect
                  ? Icons.emoji_events_rounded
                  : (isGood
                        ? Icons.military_tech_rounded
                        : Icons.verified_rounded),
              size: 68,
              color: isPerfect
                  ? const Color(0xFFFFCC00)
                  : (isGood
                        ? const Color(0xFFFF9500)
                        : const Color(0xFF81ECE1)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          isPerfect ? '완벽한 마스터!' : (isGood ? '대단한 실력이에요!' : '한걸음 더 나아가요!'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isPerfect
              ? 'Perfect Korean Achieved'
              : (isGood ? 'Outstanding Performance' : 'Step-by-step Learning'),
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context, GameState state) {
    final accuracy = (state.questions.isNotEmpty)
        ? (state.score / state.questions.length) * 100
        : 0.0;
    final isPerfect = accuracy == 100;
    final isGood = accuracy >= 70;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          _buildBackgroundGlows(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // 1) 웅장한 K-네온 트로피 헤더 애니메이션
                _buildResultHeader(isPerfect, isGood),
                const SizedBox(height: 24),

                // 2) K-네온 유리 대시보드 요약 정보 카드
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1.5,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'CHALLENGE SUMMARY',
                                  style: TextStyle(
                                    color: Color(0xFF81ECE1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '아래로 스크롤',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      color: const Color(
                                        0xFF81ECE1,
                                      ).withValues(alpha: 0.7),
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                _buildStatCard(
                                  '맞힌 문제',
                                  '${state.score} / ${state.questions.length}',
                                  Icons.check_circle_rounded,
                                  const Color(0xFF58D68D),
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  '정답률',
                                  '${accuracy.toInt()}%',
                                  Icons.offline_bolt_rounded,
                                  const Color(0xFF007AFF),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '이번 시험으로 얻은 엽전:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const YeopjeonWidget(size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      '+${state.earnedCoins}냥',
                                      style: const TextStyle(
                                        color: Color(0xFFE5C158),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '나의 총 엽전 (Total):',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const YeopjeonWidget(size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${state.coins}냥',
                                      style: const TextStyle(
                                        color: Color(0xFFE5C158),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '나의 언어 랭크 (Rank):',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPerfect
                                          ? [
                                              const Color(0xFFFFCC00),
                                              const Color(0xFFFF9500),
                                            ]
                                          : (isGood
                                                ? [
                                                    const Color(0xFF007AFF),
                                                    const Color(0xFF81ECE1),
                                                  ]
                                                : [
                                                    Colors.blueGrey,
                                                    Colors.grey,
                                                  ]),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isPerfect
                                                    ? const Color(0xFFFFCC00)
                                                    : const Color(0xFF007AFF))
                                                .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    isPerfect
                                        ? 'MASTER (훈장)'
                                        : (isGood
                                              ? 'EXPERT (달인)'
                                              : 'LEARNER (학도)'),
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _buildScrollGuideBanner(),
                            _buildExplanationSection(state),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3) 하단 버튼 및 액션
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!state.isDoubleRewardClaimed &&
                          state.earnedCoins > 0) ...[
                        _buildActionButton(
                          label: '조력자(광고) 찬스로 엽전 2배 받기 🎬',
                          icon: Icons.movie_creation_outlined,
                          color: const Color(0xFF5ED8D4),
                          onTap: () async {
                            final isAdSupported =
                                !kIsWeb &&
                                (Platform.isAndroid || Platform.isIOS);
                            bool adSuccess = false;

                            if (isAdSupported) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('엽전 2배 보상을 위해 광고를 불러오는 중...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );

                              adSuccess = await GoogleAdManager()
                                  .showRewardedAd(
                                    onUserEarnedReward: () {
                                      _viewModel.onAction(ClaimDoubleReward());
                                    },
                                  );
                            }

                            if (!adSuccess) {
                              final simulationSuccess = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const AdSimulationDialog(
                                  title: '엽전 2배 보상을 위해 광고(시뮬레이션)를 재생합니다...',
                                ),
                              );
                              if (simulationSuccess == true) {
                                _viewModel.onAction(ClaimDoubleReward());
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (state.failedQuestions.isNotEmpty) ...[
                        _buildActionButton(
                          label: '오답 다시 풀기 (${state.failedQuestions.length})',
                          icon: Icons.replay_rounded,
                          color: const Color(0xFFFF3B30),
                          onTap: () => _viewModel.onAction(StartReview()),
                          isOutlined: true,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _buildActionButton(
                        label: '홈으로 돌아가기',
                        icon: Icons.home_rounded,
                        color: const Color(0xFF58D68D),
                        onTap: () => context.go('/'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialIcon(Icons.share_rounded, label: '공유'),
                          const SizedBox(width: 44),
                          _buildSocialIcon(
                            Icons.file_download_rounded,
                            label: '저장',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 글래스 3D 액션 버튼
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                shadowColor: color.withValues(alpha: 0.3),
              ),
            ),
    );
  }

  /// 소셜 버튼
  Widget _buildSocialIcon(IconData icon, {required String label}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Icon(icon, color: Colors.white70, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildScrollGuideBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF81ECE1).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF81ECE1).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF81ECE1),
            size: 16,
          ),
          const SizedBox(width: 8),
          const Text(
            '문제의 해설과 뜻이 아래에 있습니다. 👇',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationSection(GameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF81ECE1),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '문제 해설집 & 복습노트',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.questions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final question = state.questions[index];
            final isFailed = state.failedQuestions.any(
              (fq) => fq.id == question.id,
            );
            final correctAnswer = question.options[question.answerIndex];
            final romaji = question.romaji[question.answerIndex];
            final meaning = question.englishMeanings[question.answerIndex];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFailed
                      ? const Color(0xFFFF3B30).withValues(alpha: 0.2)
                      : const Color(0xFF58D68D).withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFailed
                              ? const Color(0xFFFF3B30).withValues(alpha: 0.15)
                              : const Color(0xFF58D68D).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFailed ? '오답 🔴' : '정답 🟢',
                          style: TextStyle(
                            color: isFailed
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF58D68D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Q${index + 1}. ${_formatContextText(question.contextText)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  iconColor: Colors.white70,
                  collapsedIconColor: Colors.white30,
                  childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
                  children: [
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '정답 단어: ',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            '$correctAnswer [$romaji] - $meaning',
                            style: const TextStyle(
                              color: Color(0xFF81ECE1),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (question.explanations.isNotEmpty) ...[
                      const Text(
                        '해설:',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.explanations.join('\n'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMapaeButton(BuildContext context, GameState state) {
    final hasEnoughCoins = state.coins >= 30;
    final isAnswered = state.lastAnswerCorrect != null;
    final optionsCount = state.currentQuestion?.options.length ?? 4;
    final alreadyUsedMax =
        state.disabledOptionIndices.length >= optionsCount - 1;
    final isLimitReached = state.mapaeUsedCount >= 2;

    // 이미 문제를 맞혔거나 오답 제거 찬스를 최대로 썼을 때(정답만 남았을 때)는 버튼을 아예 숨김
    if (isAnswered || alreadyUsedMax) return const SizedBox.shrink();

    final canUseDirectly = !alreadyUsedMax && hasEnoughCoins && !isLimitReached;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: canUseDirectly
              ? [
                  BoxShadow(
                    color: const Color(0xFFE5C158).withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: const Color(0xFF0F172A), // 나전칠기 느낌의 검푸른 어두운 배경
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: alreadyUsedMax || isLimitReached
                ? null
                : () => _handleMapaeUse(context, state),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: canUseDirectly
                      ? const Color(0xFFE5C158) // 엽전 충분 시 찬란한 금테
                      : isLimitReached
                      ? Colors.white.withValues(alpha: 0.1) // 한도 도달 시 회색 테
                      : const Color(
                          0xFF5ED8D4,
                        ).withValues(alpha: 0.2), // 부족 시 옥색 테두리
                  width: canUseDirectly ? 1.8 : 1.2,
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 새롭게 제작한 암행어사 마패 아이콘 위젯 배치 (한도 도달 시 애니메이션 OFF)
                  MapaeIconWidget(animate: canUseDirectly),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '암행어사 마패 찬스',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: canUseDirectly
                                    ? const Color(0xFFFFF7D6) // 골드 텍스트
                                    : isLimitReached
                                    ? Colors
                                          .white30 // 한도 초과 시 어두운 텍스트
                                    : Colors.white70,
                                letterSpacing: 0.8,
                                shadows: canUseDirectly
                                    ? [
                                        Shadow(
                                          color: const Color(
                                            0xFFE5C158,
                                          ).withValues(alpha: 0.5),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            // 시각적 도장/마패 인디케이터 배치
                            _buildUsageIndicators(state.mapaeUsedCount),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLimitReached
                              ? '이번 판 사용 제한(2/2)에 도달하였습니다.'
                              : '오답 1개를 즉시 소멸!',
                          style: TextStyle(
                            fontSize: 11,
                            color: isLimitReached
                                ? Colors.white30
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canUseDirectly
                            ? const Color(0xFFE5C158).withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const YeopjeonWidget(size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '30냥',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasEnoughCoins && !isLimitReached
                                ? const Color(0xFFE5C158)
                                : Colors.white38,
                          ),
                        ),
                      ],
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

  Widget _buildUsageIndicators(int usedCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        final isUsed = index < usedCount;
        return Container(
          margin: const EdgeInsets.only(left: 8.0),
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isUsed
                  ? const Color(0xFFD32F2F) // 사용됨: 붉은색
                  : const Color(
                      0xFFE5C158,
                    ).withValues(alpha: 0.4), // 미사용: 흐린 골드
              width: 1.0,
            ),
            color: isUsed ? const Color(0xFFD32F2F) : Colors.transparent,
          ),
          child: Center(
            child: isUsed
                ? const Icon(Icons.close, size: 8, color: Colors.white)
                : Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE5C158).withValues(alpha: 0.6),
                    ),
                  ),
          ),
        );
      }),
    );
  }

  void _handleMapaeUse(BuildContext context, GameState state) async {
    // 판당 최대 2회 제한 검사
    if (state.mapaeUsedCount >= 2) return;

    // 광고가 뜨거나 다이얼로그가 진행되는 동안 타이머 일시정지
    _viewModel.onAction(PauseTimer());

    if (state.coins >= 30) {
      _viewModel.onAction(UseMapaeChance());
      _triggerMapaeScrollBanner('암행어사 출두야! 오답 1개 소멸!');
      _viewModel.onAction(ResumeTimer());
    } else {
      final isAdSupported = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      bool adSuccess = false;

      if (isAdSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('조력자(광고)의 지혜를 불러오는 중입니다...'),
            duration: Duration(seconds: 1),
          ),
        );

        adSuccess = await GoogleAdManager().showRewardedAd(
          onUserEarnedReward: () {
            _viewModel.onAction(AdWatchedForMapae());
          },
        );
      }

      if (!adSuccess) {
        final simulationSuccess = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AdSimulationDialog(
            title: '엽전이 부족하여 조력자(광고 시뮬레이션)의 도움을 요청합니다...',
          ),
        );

        if (simulationSuccess == true) {
          _viewModel.onAction(AdWatchedForMapae());
          if (mounted) {
            _triggerMapaeScrollBanner('조력자의 지혜로 오답 1개 소멸!');
          }
        }
      } else {
        if (mounted) {
          _triggerMapaeScrollBanner('조력자의 지혜로 오답 1개 소멸!');
        }
      }

      // 광고 시청 완료/닫기 후 타이머 재개
      _viewModel.onAction(ResumeTimer());
    }
  }
}

// 암행어사 마패 아이콘 위젯 (애니메이션 포함)
class MapaeIconWidget extends StatefulWidget {
  final bool animate;
  const MapaeIconWidget({super.key, this.animate = true});

  @override
  State<MapaeIconWidget> createState() => _MapaeIconWidgetState();
}

class _MapaeIconWidgetState extends State<MapaeIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 마패가 살짝 좌우로 흔들리는 애니메이션
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.08), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 숨쉬는 듯한 박동 애니메이션
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MapaeIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _scaleAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.animate ? _rotationAnimation.value : 0.0,
            child: CustomPaint(
              size: const Size(36, 40),
              painter: MapaePainter(animationValue: _controller.value),
            ),
          ),
        );
      },
    );
  }
}

class MapaePainter extends CustomPainter {
  final double animationValue;
  MapaePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double radius = w * 0.40;
    final Offset center = Offset(w * 0.5, h * 0.58);

    // 1. 상단 전통 고리 장식
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFD4AF37), // Metallic Gold
          Color(0xFFFFF0A5), // Highlight
          Color(0xFFAA7C11), // Dark Brass
          Color(0xFF8A6615),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.35, h * 0.08, w * 0.3, h * 0.22))
      ..style = PaintingStyle.fill;

    final ringPath = Path()
      ..moveTo(w * 0.32, h * 0.30)
      ..lineTo(w * 0.32, h * 0.16)
      ..quadraticBezierTo(w * 0.32, h * 0.08, w * 0.42, h * 0.08)
      ..lineTo(w * 0.58, h * 0.08)
      ..quadraticBezierTo(w * 0.68, h * 0.08, w * 0.68, h * 0.16)
      ..lineTo(w * 0.68, h * 0.30)
      ..close();

    canvas.drawPath(ringPath, ringPaint);

    // 고리 구멍
    final ringHolePaint = Paint()
      ..color =
          const Color(0xFF0F172A) // 심해색/배경 어두운색
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.42, h * 0.14, w * 0.16, h * 0.08),
        const Radius.circular(3),
      ),
      ringHolePaint,
    );

    // 2. 붉은색 전통 술 매듭
    final redPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    // 고리에 묶인 동그란 매듭
    canvas.drawCircle(Offset(w * 0.5, h * 0.11), 3.5, redPaint);

    // 3. 마패 원형 본체 (입체감 있는 방사형 황동색 그라데이션)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(center + const Offset(1, 1.5), radius, shadowPaint);

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: const [
          Color(0xFFFFF7D6), // 하이라이트 골드
          Color(0xFFE5C158), // 주 금색
          Color(0xFFAA7C11), // 황동색
          Color(0xFF4E3602), // 어두운 청동색
        ],
        stops: const [0.0, 0.45, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bodyPaint);

    // 이중 동심원 테두리 데코레이션
    final innerBorderPaint = Paint()
      ..color = const Color(0xFF4E3602).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 3, innerBorderPaint);

    final outerBorderPaint = Paint()
      ..color = const Color(0xFFFFF7D6).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius, outerBorderPaint);

    // 4. 삼마패 (말 3마리 실루엣 드로잉)
    final horsePaint = Paint()
      ..color = const Color(0xFF231701)
      ..style = PaintingStyle.fill;

    final sideHorsePaint = Paint()
      ..color = const Color(0xFF231701).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // 중앙 말 (가장 크고 또렷하게)
    _drawHorse(canvas, center + const Offset(0, 1), radius * 0.95, horsePaint);
    // 좌측 말 (약간 뒤쪽에 배치)
    _drawHorse(
      canvas,
      center + const Offset(-5, 3),
      radius * 0.78,
      sideHorsePaint,
    );
    // 우측 말 (약간 앞/뒤쪽에 배치)
    _drawHorse(
      canvas,
      center + const Offset(5, -0.5),
      radius * 0.78,
      sideHorsePaint,
    );
  }

  void _drawHorse(Canvas canvas, Offset pos, double size, Paint paint) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    final Path p = Path();
    final double w = size;
    final double h = size;

    // 말의 시작 위치 (-w/2, -h/2 기준)
    final double sx = -w * 0.48;
    final double sy = -h * 0.36;

    // 역동적으로 달리는 말 실루엣
    p.moveTo(sx + w * 0.22, sy + h * 0.48);
    // 목덜미 & 갈기
    p.quadraticBezierTo(
      sx + w * 0.28,
      sy + h * 0.28,
      sx + w * 0.38,
      sy + h * 0.28,
    );
    // 귀
    p.lineTo(sx + w * 0.41, sy + h * 0.20);
    p.lineTo(sx + w * 0.44, sy + h * 0.28);
    // 얼굴 & 코
    p.quadraticBezierTo(
      sx + w * 0.54,
      sy + h * 0.31,
      sx + w * 0.52,
      sy + h * 0.39,
    );
    p.quadraticBezierTo(
      sx + w * 0.46,
      sy + h * 0.43,
      sx + w * 0.40,
      sy + h * 0.45,
    );
    // 가슴
    p.quadraticBezierTo(
      sx + w * 0.48,
      sy + h * 0.55,
      sx + w * 0.58,
      sy + h * 0.55,
    );
    // 등 & 엉덩이
    p.quadraticBezierTo(
      sx + w * 0.73,
      sy + h * 0.48,
      sx + w * 0.83,
      sy + h * 0.45,
    );
    // 꼬리
    p.quadraticBezierTo(
      sx + w * 0.94,
      sy + h * 0.48,
      sx + w * 0.97,
      sy + h * 0.60,
    );
    p.quadraticBezierTo(
      sx + w * 0.85,
      sy + h * 0.62,
      sx + w * 0.81,
      sy + h * 0.56,
    );
    // 뒷다리 1
    p.lineTo(sx + w * 0.79, sy + h * 0.75);
    p.lineTo(sx + w * 0.73, sy + h * 0.76);
    p.lineTo(sx + w * 0.75, sy + h * 0.58);
    // 배
    p.quadraticBezierTo(
      sx + w * 0.58,
      sy + h * 0.65,
      sx + w * 0.45,
      sy + h * 0.60,
    );
    // 앞다리 1
    p.lineTo(sx + w * 0.35, sy + h * 0.78);
    p.lineTo(sx + w * 0.29, sy + h * 0.76);
    p.lineTo(sx + w * 0.38, sy + h * 0.52);

    p.close();
    canvas.drawPath(p, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapaePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
