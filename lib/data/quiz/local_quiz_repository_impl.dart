import 'dart:convert';
import 'dart:math';

import 'package:playingkorean/core/data/database_helper.dart';
import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';
import 'package:playingkorean/data/quiz/vocabulary_seeder.dart';
import 'package:playingkorean/core/utils/korean_romanizer.dart';

class LocalQuizRepositoryImpl implements QuizRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final VocabularySeeder _seeder = VocabularySeeder();
  static final Map<String, List<String>> _recentWordsByDifficulty = {};
  static final Map<String, List<String>> _recentContextsByDifficulty = {};
  static const int _recentWordHistorySize = 40;
  static const int _recentContextHistorySize = 60;
  static const String _metaSeedOrderKey = 'seed_cycle_order';
  static const String _metaSeedIndexKey = 'seed_cycle_index';
  static List<String>? _seedCycleOrderCache;
  static int? _seedCycleIndexCache;
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

  Future<void> _saveSeedCycleState(List<String> order, int index) async {
    _seedCycleOrderCache = List<String>.from(order);
    _seedCycleIndexCache = index;
    await _dbHelper.setMetaValue(_metaSeedOrderKey, jsonEncode(order));
    await _dbHelper.setMetaValue(_metaSeedIndexKey, index.toString());
  }

  bool _isValidSeedOrder(List<String> order) {
    const files = VocabularySeeder.jsonFiles;
    if (order.length != files.length) return false;
    final orderSet = order.toSet();
    return orderSet.length == files.length && orderSet.containsAll(files);
  }

  Future<({List<String> order, int index})> _loadSeedCycleState() async {
    if (_seedCycleOrderCache != null && _seedCycleIndexCache != null) {
      final normalized = _seedCycleIndexCache!.clamp(
        0,
        _seedCycleOrderCache!.length,
      );
      return (order: _seedCycleOrderCache!, index: normalized);
    }

    const files = VocabularySeeder.jsonFiles;
    final savedOrderRaw = await _dbHelper.getMetaValue(_metaSeedOrderKey);
    final savedIndexRaw = await _dbHelper.getMetaValue(_metaSeedIndexKey);

    List<String>? savedOrder;
    if (savedOrderRaw != null && savedOrderRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedOrderRaw);
        if (decoded is List) {
          savedOrder = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        savedOrder = null;
      }
    }

    int savedIndex = int.tryParse(savedIndexRaw ?? '') ?? 0;

    if (savedOrder == null || !_isValidSeedOrder(savedOrder)) {
      final newOrder = List<String>.from(files)..shuffle(Random());
      await _saveSeedCycleState(newOrder, 0);
      return (order: newOrder, index: 0);
    }

    if (savedIndex < 0 || savedIndex > savedOrder.length) {
      savedIndex = 0;
    }

    _seedCycleOrderCache = savedOrder;
    _seedCycleIndexCache = savedIndex;
    return (order: savedOrder, index: savedIndex);
  }

  Future<List<String>> _nextSeedWindow({int size = 3}) async {
    if (size <= 0) return const [];
    const files = VocabularySeeder.jsonFiles;
    if (files.isEmpty) return const [];

    final state = await _loadSeedCycleState();
    var order = List<String>.from(state.order);
    var index = state.index;
    final window = <String>[];

    while (window.length < size) {
      if (index >= order.length) {
        order = List<String>.from(files)..shuffle(Random());
        index = 0;
      }

      final remainingToFill = size - window.length;
      final endExclusive = min(index + remainingToFill, order.length);
      window.addAll(order.sublist(index, endExclusive));
      index = endExclusive;
    }

    await _saveSeedCycleState(order, index);
    return window;
  }

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

    final minLen = difficulty == '1' ? 10 : 10;
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

    // 특수문자/메타 기호 과다 문장 제거
    if (RegExp(r'[<>\[\]{}※]').hasMatch(e)) return false;
    if (RegExp(r'[A-Za-z]{4,}').hasMatch(e)) return false;
    if (e.startsWith('(') || e.endsWith(')')) return false;
    if (e.split(' ').length < (difficulty == '1' ? 3 : 2)) return false;

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

  static bool _isBeginnerFriendlySense(VocabularyModel s) {
    return _beginnerSenseScore(s) >= 70;
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
      final seedWindow = await _nextSeedWindow(size: 3);

      // 1) 시딩: 11개 파일을 랜덤 순서로 한 바퀴 소진 후 재셔플
      final isEmpty = await _dbHelper.isVocabularyEmpty();
      if (isEmpty) {
        await _seeder.seed(
          files: seedWindow,
          maxEntriesPerFile: 500,
          maxTotalItems: 2500,
        );
      } else {
        // 과거 실패 시딩(0~소량 삽입) 자동 복구 + 윈도우 보강 시딩
        final totalRows = await _dbHelper.countVocabularyRows();
        if (totalRows < 2500) {
          await _dbHelper.clearVocabulary();
          await _seeder.seed(
            files: seedWindow,
            maxEntriesPerFile: 500,
            maxTotalItems: 2500,
          );
        } else {
          // 매 회차마다 다른 파일 윈도우를 소량 보강해 다양성 확장
          await _seeder.seed(
            files: seedWindow,
            maxEntriesPerFile: 180,
            maxTotalItems: 900,
          );
        }
      }

      // 2) 동음이의어 문맥 퀴즈 생성 (단어 중복 최소화)
      // - word별로 homonym_no가 2개 이상인 그룹만 사용
      // - 한 단어당 1문항만 출제하여 "구, 구, 구..." 반복 방지
      final random = Random();

      final db = await _dbHelper.database;
      final maps = await db.query(
        'vocabulary',
        where: "IFNULL(example_kr, '') != ''",
        limit: 15000,
      );
      final allRows = maps.map((m) => VocabularyModel.fromMap(m)).toList();

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
      final recentContexts =
          _recentContextsByDifficulty[selectedDifficulty] ?? <String>[];
      final candidateWords = groupedByWord.keys.where((w) {
        final senses = groupedByWord[w]!.values.toList();
        if (senses.length < 2) return false;
        if (selectedDifficulty == '1') {
          final usable = senses
              .where((s) => !_isHardBlockedBeginnerSense(s))
              .toList();
          return usable.length >= 2;
        }
        return true;
      }).toList();

      // 우선순위(선택 난이도와 가까운 레벨) + 랜덤 섞기
      candidateWords.shuffle(random);
      candidateWords.sort((a, b) => priorityOf(a).compareTo(priorityOf(b)));

      // 최근 출제 단어는 우선 제외해서 반복을 줄인다.
      final filteredWords = candidateWords
          .where((w) => !recentWords.contains(w))
          .toList();
      List<String> wordsToUse = filteredWords.length >= takeCount
          ? filteredWords
          : candidateWords;
      if (selectedDifficulty == '1') {
        // 초급은 우선 화이트리스트 단어만 사용
        final priority = wordsToUse
            .where(_beginnerPriorityWords.contains)
            .toList();
        if (priority.length >= takeCount) {
          wordsToUse = priority;
        } else {
          // 모자라면 초급 friendly sense가 있는 단어를 단계적으로 추가
          final extra = wordsToUse.where((w) {
            final senses = groupedByWord[w]!.values.toList();
            return senses.any(_isBeginnerFriendlySense);
          }).toList();
          final merged = <String>[...priority];
          for (final w in extra) {
            if (!merged.contains(w)) merged.add(w);
          }
          wordsToUse = merged;
        }
      }
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
            example.length >= 6 &&
            example.length <= 56;
        if (!(strictExampleOk || relaxedExampleOk)) continue;
        // 최근 예문 회피는 너무 강하면 0문항이 되므로, 충분히 모였을 때만 강하게 적용
        if (recentContexts.contains(example) &&
            quizPool.length >= (takeCount ~/ 2)) {
          continue;
        }
        final contextText = example.replaceAll(word, '(    )');

        final options = pickedSenses.map((s) => s.word).toList();
        final romaji = pickedSenses.map((s) {
          final p = (s.pronunciation ?? '').trim();
          return p.isNotEmpty ? p : KoreanRomanizer.romanize(s.word);
        }).toList();
        final englishMeanings = pickedSenses.map((s) {
          final en = (s.definitionEn ?? '').trim();
          if (en.isNotEmpty) return en;
          return (s.lemmaEn ?? '').trim();
        }).toList();
        final explanations = pickedSenses
            .map((s) => (s.definitionKr ?? '').trim())
            .toList();

        final correctIdx = pickedSenses.indexWhere((s) => s.id == target.id);
        if (correctIdx < 0) continue;
        final indices = List<int>.generate(optionSize, (i) => i)
          ..shuffle(random);
        final shuffledAnswerIndex = indices.indexOf(correctIdx);

        quizPool.add(
          QuizQuestion(
            id: 'seed_${target.id}',
            imageUrl: '',
            contextText: contextText,
            options: indices.map((i) => options[i]).toList(),
            romaji: indices.map((i) => romaji[i]).toList(),
            englishMeanings: indices.map((i) => englishMeanings[i]).toList(),
            optionImages: List.filled(optionSize, ''),
            explanations: indices.map((i) => explanations[i]).toList(),
            exampleSentences: List.filled(optionSize, ''),
            difficulty: selectedDifficulty,
            answerIndex: shuffledAnswerIndex,
          ),
        );
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
          final contextText = example.replaceAll(word, '(    )');

          final options = pickedSenses.map((s) => s.word).toList();
          final romaji = pickedSenses.map((s) {
            final p = (s.pronunciation ?? '').trim();
            return p.isNotEmpty ? p : KoreanRomanizer.romanize(s.word);
          }).toList();
          final englishMeanings = pickedSenses.map((s) {
            final en = (s.definitionEn ?? '').trim();
            if (en.isNotEmpty) return en;
            return (s.lemmaEn ?? '').trim();
          }).toList();
          final explanations = pickedSenses
              .map((s) => (s.definitionKr ?? '').trim())
              .toList();

          final correctIdx = pickedSenses.indexWhere((s) => s.id == target.id);
          if (correctIdx < 0) continue;
          final indices = List<int>.generate(optionSize, (i) => i)
            ..shuffle(random);
          final shuffledAnswerIndex = indices.indexOf(correctIdx);

          quizPool.add(
            QuizQuestion(
              id: 'seed_fallback_${target.id}',
              imageUrl: '',
              contextText: contextText,
              options: indices.map((i) => options[i]).toList(),
              romaji: indices.map((i) => romaji[i]).toList(),
              englishMeanings: indices.map((i) => englishMeanings[i]).toList(),
              optionImages: List.filled(optionSize, ''),
              explanations: indices.map((i) => explanations[i]).toList(),
              exampleSentences: List.filled(optionSize, ''),
              difficulty: selectedDifficulty,
              answerIndex: shuffledAnswerIndex,
            ),
          );
        }
      }

      if (quizPool.isEmpty) {
        return const Result.failure('이 레벨에 동음이의어 문맥 퀴즈를 만들 수 있는 데이터가 없습니다.');
      }

      // 4) 최종 안전장치: 어떤 경우에도 요청 문항 수를 맞춘다.
      if (quizPool.length < takeCount) {
        final base = List<QuizQuestion>.from(quizPool);
        int pad = 0;
        while (quizPool.length < takeCount && base.isNotEmpty) {
          final source = base[pad % base.length];
          final optionCount = source.options.length;
          final indices = List<int>.generate(optionCount, (i) => i)
            ..shuffle(random);
          final remixedAnswerIndex = indices.indexOf(source.answerIndex);
          quizPool.add(
            QuizQuestion(
              id: '${source.id}_pad_$pad',
              imageUrl: source.imageUrl,
              contextText: source.contextText,
              options: indices.map((i) => source.options[i]).toList(),
              romaji: indices.map((i) => source.romaji[i]).toList(),
              englishMeanings: indices
                  .map((i) => source.englishMeanings[i])
                  .toList(),
              optionImages: indices.map((i) => source.optionImages[i]).toList(),
              explanations: indices.map((i) => source.explanations[i]).toList(),
              exampleSentences: indices
                  .map((i) => source.exampleSentences[i])
                  .toList(),
              difficulty: source.difficulty,
              answerIndex: remixedAnswerIndex,
            ),
          );
          pad++;
        }
      }

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
      final merged = [...usedWords, ...recentWords];
      final dedup = <String>[];
      for (final w in merged) {
        if (!dedup.contains(w)) dedup.add(w);
      }
      _recentWordsByDifficulty[selectedDifficulty] = dedup
          .take(_recentWordHistorySize)
          .toList();
      final mergedContexts = [...usedContexts, ...recentContexts];
      final dedupContexts = <String>[];
      for (final c in mergedContexts) {
        if (!dedupContexts.contains(c)) dedupContexts.add(c);
      }
      _recentContextsByDifficulty[selectedDifficulty] = dedupContexts
          .take(_recentContextHistorySize)
          .toList();

      return Result.success(result);
    } catch (e, stack) {
      return Result.failure('퀴즈 데이터 생성 중 오류 발생: $e\n$stack');
    }
  }

  @override
  Future<Result<bool, String>> submitAnswer(
    String quizId,
    int selectedIndex,
  ) async {
    return const Result.success(true);
  }
}
