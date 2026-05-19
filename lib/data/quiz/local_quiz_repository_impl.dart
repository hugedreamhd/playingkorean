import 'dart:convert';
import 'dart:math';

import 'package:playingkorean/core/data/database_helper.dart';
import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';
import 'package:playingkorean/core/utils/korean_romanizer.dart';
import 'package:playingkorean/data/precomputed_homonyms.dart';

class LocalQuizRepositoryImpl implements QuizRepository {
  // vocabulary는 precomputed_homonyms.dart의 컴파일 타임 상수에서 직접 로드.
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 출제 이력: 메모리 캐시 (DB와 동기화됨)
  static final Map<String, List<String>> _recentWordsByDifficulty = {};
  static final Map<String, List<String>> _recentContextsByDifficulty = {};
  // 이력 크기 200 = 20라운드(10문항 기준)분 커버
  static const int _recentWordHistorySize = 200;
  static const int _recentContextHistorySize = 200;

  // DB에서 이력을 한 번만 로드하기 위한 플래그
  static final Set<String> _historyLoaded = {};

  static const String _metaShownWordsPrefix = 'shown_words_';
  static const String _metaShownContextsPrefix = 'shown_contexts_';

  // 사전 추출된 동음이의어를 VocabularyModel 리스트로 변환 (한 번만 실행)
  static List<VocabularyModel>? _cachedVocab;
  static List<VocabularyModel> _loadVocab() {
    return _cachedVocab ??= kPrecomputedHomonyms.map((m) => VocabularyModel(
          id: m['id']!,
          word: m['word']!,
          level: m['level'],
          homonymNo: int.tryParse(m['homonymNo'] ?? '1') ?? 1,
          definitionKr: m['definitionKr'],
          definitionEn: m['definitionEn'],
          lemmaEn: m['lemmaEn'],
          exampleKr: m['exampleKr'],
        )).toList();
  }
  static const Set<String> _beginnerPriorityWords = {
    '밤',
    '눈',
    '말',
    '배',
    '벌',
    '김',
    '차',
    '공',
    '장',
    '방',
    '줄',
    '손',
    '발',
    '길',
    '문',
    '집',
    '산',
    '강',
    '물',
    '불',
    '달',
    '별',
    '돈',
    '책',
  };
  static const Set<String> _beginnerBlockedWords = {
    '간지',
    '간담',
    '만행',
    '만수',
    '구상',
    '교차',
    '강설',
    '강설량',
    '레이스',
    '구실',
    '관료',
    '형식',
    '유세',
    '단위',
    '지붕',
    '인체',
    '강수량',
    '기상',
  };
  static const List<String> _beginnerHardBlockedDefinitionKeywords = [
    '열녀문',
    '정려',
    '정문',
    '홍문',
    '유교 경전',
    '사서',
    '오경',
    '십간',
    '십이지',
  ];
  // 초급 예문에 등장하면 안 되는 고급/전문 어휘 (문장 수준 차단)
  static const List<String> _beginnerBlockedExamplePhrases = [
    '통치',
    '신당',
    '창당',
    '정가',
    '국회',
    '의회',
    '선거운동',
    '법정',
    '재판',
    '행정부',
    '입법',
    '헌법',
    '탄핵',
    '외교',
    '조약',
    '분쟁',
    '혁명',
    '봉기',
    '궁중',
    '왕조',
    '성리학',
    '유교',
    '불교',
    '성직자',
    '주권',
    '민주주의',
    '자본주의',
    '사회주의',
  ];
  static const List<String> _beginnerPenaltyDefinitionKeywords = [
    '유교',
    '경전',
    '고전',
    '철학',
    '문법',
    '음운',
    '강설',
    '강수량',
    '기상',
    '행정',
    '관료',
    '법률',
    '정치',
    '제도',
    '인체',
  ];
  static const List<String> _beginnerEasyDefinitionKeywords = [
    '사람',
    '집',
    '학교',
    '가족',
    '아이',
    '친구',
    '돈',
    '길',
    '옷',
    '음식',
    '먹',
    '마시',
    '손',
    '발',
    '방',
    '문',
    '책',
    '차',
    '산',
    '강',
    '물',
    '불',
  ];

