import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playingkorean/core/di/di_setup.dart';
import 'package:playingkorean/core/presentation/app_theme.dart';
import 'package:playingkorean/presentation/quiz_game/game_state.dart';
import 'package:playingkorean/presentation/quiz_game/game_view_model.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/presentation/quiz_game/widgets/quiz_option_button.dart';
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
  Widget build(BuildContext context) {
    return StreamBuilder<GameState>(
      stream: _viewModel.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? GameState();

        if (state.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    '동음이의어 문제를 찾는 중...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '처음 실행 시 잠시 시간이 걸릴 수 있습니다.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '데이터 로딩 실패\n(Data Loading Failed)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pointGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('홈으로 돌아가기 (Back to Home)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state.isFinished) {
          return _buildResult(context, state);
        }

        final question = state.currentQuestion;

        // questions 자체가 비어있는 경우 (로딩은 완료됐지만 동음이의어가 없음)
        if (state.questions.isEmpty && !state.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off,
                      color: Colors.white70,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '이 레벨에 동음이의어 문제가\n없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pointGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('홈으로 돌아가기'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (question == null || state.questions.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
              centerTitle: true,
            ),
            body: const QuizSkeletonLoader(),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
            title: Text(
              'Level ${widget.level} - ${state.currentQuestionIndex + 1}/${state.questions.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    'Score: ${state.score}',
                    style: TextStyle(
                      color: AppTheme.pointGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      value:
                          (state.currentQuestionIndex + 1) /
                          state.questions.length,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.pointGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 질문 카드
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(state.currentQuestionIndex),
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Card(
                      elevation: 12,
                      color: Colors.white.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 영어 문장 (문맥 힌트)
                            Text(
                              question.exampleSentences[question.answerIndex],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 한국어 문장 (빈칸 포함)
                            Text(
                              _formatContextText(question.contextText),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // 타이머
                            _buildTimer(state),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // 보기 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),

                  child: _buildOptions(context, state, question),
                ),
                // 하단 액션 (정답 확인 후 슬라이드 업)
                if (state.lastAnswerCorrect != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value * 100),
                        child: child,
                      );
                    },
                    child: _buildPostAnswerActions(context, state, question),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 보기 버튼 렌더링 - 2개/3개: 세로, 4개+: 2x2 그리드
  /// - Column 안에 Expanded 사용 금지 (Exception 원인)
  /// - 보기에는 영문뜻(englishMeanings)만 표시
  Widget _buildOptions(
    BuildContext context,
    GameState state,
    QuizQuestion question,
  ) {
    final optionCount = question.options.length;

    // 안전한 값 추출 헬퍼
    String safeRomaji(int i) =>
        question.romaji.length > i ? question.romaji[i] : '';
    String toConciseMeaning(String raw) {
      var text = raw.trim();
      if (text.isEmpty) return '';

      // 괄호/대괄호 메타 정보 제거
      text = text.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim();
      text = text.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
      if (text.isEmpty) return '';

      // 첫 구/절만 사용해 핵심 의미만 노출
      final firstChunk = text.split(RegExp(r'[;,.]')).first.trim();
      text = firstChunk;
      text = text.replaceFirst(
        RegExp(r'^(a|an|the)\s+', caseSensitive: false),
        '',
      );
      text = text.replaceFirst(RegExp(r'^to\s+', caseSensitive: false), 'to ');

      final words = text
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
      if (words.length > 5) {
        return words.take(5).join(' ');
      }
      return text;
    }

    String? safeEnglish(int i) {
      // 보기는 항상 짧고 딱 떨어지는 영어 핵심 의미만 노출
      if (question.englishMeanings.length > i) {
        final concise = toConciseMeaning(question.englishMeanings[i]);
        if (concise.isNotEmpty) return concise;
      }
      return null;
    }

    Widget buildButton(int index) {
      final isCorrect = state.lastAnswerCorrect;
      final isSelected = state.selectedOptionIndex == index;
      final isAnswer = index == question.answerIndex;
      return QuizOptionButton(
        text: question.options[index],
        romaji: safeRomaji(index),
        english: safeEnglish(index),
        type: ChoiceType.values[index % 4],
        onTap: () => _viewModel.onAction(SelectOption(index)),
        isCorrect: isCorrect,
        isSelected: isSelected,
        isAnswer: isAnswer,
      );
    }

    // 2~3개 보기: 세로 배치 (폭이 좁아 보이는 문제 해결)
    if (optionCount <= 3) {
      return Column(
        children: List.generate(optionCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < optionCount - 1 ? 12 : 0),
            child: SizedBox(width: double.infinity, child: buildButton(i)),
          );
        }),
      );
    }

    // 4개 이상(혹시 모를 확장): 2열 그리드
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: optionCount,
      itemBuilder: (context, i) => buildButton(i),
    );
  }

  /// {(      )로} 또는 (      ) 형태의 빈칸을 (    ) 형태로 정규화
  String _formatContextText(String text) {
    // { ( ) } 패턴을 찾아서 ( ) 형태로 변환
    // 예: {(      )을} → (    )을 / {(      )로} → (    )로
    return text
        .replaceAllMapped(
          RegExp(r'\{\s*\(\s*\)\s*([가-힣]*)\}'),
          (match) => '(    )${match.group(1) ?? ''}',
        )
        .replaceAllMapped(
          // 남은 { ( ) } 패턴 처리 (조사 없는 경우)
          RegExp(r'\{[\s]*\([\s]*\)[\s]*\}'),
          (match) => '(    )',
        )
        .replaceAllMapped(
          // plain (      ) 형태 처리 (공백 4개 이상)
          RegExp(r'\(\s{4,}\)([가-힣]*)'),
          (match) => '(    )${match.group(1) ?? ''}',
        );
  }

  Widget _buildTimer(GameState state) {
    final isCritical = state.remainingSeconds <= 5;
    return TweenAnimationBuilder<double>(
      key: ValueKey(state.remainingSeconds),
      duration: const Duration(milliseconds: 200),
      tween: isCritical
          ? Tween(begin: 1.1, end: 1.0)
          : Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isCritical
                  ? Colors.red.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCritical ? Colors.red : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: isCritical ? Colors.red : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${state.remainingSeconds}s',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostAnswerActions(
    BuildContext context,
    GameState state,
    QuizQuestion question,
  ) {
    final isCorrect = state.lastAnswerCorrect ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppTheme.pointGreen : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct! (정답입니다)' : 'Wrong... (틀렸습니다)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppTheme.pointGreen : Colors.red,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _viewModel.onAction(NextQuestion()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pointGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next (다음)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 상세 설명 - 카드 디자인으로 변경
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppTheme.pointGreen.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isCorrect
                    ? AppTheme.pointGreen.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.lightbulb : Icons.info_outline,
                      size: 18,
                      color: isCorrect ? AppTheme.pointGreen : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCorrect
                          ? 'Correct Meaning'
                          : 'Let\'s check the meanings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? AppTheme.pointGreen : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 모든 보기의 의미 나열
                ...List.generate(question.options.length, (i) {
                  final isThisAnswer = i == question.answerIndex;
                  final isUserSelected = i == state.selectedOptionIndex;
                  final romaji = question.romaji.length > i
                      ? question.romaji[i]
                      : '';
                  final englishMeaning = (question.englishMeanings.length > i)
                      ? question.englishMeanings[i]
                      : '';
                  final explanation = (question.explanations.length > i)
                      ? question.explanations[i]
                      : '';

                  // 영문 뜻이 있으면 영문 뜻을, 없으면 한글 설명을 사용
                  final displayMeaning = englishMeaning.isNotEmpty
                      ? englishMeaning
                      : explanation;

                  final isHighlighted = isThisAnswer || isUserSelected;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? (isThisAnswer
                                ? AppTheme.pointGreen.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isThisAnswer
                              ? Icons.check_circle
                              : (isUserSelected
                                    ? Icons.cancel
                                    : Icons.circle_outlined),
                          size: 16,
                          color: isThisAnswer
                              ? AppTheme.pointGreen
                              : (isUserSelected ? Colors.red : Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                  text: question.options[i],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (romaji.isNotEmpty)
                                  TextSpan(
                                    text: ' ($romaji)',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                TextSpan(
                                  text: ' : $displayMeaning',
                                  style: TextStyle(
                                    color: isThisAnswer
                                        ? AppTheme.pointGreen
                                        : Colors.black54,
                                    fontWeight: isThisAnswer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, GameState state) {
    final accuracy = (state.questions.isNotEmpty)
        ? (state.score / state.questions.length) * 100
        : 0.0;
    final isPerfect = accuracy == 100;
    final isGood = accuracy >= 70;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.background.withBlue(50)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              // 헤더 및 메인 아이콘
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        Icon(
                          isPerfect
                              ? Icons.emoji_events
                              : (isGood
                                    ? Icons.stars
                                    : Icons.sentiment_satisfied),
                          size: 100,
                          color: isPerfect
                              ? Colors.amber
                              : (isGood ? Colors.orange : Colors.grey[400]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPerfect
                          ? 'Perfect Score!'
                          : (isGood ? 'Great Job!' : 'Keep Practicing!'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // 결과 카드
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance Summary',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            _buildStatCard(
                              'Correct',
                              '${state.score}/${state.questions.length}',
                              Icons.check_circle_outline,
                              AppTheme.pointGreen,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'Accuracy',
                              '${accuracy.toInt()}%',
                              Icons.auto_graph,
                              Colors.blueAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // 랭크 표시
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Language Rank:',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPerfect
                                    ? Colors.amber
                                    : (isGood
                                          ? Colors.orange
                                          : Colors.blueGrey),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isPerfect
                                    ? 'MASTER'
                                    : (isGood ? 'EXPERT' : 'LEARNER'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // 하단 액션 버튼들
                        Column(
                          children: [
                            if (state.failedQuestions.isNotEmpty)
                              _buildActionButton(
                                label:
                                    'Review Wrong Answers (${state.failedQuestions.length})',
                                icon: Icons.replay,
                                color: Colors.redAccent,
                                onTap: () => _viewModel.onAction(StartReview()),
                                isOutlined: true,
                              ),
                            const SizedBox(height: 12),
                            _buildActionButton(
                              label: 'Back to Home',
                              icon: Icons.home,
                              color: AppTheme.pointGreen,
                              onTap: () => context.go('/'),
                            ),
                            const SizedBox(height: 24),
                            // 가상의 공유 섹션
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialIcon(Icons.share, label: 'Share'),
                                const SizedBox(width: 32),
                                _buildSocialIcon(
                                  Icons.download,
                                  label: 'Save Result',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
    );
  }

  Widget _buildSocialIcon(IconData icon, {required String label}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
