import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playingkorean/core/di/di_setup.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';
import 'package:playingkorean/presentation/quiz_game/game_view_model.dart';
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

  @override
  void initState() {
    super.initState();
    _viewModel.onAction(
      LoadQuizzes(difficulty: widget.level, count: widget.count),
    );
  }

  @override
  void dispose() {
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
                        const CircularProgressIndicator(color: Color(0xFF81ECE1)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                const SafeArea(
                  child: QuizSkeletonLoader(),
                ),
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
                            const SizedBox(height: 36),

                            // K-네온 오방색 보기 리스트 패널
                            QuizOptionsPanel(
                              question: question,
                              state: state,
                              onSelect: (i) => _viewModel.onAction(SelectOption(i)),
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
            ],
          ),
        );
      },
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
            child: Container(
              color: Colors.transparent,
            ),
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
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            onPressed: () => context.go('/'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              '난이도 ${widget.level == '1' ? '초급' : '중급'}  •  ${state.currentQuestionIndex + 1}/${state.questions.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFCC00), size: 20),
              const SizedBox(width: 4),
              Text(
                '${state.score * 10}',
                style: const TextStyle(
                  color: Color(0xFFFFCC00), // 오방 황색으로 점수 강조
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
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
              final progress = (state.currentQuestionIndex + 1) / state.questions.length;
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
                    )
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
              )
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
      tween: isCritical ? Tween(begin: 1.12, end: 1.0) : Tween(begin: 1.0, end: 1.0),
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
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.alarm_rounded,
                  color: timerColor,
                  size: 18,
                ),
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
                  )
                ],
              ),
            ),
            Icon(
              isPerfect
                  ? Icons.emoji_events_rounded
                  : (isGood ? Icons.military_tech_rounded : Icons.verified_rounded),
              size: 68,
              color: isPerfect
                  ? const Color(0xFFFFCC00)
                  : (isGood ? const Color(0xFFFF9500) : const Color(0xFF81ECE1)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.5),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  '나의 언어 랭크 (Rank):',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPerfect
                                          ? [const Color(0xFFFFCC00), const Color(0xFFFF9500)]
                                          : (isGood
                                              ? [const Color(0xFF007AFF), const Color(0xFF81ECE1)]
                                              : [Colors.blueGrey, Colors.grey]),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isPerfect ? const Color(0xFFFFCC00) : const Color(0xFF007AFF))
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    isPerfect ? 'MASTER (훈장)' : (isGood ? 'EXPERT (달인)' : 'LEARNER (학도)'),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3) 하단 버튼 및 액션
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          _buildSocialIcon(Icons.file_download_rounded, label: '저장'),
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
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
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
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
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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
          style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
