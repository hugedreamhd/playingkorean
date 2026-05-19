// scripts/count_candidate_pool.dart
// 실행: dart run scripts/count_candidate_pool.dart

import '../lib/data/precomputed_homonyms.dart';

// === 아래는 local_quiz_repository_impl.dart와 동일한 로직 ===

const Set<String> _beginnerHardBlockedDefinitionKeywords = {
  '열녀문', '정려', '정문', '홍문', '유교 경전', '사서', '오경', '십간', '십이지',
};

bool _isHardBlockedBeginnerSense(Map<String, String> s) {
  final defKr = (s['definitionKr'] ?? '').trim();
  for (final keyword in _beginnerHardBlockedDefinitionKeywords) {
    if (defKr.contains(keyword)) return true;
  }
  return false;
}

void main() {
  final allRows = kPrecomputedHomonyms;

  print('=== 전체 항목 수: ${allRows.length} ===\n');

  // 레벨별 카운트
  final levelCount = <String, int>{};
  for (final row in allRows) {
    final level = row['level'] ?? '없음';
    levelCount[level] = (levelCount[level] ?? 0) + 1;
  }
  print('레벨별 항목 수:');
  levelCount.forEach((k, v) => print('  $k: $v개'));
  print('');

  // 단어별 그룹핑
  final groupedByWord = <String, Map<int, Map<String, String>>>{};
  final wordLevels = <String, Set<String>>{};

  for (final row in allRows) {
    final word = (row['word'] ?? '').trim();
    if (word.isEmpty) continue;
    final hn = int.tryParse(row['homonymNo'] ?? '1') ?? 1;

    groupedByWord.putIfAbsent(word, () => {});
    groupedByWord[word]![hn] = row;

    final lv = (row['level'] ?? '').trim();
    if (lv.isNotEmpty) {
      wordLevels.putIfAbsent(word, () => <String>{}).add(lv);
    }
  }

  print('=== 고유 단어(표제어) 수: ${groupedByWord.length} ===\n');

  // ── 초급 퀴즈 후보 풀 계산 ──
  final beginnerCandidates = <String>[];
  final beginnerFailReasons = <String, List<String>>{};

  for (final word in groupedByWord.keys) {
    final senses = groupedByWord[word]!.values.toList();
    final levels = wordLevels[word] ?? const <String>{};

    // 조건 1: 동음이의어 2개 이상
    if (senses.length < 2) {
      beginnerFailReasons.putIfAbsent('동음이의어 1개뿐', () => []).add(word);
      continue;
    }

    // 조건 2: 초급 또는 중급 레벨이 하나 이상
    if (!levels.contains('초급') && !levels.contains('중급')) {
      beginnerFailReasons.putIfAbsent('초급/중급 레벨 없음', () => []).add(word);
      continue;
    }

    // 조건 3: 하드 차단 필터 후 2개 이상 남아야 함
    final usable = senses.where((s) => !_isHardBlockedBeginnerSense(s)).toList();
    if (usable.length < 2) {
      beginnerFailReasons.putIfAbsent('하드차단 후 1개 이하', () => []).add(word);
      continue;
    }

    // 조건 4: 영어 뜻이 있는 sense가 2개 이상
    final withEnglish = usable.where((s) {
      final en = (s['definitionEn'] ?? '').trim();
      final lemma = (s['lemmaEn'] ?? '').trim();
      return en.isNotEmpty || lemma.isNotEmpty;
    }).toList();
    if (withEnglish.length < 2) {
      beginnerFailReasons.putIfAbsent('영어뜻 있는 sense 1개 이하', () => []).add(word);
      continue;
    }

    beginnerCandidates.add(word);
  }

  print('=== 초급 퀴즈 후보 단어 수: ${beginnerCandidates.length} ===');
  print('  → 30문제 세트로: ${beginnerCandidates.length ~/ 30}회 가능');
  print('  → 겹치지 않는 총 문제 수: ${beginnerCandidates.length}문제\n');

  print('탈락 이유별:');
  beginnerFailReasons.forEach((reason, words) {
    print('  $reason: ${words.length}개');
  });

  // ── 중급 퀴즈 후보 풀 계산 ──
  print('');
  final intermediateCandidates = <String>[];
  for (final word in groupedByWord.keys) {
    final senses = groupedByWord[word]!.values.toList();
    final levels = wordLevels[word] ?? const <String>{};

    if (senses.length < 2) continue;
    if (!levels.contains('중급') && !levels.contains('초급')) continue;

    final withEnglish = senses.where((s) {
      final en = (s['definitionEn'] ?? '').trim();
      final lemma = (s['lemmaEn'] ?? '').trim();
      return en.isNotEmpty || lemma.isNotEmpty;
    }).toList();
    if (withEnglish.length < 2) continue;

    intermediateCandidates.add(word);
  }

  print('=== 중급 퀴즈 후보 단어 수: ${intermediateCandidates.length} ===');
  print('  → 30문제 세트로: ${intermediateCandidates.length ~/ 30}회 가능\n');

  // ── 초급 후보 중 예문이 있는 단어 ──
  int withGoodExample = 0;
  for (final word in beginnerCandidates) {
    final senses = groupedByWord[word]!.values.toList();
    final hasExample = senses.any((s) {
      final ex = (s['exampleKr'] ?? '').trim();
      return ex.isNotEmpty && ex.contains(word) && ex.length >= 10;
    });
    if (hasExample) withGoodExample++;
  }
  print('초급 후보 중 예문이 있는 단어: $withGoodExample개');
  print('초급 후보 중 예문이 없는 단어: ${beginnerCandidates.length - withGoodExample}개');
  print('');
  print('결론:');
  print('  30문제 × ${beginnerCandidates.length ~/ 30}회 = ${(beginnerCandidates.length ~/ 30) * 30}문제까지 완전 비중복 가능');
  print('  (실제 풀: $withGoodExample개, 예문 없는 건 폴백으로 처리)');
}
