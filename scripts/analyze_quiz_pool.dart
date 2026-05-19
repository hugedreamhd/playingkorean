import 'dart:math';
import '../lib/data/precomputed_homonyms.dart';
import '../lib/core/data/database_helper.dart';

// Copy block list and utility methods from local_quiz_repository_impl.dart to replicate logic exactly.
const Set<String> _beginnerPriorityWords = {
  '밤', '눈', '말', '배', '벌', '김', '차', '공', '장', '방', '줄', '손', '발', '길', '문', '집', '산', '강', '물', '불', '달', '별', '돈', '책',
};

const Set<String> _beginnerBlockedWords = {
  '간지', '간담', '만행', '만수', '구상', '교차', '강설', '강설량', '레이스', '구실', '관료', '형식', '유세', '단위', '지붕', '인체', '강수량', '기상',
};

const List<String> _beginnerHardBlockedDefinitionKeywords = [
  '열녀문', '정려', '정문', '홍문', '유교 경전', '사서', '오경', '십간', '십이지',
];

const List<String> _beginnerBlockedExamplePhrases = [
  '통치', '신당', '창당', '정가', '국회', '의회', '선거운동', '법정', '재판', '행정부', '입법', '헌법', '탄핵', '외교', '조약', '분쟁', '혁명', '봉기', '궁중', '왕조', '성리학', '유교', '불교', '성직자', '주권', '민주주의', '자본주의', '사회주의',
];

const List<String> _beginnerPenaltyDefinitionKeywords = [
  '유교', '경전', '고전', '철학', '문법', '음운', '강설', '강수량', '기상', '행정', '관료', '법률', '정치', '제도', '인체',
];

const List<String> _beginnerEasyDefinitionKeywords = [
  '사람', '집', '학교', '가족', '아이', '친구', '돈', '길', '옷', '음식', '먹', '마시', '손', '발', '방', '문', '책', '차', '산', '강', '물', '불',
];

List<String> _levelPriorityFromDifficulty(String difficulty) {
  if (difficulty == '2') return const ['중급', '초급'];
  return const ['초급', '중급'];
}

bool _isNaturalExample(String example, String word, String difficulty) {
  final e = example.trim();
  if (e.isEmpty) return false;
  if (!e.contains(word)) return false;

  final minLen = 10;
  final maxLen = difficulty == '1' ? 34 : 52;
  if (e.length < minLen || e.length > maxLen) return false;

  const blockedPhrases = [
    '의 뜻', '을 이르는 말', '를 이르는 말', '비유적으로', '속담', '관용', '문장의 단위', '품사', '단위에는', '되다.',
  ];
  for (final p in blockedPhrases) {
    if (e.contains(p)) return false;
  }

  if (difficulty == '1') {
    for (final p in _beginnerBlockedExamplePhrases) {
      if (e.contains(p)) return false;
    }
  }

  if (RegExp(r'[<>\[\]{}※]').hasMatch(e)) return false;
  if (RegExp(r'[A-Za-z]{4,}').hasMatch(e)) return false;
  if (e.startsWith('(') || e.endsWith(')')) return false;
  final tokenCount = e.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).length;
  if (tokenCount < 3) return false;

  return true;
}

int _exampleScore(String example, String word, String difficulty) {
  int score = 0;
  final e = example.trim();
  if (_isNaturalExample(e, word, difficulty)) score += 100;
  score += (60 - (e.length - 24).abs()).clamp(0, 40).toInt();
  if (e.contains('다.') || e.contains('요.')) score += 12;
  if (e.contains(',')) score -= 8;
  return score;
}

bool _containsAny(String source, List<String> keywords) {
  for (final keyword in keywords) {
    if (source.contains(keyword)) return true;
  }
  return false;
}

bool _isHardBlockedBeginnerSense(VocabularyModel s) {
  final defKr = (s.definitionKr ?? '').trim();
  return _containsAny(defKr, _beginnerHardBlockedDefinitionKeywords);
}

