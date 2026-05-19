// scripts/analyze_pool.dart
// 실행: dart run scripts/analyze_pool.dart
// (precomputed_homonyms.dart를 텍스트로 직접 파싱)

import 'dart:io';

void main() async {
  final file = File('lib/data/precomputed_homonyms.dart');
  final content = await file.readAsString();

  // 각 항목 파싱: {'id':..., 'word':..., 'level':..., 'homonymNo':..., ...}
  final entryPattern = RegExp(r"\{[^}]+\}");
  final matches = entryPattern.allMatches(content);

  // word -> {homonymNo -> {level, hasDefinitionEn, hasLemmaEn, hasExampleKr, definitionKr}}
  final data = <String, Map<int, Map<String, dynamic>>>{};

  for (final m in matches) {
    final entry = m.group(0)!;
    
    String? extract(String key) {
      final r = RegExp("'$key':'([^']*)'");
      return r.firstMatch(entry)?.group(1);
    }

    final word = extract('word');
    final level = extract('level');
    final homonymNoStr = extract('homonymNo');
    final definitionEn = extract('definitionEn') ?? '';
    final lemmaEn = extract('lemmaEn') ?? '';
    final exampleKr = extract('exampleKr') ?? '';
    final definitionKr = extract('definitionKr') ?? '';

    if (word == null || word.isEmpty) continue;
    final homonymNo = int.tryParse(homonymNoStr ?? '1') ?? 1;

    data.putIfAbsent(word, () => {});
    data[word]![homonymNo] = {
      'level': level ?? '',
      'hasEn': definitionEn.isNotEmpty || lemmaEn.isNotEmpty,
      'definitionEn': definitionEn,
      'lemmaEn': lemmaEn,
      'exampleKr': exampleKr,
      'definitionKr': definitionKr,
    };
  }

  print('=================================');
  print('전체 항목(sense) 수: ${matches.length}');
  print('고유 단어(표제어) 수: ${data.length}');
  print('=================================\n');

  // 레벨별 sense 수
  final levelCount = <String, int>{};
  for (final senses in data.values) {
    for (final s in senses.values) {
      final lv = s['level'] as String;
      levelCount[lv] = (levelCount[lv] ?? 0) + 1;
    }
  }
  print('레벨별 sense 수:');
  final sorted = levelCount.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
  for (final e in sorted) {
    print('  ${e.key.isEmpty ? "(없음)" : e.key}: ${e.value}개');
  }
  print('');

  // 하드 차단 키워드
  final hardBlocked = ['열녀문', '정려', '정문', '홍문', '유교 경전', '사서', '오경', '십간', '십이지'];

  bool isHardBlocked(Map<String, dynamic> s) {
    final defKr = s['definitionKr'] as String;
    return hardBlocked.any((k) => defKr.contains(k));
  }

  // ── 초급 후보 풀 계산 ──
  final beginnerCandidates = <String>[];
  int failedSingle = 0;
  int failedNoBeginnerLevel = 0;
  int failedHardBlock = 0;
  int failedNoEnglish = 0;

  for (final word in data.keys) {
    final senses = data[word]!;
    
    if (senses.length < 2) { failedSingle++; continue; }

    final levels = senses.values.map((s) => s['level'] as String).toSet();
    if (!levels.contains('초급') && !levels.contains('중급')) {
      failedNoBeginnerLevel++;
      continue;
    }

    final usable = senses.values.where((s) => !isHardBlocked(s)).toList();
    if (usable.length < 2) { failedHardBlock++; continue; }

    final withEn = usable.where((s) => s['hasEn'] == true).toList();
    if (withEn.length < 2) { failedNoEnglish++; continue; }

    beginnerCandidates.add(word);
  }

  print('=================================');
  print('초급 퀴즈 후보 단어 수: ${beginnerCandidates.length}개');
  print('  → 30문제 × ${beginnerCandidates.length ~/ 30}회 완전 비중복 가능');
  print('  → 겹치지 않는 최대 문제 수: ${beginnerCandidates.length}문제');
  print('=================================');
  print('탈락 이유:');
  print('  동음이의어 1개뿐: $failedSingle개');
  print('  초급/중급 레벨 없음: $failedNoBeginnerLevel개');
  print('  하드차단 후 usable < 2: $failedHardBlock개');
  print('  영어뜻 있는 sense < 2: $failedNoEnglish개');
  print('');

  // 예문 품질 분석
  int withGoodExample = 0;
  int withAnyExample = 0;
  for (final word in beginnerCandidates) {
    final senses = data[word]!;
    final hasAny = senses.values.any((s) {
      final ex = s['exampleKr'] as String;
      return ex.isNotEmpty && ex.contains(word);
    });
    final hasGood = senses.values.any((s) {
      final ex = s['exampleKr'] as String;
      return ex.isNotEmpty && ex.contains(word) && ex.length >= 10 && ex.length <= 56;
    });
    if (hasAny) withAnyExample++;
    if (hasGood) withGoodExample++;
  }

  print('초급 후보 예문 품질:');
  print('  예문 있음 (길이무관): $withAnyExample개');
  print('  예문 좋음 (10~56자): $withGoodExample개');
  print('  예문 없음: ${beginnerCandidates.length - withAnyExample}개');
  print('');

  // ── 중급 후보 풀 계산 ──
  final intermediateCandidates = <String>[];
  for (final word in data.keys) {
    final senses = data[word]!;
    if (senses.length < 2) continue;

    final levels = senses.values.map((s) => s['level'] as String).toSet();
    if (!levels.contains('중급') && !levels.contains('초급')) continue;

    final withEn = senses.values.where((s) => s['hasEn'] == true).toList();
    if (withEn.length < 2) continue;

    intermediateCandidates.add(word);
  }

  print('=================================');
  print('중급 퀴즈 후보 단어 수: ${intermediateCandidates.length}개');
  print('  → 30문제 × ${intermediateCandidates.length ~/ 30}회 완전 비중복 가능');
  print('=================================');
}