  static List<String> _levelPriorityFromDifficulty(String difficulty) {
    // 현재는 초급/중급만 운영
    if (difficulty == '2') return const ['중급', '초급'];
    return const ['초급', '중급'];
  }

  static bool _isNaturalExample(
    String example,
    String word,
    String difficulty,
  ) {
    final e = example.trim();
    if (e.isEmpty) return false;
    if (!e.contains(word)) return false;

    final minLen = difficulty == '1' ? 5 : 10;
    final maxLen = difficulty == '1' ? 34 : 52;
    if (e.length < minLen || e.length > maxLen) return false;

    // 사전식 정의문/메타 설명 제거
    const blockedPhrases = [
      '의 뜻',
      '을 이르는 말',
      '를 이르는 말',
      '비유적으로',
      '속담',
      '관용',
      '문장의 단위',
      '품사',
      '단위에는',
      '되다.',
    ];
    for (final p in blockedPhrases) {
      if (e.contains(p)) return false;
    }

    // 초급에서는 고급/전문 어휘가 포함된 예문 제외
    if (difficulty == '1') {
      for (final p in _beginnerBlockedExamplePhrases) {
        if (e.contains(p)) return false;
      }
    }

    // 특수문자/메타 기호 과다 문장 제거
    if (RegExp(r'[<>\[\]{}※]').hasMatch(e)) return false;
    if (RegExp(r'[A-Za-z]{4,}').hasMatch(e)) return false;
    if (e.startsWith('(') || e.endsWith(')')) return false;
    final tokenCount = e
        .split(RegExp(r'\s+'))
        .where((t) => t.trim().isNotEmpty)
        .length;
    if (tokenCount < (difficulty == '1' ? 2 : 3)) return false;

    return true;
  }

  static int _exampleScore(String example, String word, String difficulty) {
    int score = 0;
    final e = example.trim();
    if (_isNaturalExample(e, word, difficulty)) score += 100;
    score += (60 - (e.length - 24).abs()).clamp(0, 40).toInt();
    if (e.contains('다.') || e.contains('요.')) score += 12;
    if (e.contains(',')) score -= 8;
    return score;
  }