int _beginnerSenseScore(VocabularyModel s) {
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

void main() {
  final allRows = kPrecomputedHomonyms.map((m) => VocabularyModel(
        id: m['id']!,
        word: m['word']!,
        level: m['level'],
        homonymNo: int.tryParse(m['homonymNo'] ?? '1') ?? 1,
        definitionKr: m['definitionKr'],
        definitionEn: m['definitionEn'],
        lemmaEn: m['lemmaEn'],
        exampleKr: m['exampleKr'],
      )).toList();

  print('=== 1단계: 전체 데이터 로드 ===');
  print('kPrecomputedHomonyms 총 개수: ${kPrecomputedHomonyms.length}');
  print('VocabularyModel 변환 개수: ${allRows.length}');

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

  print('\n=== 2단계: 단어 그룹화 ===');
  print('총 고유 단어 수: ${groupedByWord.length}');

  // difficulty = '1' (초급) 퀴즈용 candidateWords 조건 필터링 검사
  print('\n=== 3단계: 초급(difficulty=1) candidateWords 필터링 상세 ===');
  int step1Pass = 0; // 초급/중급 최소 1개 포함
  int step2Pass = 0; // hard-blocked senses 제외 후에도 senses >= 2 개 이상 유지
  List<String> candidateWords = [];

  groupedByWord.forEach((word, senseMap) {
    final senses = senseMap.values.toList();
    if (senses.length < 2) return;

    final levels = wordLevels[word] ?? const <String>{};
    final hasBeginnerOrIntermediate = levels.contains('초급') || levels.contains('중급');
    if (hasBeginnerOrIntermediate) {
      step1Pass++;
      final usable = senses.where((s) => !_isHardBlockedBeginnerSense(s)).toList();
      if (usable.length >= 2) {
        step2Pass++;
        candidateWords.add(word);
      }
    }
  });

  print('1) 초급/중급 태그를 가진 단어가 최소 1개 이상인 동음이의어 단어 수: $step1Pass');
  print('2) 하드 블락된 의미(불교, 유교, 십간/십이지 등) 제외 후 2개 이상의 의미가 남는 단어 수: $step2Pass');
  print('   -> 최종 candidateWords 개수: ${candidateWords.length}');

  print('\n=== 4단계: 퀴즈 풀 생성 과정 시뮬레이션 ===');
  int finalPoolCount = 0;
  int fallbackPoolCount = 0;
  List<String> failedAtSensesFilter = [];
  List<String> failedAtOptionSizeFilter = [];
  List<String> failedAtExampleFilter = [];
  List<String> successfulWords = [];

  final preferredLevels = ['초급', '중급'];
  final random = Random(42); // 고정 시드

  for (final word in candidateWords) {
    List<VocabularyModel> senses = groupedByWord[word]!.values.toList();
    
    // 초급 필터링
    final usable = senses.where((s) => !_isHardBlockedBeginnerSense(s)).toList();
    if (usable.length < 2) {
      failedAtSensesFilter.add('$word (usable senses < 2)');
      continue;
    }

    usable.sort((a, b) => _beginnerSenseScore(b).compareTo(_beginnerSenseScore(a)));
    final strict = usable.where((s) => _beginnerSenseScore(s) >= 95).toList();
    final relaxed = usable.where((s) => _beginnerSenseScore(s) >= 75).toList();
    final fallback = usable.where((s) => _beginnerSenseScore(s) >= 55).toList();

    List<VocabularyModel> senseChoices = [];
    if (strict.length >= 2) {
      senseChoices = strict;
    } else if (relaxed.length >= 2) {
      senseChoices = relaxed;
    } else if (fallback.length >= 2) {
      senseChoices = fallback;
    } else {
      senseChoices = usable;
    }

    // 영어 뜻 필터링 (en.isNotEmpty || lemma.isNotEmpty)
    final withEnglish = senseChoices.where((s) {
      final en = (s.definitionEn ?? '').trim();
      final lemma = (s.lemmaEn ?? '').trim();
      return en.isNotEmpty || lemma.isNotEmpty;
    }).toList();

    final optionSize = 2; // 초급은 2
    if (withEnglish.length < optionSize) {
      failedAtOptionSizeFilter.add('$word (english senses ${withEnglish.length} < 2, total senseChoices: ${senseChoices.length})');
      continue;
    }

    // 정답 sense & 예문 필터링
    final pickedSenses = withEnglish.take(optionSize).toList();
    VocabularyModel target = pickedSenses.first;
    int bestScore = -9999;
    for (final s in pickedSenses) {
      final ex = (s.exampleKr ?? '').trim();
      final hasExample = ex.isNotEmpty;
      final lv = (s.level ?? '').trim();
      final score = _exampleScore(ex, word, '1') +
          (preferredLevels.contains(lv) ? 20 : 0) +
          _beginnerSenseScore(s);
      if (hasExample && score > bestScore) {
        bestScore = score;
        target = s;
      }
    }

    final example = (target.exampleKr ?? '').trim();
    final strictExampleOk = _isNaturalExample(example, word, '1');
    final relaxedExampleOk = example.isNotEmpty &&
        example.contains(word) &&
        example.length >= 10 &&
        example.length <= 56 &&
        example.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).length >= 3;

    if (!(strictExampleOk || relaxedExampleOk)) {
      failedAtExampleFilter.add('$word (example: "$example" - length: ${example.length}, strict: $strictExampleOk, relaxed: $relaxedExampleOk)');
      continue;
    }

    successfulWords.add(word);
    finalPoolCount++;
  }

  print('1. 영어 뜻 필터(definitionEn/lemmaEn 존재)에서 탈락한 단어 수: ${failedAtOptionSizeFilter.length}');
  print('   (일부 예시: ${failedAtOptionSizeFilter.take(5).toList()})');
  print('2. 예문 필터(strict/relaxed 예문 기준 미달)에서 탈락한 단어 수: ${failedAtExampleFilter.length}');
  print('   (일부 예시: ${failedAtExampleFilter.take(5).toList()})');
  print('3. 1차 풀 생성에 성공한 단어 수: $finalPoolCount');
  print('   성공한 단어 목록: $successfulWords');

  print('\n=== 5단계: 2차 폴백(fallback) 시뮬레이션 ===');
  List<String> fallbackSuccessWords = [];
  
  for (final word in candidateWords) {
    if (successfulWords.contains(word)) continue;

    List<VocabularyModel> senses = groupedByWord[word]!.values.toList();
    final usable = senses.where((s) => !_isHardBlockedBeginnerSense(s)).toList();
    usable.sort((a, b) => _beginnerSenseScore(b).compareTo(_beginnerSenseScore(a)));

    final withEnglish = usable.where((s) {
      final en = (s.definitionEn ?? '').trim();
      final lemma = (s.lemmaEn ?? '').trim();
      return en.isNotEmpty || lemma.isNotEmpty;
    }).toList();

    final optionSize = 2;
    if (withEnglish.length < optionSize) continue;

    final pickedSenses = withEnglish.take(optionSize).toList();
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
    final fallbackTokenCount = example.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).length;
    if (example.length < 10 || fallbackTokenCount < 3) continue;

    fallbackSuccessWords.add(word);
    fallbackPoolCount++;
  }

  print('4. 2차 폴백에서 추가 생성에 성공한 단어 수: $fallbackPoolCount');
  print('   추가된 단어 목록: $fallbackSuccessWords');

  final totalGenerated = finalPoolCount + fallbackPoolCount;
  print('\n=== 최종 결론 ===');
  print('1차 풀 ($finalPoolCount개) + 2차 폴백 ($fallbackPoolCount개) = 총 생성 가능한 초급 퀴즈 문제 개수: $totalGenerated개');
}