  static bool _containsAny(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) return true;
    }
    return false;
  }

  static bool _isHardBlockedBeginnerSense(VocabularyModel s) {
    final defKr = (s.definitionKr ?? '').trim();
    return _containsAny(defKr, _beginnerHardBlockedDefinitionKeywords);
  }

  static int _beginnerSenseScore(VocabularyModel s) {
    final word = s.word.trim();
    if (word.isEmpty) return -999;
    if (_isHardBlockedBeginnerSense(s)) return -999;

    final defKr = (s.definitionKr ?? '').trim();
    int score = 0;

    final level = (s.level ?? '').trim();
    if (level == '초급') {
      score += 45;
    } else if (level == '중급') {
      score += 15;
    } else {
      score -= 10;
    }

    if (word.length <= 2) score += 20;
    if (word.length == 3) score += 8;
    if (_beginnerPriorityWords.contains(word)) score += 18;
    if (_beginnerBlockedWords.contains(word)) score -= 24;

    if (_containsAny(defKr, _beginnerPenaltyDefinitionKeywords)) score -= 30;
    if (_containsAny(defKr, _beginnerEasyDefinitionKeywords)) score += 16;

    if (defKr.length > 90) score -= 25;
    if (defKr.length > 60) score -= 14;
    if (defKr.length < 20) score += 8;

    final example = (s.exampleKr ?? '').trim();
    if (example.isNotEmpty) score += 12;
    if (_isNaturalExample(example, word, '1')) score += 12;

    return score;
  }


  /// DB에서 해당 난이도의 출제 이력을 로드 (앱 세션당 1회)
  Future<void> _ensureHistoryLoaded(String difficulty) async {
    if (_historyLoaded.contains(difficulty)) return;
    _historyLoaded.add(difficulty);

    try {
      final wordsRaw = await _dbHelper.getMetaValue(
          '$_metaShownWordsPrefix$difficulty');
      if (wordsRaw != null && wordsRaw.isNotEmpty) {
        final decoded = jsonDecode(wordsRaw);
        if (decoded is List) {
          _recentWordsByDifficulty[difficulty] =
              decoded.map((e) => e.toString()).toList();
        }
      }
      final contextsRaw = await _dbHelper.getMetaValue(
          '$_metaShownContextsPrefix$difficulty');
      if (contextsRaw != null && contextsRaw.isNotEmpty) {
        final decoded = jsonDecode(contextsRaw);
        if (decoded is List) {
          _recentContextsByDifficulty[difficulty] =
              decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {
      // 이력 로드 실패 시 빈 이력으로 진행
    }
  }

  /// 출제 이력을 DB에 영구 저장
  Future<void> _saveHistory(String difficulty) async {
    try {
      final words = _recentWordsByDifficulty[difficulty] ?? [];
      final contexts = _recentContextsByDifficulty[difficulty] ?? [];
      await _dbHelper.setMetaValue(
          '$_metaShownWordsPrefix$difficulty', jsonEncode(words));
      await _dbHelper.setMetaValue(
          '$_metaShownContextsPrefix$difficulty', jsonEncode(contexts));
    } catch (_) {
      // 저장 실패 시 무시 (다음 라운드에서 재시도)
    }
  }

  @override
  Future<Result<List<QuizQuestion>, String>> getQuizQuestions({
    String? difficulty,
    int? count,
  }) async {
    try {
      final selectedDifficulty = difficulty ?? '1';
      final preferredLevels = _levelPriorityFromDifficulty(selectedDifficulty);
      final takeCount = count ?? 10;

      // 컴파일 타임 상수에서 즉시 로드 — JSON 스캔/DB 시딩 불필요
      final random = Random();
      final allRows = _loadVocab();

      // DB에서 이력 로드 (세션 첫 호출 시 1회)
      await _ensureHistoryLoaded(selectedDifficulty);

      final Map<String, Map<int, VocabularyModel>> groupedByWord = {};
      final Map<String, Set<String>> wordLevels = {};

      for (final row in allRows) {
        final word = row.word.trim();
        if (word.isEmpty) continue;
        final hn = row.homonymNo ?? 1;

        groupedByWord.putIfAbsent(word, () => {});
        final current = groupedByWord[word]![hn];
        if (current == null) {
          groupedByWord[word]![hn] = row;
        } else {
          // 영어 뜻/예문이 더 풍부한 항목을 우선 유지
          final currentScore =
              ((current.definitionEn ?? '').isNotEmpty ? 1 : 0) +
              ((current.lemmaEn ?? '').isNotEmpty ? 1 : 0) +
              ((current.exampleKr ?? '').isNotEmpty ? 1 : 0);
          final newScore =
              ((row.definitionEn ?? '').isNotEmpty ? 1 : 0) +
              ((row.lemmaEn ?? '').isNotEmpty ? 1 : 0) +
              ((row.exampleKr ?? '').isNotEmpty ? 1 : 0);
          if (newScore > currentScore) {
            groupedByWord[word]![hn] = row;
          }
        }

        final lv = (row.level ?? '').trim();
        if (lv.isNotEmpty) {
          wordLevels.putIfAbsent(word, () => <String>{}).add(lv);
        }
      }

      int priorityOf(String word) {
        final levels = wordLevels[word] ?? const <String>{};
        for (int i = 0; i < preferredLevels.length; i++) {
          if (levels.contains(preferredLevels[i])) return i;
        }
        return preferredLevels.length + 1;
      }

      final recentWords =
          _recentWordsByDifficulty[selectedDifficulty] ?? <String>[];
      final candidateWords = groupedByWord.keys.where((w) {
        final senses = groupedByWord[w]!.values.toList();
        if (senses.length < 2) return false;

        final levels = wordLevels[w] ?? const <String>{};
        if (selectedDifficulty == '1') {
          // 초급 퀴즈: 고급-고급 쌍 제외 (초급 또는 중급 항목이 최소 1개 있어야 함)
          if (!levels.contains('초급') && !levels.contains('중급')) return false;
          final usable = senses
              .where((s) => !_isHardBlockedBeginnerSense(s))
              .toList();
          return usable.length >= 2;
        }
        if (selectedDifficulty == '2') {
          // 중급 퀴즈: 초급 또는 중급 항목이 하나라도 있어야 함
          if (!levels.contains('중급') && !levels.contains('초급')) return false;
        }
        return true;
      }).toList();

      // Fix 3: 이력이 전체 풀의 80% 이상이면 round-robin 리셋
      if (recentWords.length >= (candidateWords.length * 0.8).ceil() &&
          candidateWords.isNotEmpty) {
        _recentWordsByDifficulty[selectedDifficulty] = [];
        _recentContextsByDifficulty[selectedDifficulty] = [];
        await _saveHistory(selectedDifficulty);
      }
      final effectiveRecentWords =
          _recentWordsByDifficulty[selectedDifficulty] ?? <String>[];
      final effectiveRecentContexts =
          _recentContextsByDifficulty[selectedDifficulty] ?? <String>[];

      // 우선순위(선택 난이도와 가까운 레벨) + 랜덤 섞기
      candidateWords.shuffle(random);
      candidateWords.sort((a, b) => priorityOf(a).compareTo(priorityOf(b)));

      // 최근 출제 단어는 우선 제외해서 반복을 줄인다.
      final filteredWords = candidateWords
          .where((w) => !effectiveRecentWords.contains(w))
          .toList();
      List<String> wordsToUse = filteredWords.length >= takeCount
          ? filteredWords
          : candidateWords;
      if (wordsToUse.isEmpty) {
        wordsToUse = candidateWords;
      } else if (wordsToUse.length < takeCount) {
        final merged = <String>[...wordsToUse];
        for (final w in candidateWords) {
          if (!merged.contains(w)) merged.add(w);
        }
        wordsToUse = merged;
      }

      final List<QuizQuestion> quizPool = [];
      final Set<String> seenQuestionKeys = <String>{};

      for (final word in wordsToUse) {
        if (quizPool.length >= takeCount) break;

        List<VocabularyModel> senses = groupedByWord[word]!.values.toList();
        if (selectedDifficulty == '1') {
          final usable = senses
              .where((s) => !_isHardBlockedBeginnerSense(s))
              .toList();
          if (usable.length < 2) continue;

          usable.sort(
            (a, b) => _beginnerSenseScore(b).compareTo(_beginnerSenseScore(a)),
          );
          final strict = usable
              .where((s) => _beginnerSenseScore(s) >= 95)
              .toList();
          final relaxed = usable
              .where((s) => _beginnerSenseScore(s) >= 75)
              .toList();
          final fallback = usable
              .where((s) => _beginnerSenseScore(s) >= 55)
              .toList();

          if (strict.length >= 2) {
            senses = strict;
          } else if (relaxed.length >= 2) {
            senses = relaxed;
          } else if (fallback.length >= 2) {
            senses = fallback;
          } else {
            senses = usable;
          }
        }
        // 영어 뜻이 없는 sense는 보기에서 제외 (뜻 없는 보기 방지)
        senses = senses.where((s) {
          final en = (s.definitionEn ?? '').trim();
          final lemma = (s.lemmaEn ?? '').trim();
          return en.isNotEmpty || lemma.isNotEmpty;
        }).toList();
        senses.shuffle(random);
        final optionSize = selectedDifficulty == '1'
            ? 2
            : (senses.length >= 3 ? 3 : 2);
        if (senses.length < optionSize) continue;
        final pickedSenses = senses.take(optionSize).toList();

        // 정답 sense: 선택 난이도와 가장 가까운 레벨 + 예문 존재 우선
        VocabularyModel target = pickedSenses.first;
        int bestScore = -9999;
        for (final s in pickedSenses) {
          final ex = (s.exampleKr ?? '').trim();
          final hasExample = ex.isNotEmpty;
          final lv = (s.level ?? '').trim();
          final score =
              _exampleScore(ex, word, selectedDifficulty) +
              (preferredLevels.contains(lv) ? 20 : 0) +
              (selectedDifficulty == '1' ? _beginnerSenseScore(s) : 0);
          if (hasExample && score > bestScore) {
            bestScore = score;
            target = s;
          }
        }
        final example = (target.exampleKr ?? '').trim();
        final strictExampleOk = _isNaturalExample(
          example,
          word,
          selectedDifficulty,
        );
        final relaxedExampleOk =
            example.isNotEmpty &&
            example.contains(word) &&
            example.length >= (selectedDifficulty == '1' ? 5 : 10) &&
            example.length <= 56 &&
            example
                    .split(RegExp(r'\s+'))
                    .where((t) => t.trim().isNotEmpty)
                    .length >=
                (selectedDifficulty == '1' ? 2 : 3);
        if (!(strictExampleOk || relaxedExampleOk)) continue;
        // 최근 예문 회피는 너무 강하면 0문항이 되므로, 충분히 모였을 때만 강하게 적용
        if (effectiveRecentContexts.contains(example) &&
            quizPool.length >= (takeCount ~/ 2)) {
          continue;
        }
        final contextText = example.replaceAll(word, '(    )');
        final questionKey = '$word|$contextText';
        if (!seenQuestionKeys.contains(questionKey)) {
          final q = _buildQuestion(
            pickedSenses: pickedSenses,
            target: target,
            contextText: contextText,
            difficulty: selectedDifficulty,
            idPrefix: 'seed_',
            random: random,
          );
          if (q != null) {
            seenQuestionKeys.add(questionKey);
            quizPool.add(q);
          }
        }
      }

      // 3) 2차 폴백: 목표 문항 수에 못 미치면 최소 조건으로 추가 생성
      if (quizPool.length < takeCount) {
        for (final word in candidateWords) {
          if (quizPool.length >= takeCount) break;
          List<VocabularyModel> senses = groupedByWord[word]!.values.toList();
          if (selectedDifficulty == '1') {
            senses = senses
                .where((s) => !_isHardBlockedBeginnerSense(s))
                .toList();
            senses.sort(
              (a, b) =>
                  _beginnerSenseScore(b).compareTo(_beginnerSenseScore(a)),
            );
          }
          // 영어 뜻이 없는 sense는 보기에서 제외
          senses = senses.where((s) {
            final en = (s.definitionEn ?? '').trim();
            final lemma = (s.lemmaEn ?? '').trim();
            return en.isNotEmpty || lemma.isNotEmpty;
          }).toList();
          senses = List<VocabularyModel>.from(senses)..shuffle(random);
          final optionSize = selectedDifficulty == '1'
              ? 2
              : (senses.length >= 3 ? 3 : 2);
          if (senses.length < optionSize) continue;
          final pickedSenses = senses.take(optionSize).toList();

          VocabularyModel target = pickedSenses.first;
          for (final s in pickedSenses) {
            final ex = (s.exampleKr ?? '').trim();
            if (ex.isNotEmpty && ex.contains(word)) {
              target = s;
              break;
            }
          }

          final example = (target.exampleKr ?? '').trim();
          if (example.isEmpty || !example.contains(word)) continue;
          final fallbackTokenCount = example
              .split(RegExp(r'\s+'))
              .where((t) => t.trim().isNotEmpty)
              .length;
          final minLen = selectedDifficulty == '1' ? 5 : 10;
          final minTokens = selectedDifficulty == '1' ? 2 : 3;
          if (example.length < minLen || fallbackTokenCount < minTokens) continue;
          final contextText = example.replaceAll(word, '(    )');
          final questionKey = '$word|$contextText';
          if (!seenQuestionKeys.contains(questionKey)) {
            final q = _buildQuestion(
              pickedSenses: pickedSenses,
              target: target,
              contextText: contextText,
              difficulty: selectedDifficulty,
              idPrefix: 'seed_fallback_',
              random: random,
            );
            if (q != null) {
              seenQuestionKeys.add(questionKey);
              quizPool.add(q);
            }
          }
        }
      }

      if (quizPool.isEmpty) {
        return const Result.failure('이 레벨에 동음이의어 문맥 퀴즈를 만들 수 있는 데이터가 없습니다.');
      }

      // 최종 단계에서는 중복 패딩을 하지 않는다.
      // (같은 문제를 반복해서 10개를 맞추는 현상 방지)

      quizPool.shuffle(random);
      final result = takeCount < quizPool.length
          ? quizPool.take(takeCount).toList()
          : quizPool;

      // 최근 출제 단어 히스토리 갱신
      final usedWords = result
          .map((q) => q.options.isNotEmpty ? q.options[q.answerIndex] : '')
          .where((w) => w.isNotEmpty)
          .toList();
      final usedContexts = result
          .map((q) => q.contextText)
          .where((c) => c.isNotEmpty)
          .toList();
      final merged = [...usedWords, ...effectiveRecentWords];
      final dedup = <String>[];
      for (final w in merged) {
        if (!dedup.contains(w)) dedup.add(w);
      }
      _recentWordsByDifficulty[selectedDifficulty] = dedup
          .take(_recentWordHistorySize)
          .toList();
      final mergedContexts = [...usedContexts, ...effectiveRecentContexts];
      final dedupContexts = <String>[];
      for (final c in mergedContexts) {
        if (!dedupContexts.contains(c)) dedupContexts.add(c);
      }
      _recentContextsByDifficulty[selectedDifficulty] = dedupContexts
          .take(_recentContextHistorySize)
          .toList();

      // Fix 2: 이력을 DB에 영구 저장
      await _saveHistory(selectedDifficulty);

      return Result.success(result);
    } catch (e, stack) {
      return Result.failure('퀴즈 데이터 생성 중 오류 발생: $e\n$stack');
    }
  }

  /// pickedSenses로부터 QuizQuestion을 조립한다.
  /// correctIdx가 유효하지 않으면 null 반환.
  QuizQuestion? _buildQuestion({
    required List<VocabularyModel> pickedSenses,
    required VocabularyModel target,
    required String contextText,
    required String difficulty,
    required String idPrefix,
    required Random random,
  }) {
    final optionSize = pickedSenses.length;
    final options = pickedSenses.map((s) => s.word).toList();
    final romaji = pickedSenses.map((s) {
      final p = (s.pronunciation ?? '').trim();
      return p.isNotEmpty ? p : KoreanRomanizer.romanize(s.word);
    }).toList();
    final englishMeanings = pickedSenses.map((s) {
      final en = (s.definitionEn ?? '').trim();
      return en.isNotEmpty ? en : (s.lemmaEn ?? '').trim();
    }).toList();
    final explanations =
        pickedSenses.map((s) => (s.definitionKr ?? '').trim()).toList();

    final correctIdx = pickedSenses.indexWhere((s) => s.id == target.id);
    if (correctIdx < 0) return null;

    final indices = List<int>.generate(optionSize, (i) => i)..shuffle(random);
    final shuffledAnswerIndex = indices.indexOf(correctIdx);

    return QuizQuestion(
      id: '$idPrefix${target.id}',
      imageUrl: '',
      contextText: contextText,
      options: indices.map((i) => options[i]).toList(),
      romaji: indices.map((i) => romaji[i]).toList(),
      englishMeanings: indices.map((i) => englishMeanings[i]).toList(),
      optionImages: List.filled(optionSize, ''),
      explanations: indices.map((i) => explanations[i]).toList(),
      exampleSentences: List.filled(optionSize, ''),
      difficulty: difficulty,
      answerIndex: shuffledAnswerIndex,
    );
  }

  @override
  Future<Result<bool, String>> submitAnswer(
    String quizId,
    int selectedIndex,
  ) async {
    return const Result.success(true);
  }
}
