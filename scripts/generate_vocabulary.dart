// ============================================================
// 사전 데이터 사전 생성 스크립트
// ============================================================
// 실행 방법 (playingkorean/ 디렉터리에서):
//   dart run scripts/generate_vocabulary.dart
//
// 출력: lib/data/precomputed_homonyms.dart
// - 11개 사전 JSON 파일 전체를 스캔
// - 동음이의어 쌍(homonym_number가 2개 이상)인 명사만 추출
// - 앱이 이 파일을 컴파일 타임 상수로 읽으므로 런타임 스캔 불필요
// ============================================================

import 'dart:convert';
import 'dart:io';

// --------------- 데이터 구조 ---------------

class VocabEntry {
  final String id;
  final String word;
  final String level;
  final int homonymNo;
  final String definitionKr;
  final String definitionEn;
  final String lemmaEn;
  final String exampleKr;

  VocabEntry({
    required this.id,
    required this.word,
    required this.level,
    required this.homonymNo,
    required this.definitionKr,
    required this.definitionEn,
    required this.lemmaEn,
    required this.exampleKr,
  });
}

// --------------- JSON 파싱 유틸 ---------------

String _readWrittenForm(dynamic lemmaNode) {
  if (lemmaNode is Map) {
    final feat = lemmaNode['feat'];
    if (feat is Map) return (feat['val'] ?? '').toString();
    if (feat is List) {
      for (final f in feat) {
        if (f is Map && f['att'] == 'writtenForm') {
          return (f['val'] ?? '').toString();
        }
      }
    }
  }
  return '';
}

Iterable<dynamic> _asList(dynamic v) sync* {
  if (v == null) return;
  if (v is List) {
    yield* v;
  } else {
    yield v;
  }
}

List<Map<String, dynamic>> _asFeatList(dynamic feat) {
  final out = <Map<String, dynamic>>[];
  if (feat is List) {
    for (final f in feat) {
      if (f is Map) out.add(Map<String, dynamic>.from(f));
    }
  } else if (feat is Map) {
    out.add(Map<String, dynamic>.from(feat));
  }
  return out;
}

String _featVal(List<Map<String, dynamic>> feats, String att) {
  for (final f in feats) {
    if (f['att'] == att) return (f['val'] ?? '').toString();
  }
  return '';
}

Map<String, String> _extractEnglish(dynamic equivalentsNode) {
  for (final eq in _asList(equivalentsNode)) {
    if (eq is! Map) continue;
    final feats = _asFeatList(eq['feat']);
    if (_featVal(feats, 'language') != '영어') continue;
    return {
      'lemma': _featVal(feats, 'lemma'),
      'definition': _featVal(feats, 'definition'),
    };
  }
  return {'lemma': '', 'definition': ''};
}

String _extractFirstExample(dynamic senseExampleNode) {
  for (final ex in _asList(senseExampleNode)) {
    if (ex is! Map) continue;
    final feats = _asFeatList(ex['feat']);
    final example = _featVal(feats, 'example');
    if (example.isNotEmpty) return example;
  }
  return '';
}

// 레벨 텍스트 정제 및 영문 변환 방지 (유저 요청: '초급', '중급', '고급' 정제 지원)
String _cleanLevel(String level) {
  final l = level.trim();
  if (l == '초급' || l == '초' || l.toLowerCase().contains('begin')) {
    return '초급';
  }
  if (l == '중급' || l == '중' || l.toLowerCase().contains('intermed')) {
    return '중급';
  }
  if (l == '고급' || l == '고' || l.toLowerCase().contains('advanc')) {
    return '고급';
  }
  return l.isNotEmpty ? l : '초급'; // 기본값은 초급으로 안정적 설정
}

// --------------- 핵심 추출 로직 ---------------
// vocabulary_seeder.dart의 스트리밍 파서와 동일한 방식으로 동작하되,
// 파일 전체를 스캔해 단어별 최적 항목(예문+영어 정의)을 모은다.

Map<String, Map<int, VocabEntry>> _extractFromFile(String jsonString) {
  final keyIdx = jsonString.indexOf('"LexicalEntry"');
  if (keyIdx < 0) return {};
  final arrStart = jsonString.indexOf('[', keyIdx);
  if (arrStart < 0) return {};

  final Map<String, Map<int, VocabEntry>> wordMap = {};

  int i = arrStart + 1;
  int depth = 0;
  bool inString = false;
  bool escape = false;
  int objStart = -1;

  while (i < jsonString.length) {
    final c = jsonString.codeUnitAt(i);

    if (inString) {
      if (escape) {
        escape = false;
      } else if (c == 0x5C) {
        escape = true;
      } else if (c == 0x22) {
        inString = false;
      }
      i++;
      continue;
    }

    if (c == 0x22) {
      inString = true;
      i++;
      continue;
    }

    if (c == 0x7B) {
      if (depth == 0) objStart = i;
      depth++;
    } else if (c == 0x7D) {
      depth--;
      if (depth == 0 && objStart >= 0) {
        final objStr = jsonString.substring(objStart, i + 1);
        objStart = -1;

        try {
          final decoded = json.decode(objStr);
          if (decoded is! Map) {
            i++;
            continue;
          }
          final entry = Map<String, dynamic>.from(decoded);

          final lemma = _readWrittenForm(entry['Lemma']);
          if (lemma.isEmpty) {
            i++;
            continue;
          }

          final feats = _asFeatList(entry['feat']);
          final rawLevel = _featVal(feats, 'vocabularyLevel');
          final level = _cleanLevel(rawLevel);
          final pos = _featVal(feats, 'partOfSpeech');
          final hn = _featVal(feats, 'homonym_number');
          final homonymNo = int.tryParse(hn.isNotEmpty ? hn : '1') ?? 1;

          if (pos != '명사') {
            i++;
            continue;
          }

          // LexicalEntry의 여러 Sense 중 "예문이 있고 영어 정의가 풍부한" 최적 항목 선택
          VocabEntry? best;
          int bestScore = -1;

          for (final sense in _asList(entry['Sense'])) {
            if (sense is! Map) continue;
            final senseFeats = _asFeatList(sense['feat']);
            final defKr = _featVal(senseFeats, 'definition');
            final en = _extractEnglish(sense['Equivalent']);
            final example = _extractFirstExample(sense['SenseExample']);

            final score =
                (example.isNotEmpty ? 4 : 0) +
                (en['definition']!.isNotEmpty ? 2 : 0) +
                (en['lemma']!.isNotEmpty ? 1 : 0);

            if (score > bestScore) {
              bestScore = score;
              best = VocabEntry(
                id: 'kr_${lemma}_${homonymNo}_${defKr.hashCode}',
                word: lemma,
                level: level,
                homonymNo: homonymNo,
                definitionKr: defKr,
                definitionEn: en['definition'] ?? '',
                lemmaEn: en['lemma'] ?? '',
                exampleKr: example,
              );
            }
          }

          if (best != null) {
            // 예문이 더 풍부한 항목으로 교체
            final existing = wordMap[lemma]?[homonymNo];
            if (existing == null || bestScore > -1) {
              wordMap.putIfAbsent(lemma, () => {})[homonymNo] = best;
            }
          }
        } catch (_) {
          // 파싱 오류 무시
        }
      }
    } else if (c == 0x5D && depth == 0) {
      break;
    }

    i++;
  }

  return wordMap;
}

// --------------- 품질 필터 ---------------

bool _isUsableExample(String example, String word) {
  if (example.isEmpty || !example.contains(word)) return false;
  if (example.length < 8) return false;
  final tokens = example
      .split(RegExp(r'\s+'))
      .where((t) => t.trim().isNotEmpty)
      .length;
  if (tokens < 3) return false;
  // 사전식 정의문 제거
  const blocked = ['을 이르는 말', '를 이르는 말', '의 뜻', '비유적으로', '속담', '품사', '되다.'];
  for (final b in blocked) {
    if (example.contains(b)) return false;
  }
  return true;
}

// --------------- 문자열 이스케이프 ---------------

String _esc(String s) {
  return s
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\r', '')
      .replaceAll('\n', '\\n')
      .replaceAll('\$', '\\\$');
}

// --------------- main ---------------

void main() async {
  const dataDir = 'assets/data';
  const outputPath = 'lib/data/precomputed_homonyms.dart';

  const fileNames = [
    '1_5000_20260319.json',
    '2_5000_20260319.json',
    '3_5000_20260319.json',
    '4_5000_20260319.json',
    '5_5000_20260319.json',
    '6_5000_20260319.json',
    '7_5000_20260319.json',
    '8_5000_20260319.json',
    '9_5000_20260319.json',
    '10_5000_20260319.json',
    '11_3439_20260319.json',
  ];

  // 11개 파일을 모두 처리해 단어별 homonym 맵 누적
  final Map<String, Map<int, VocabEntry>> globalWordMap = {};
  int totalEntries = 0;

  for (final fileName in fileNames) {
    final filePath = '$dataDir/$fileName';
    final file = File(filePath);
    if (!await file.exists()) {
      print('파일 없음, 건너뜀: $filePath');
      continue;
    }

    stdout.write('처리 중: $fileName ... ');
    stdout.flush();

    // 중요: 인코딩을 UTF-8로 명시하여 Windows 시스템 기본 인코딩(CP949) 무시
    final content = await file.readAsString(encoding: utf8);
    final fileMap = _extractFromFile(content);

    int added = 0;
    for (final entry in fileMap.entries) {
      final word = entry.key;
      final homoMap = entry.value;
      for (final kv in homoMap.entries) {
        // 이미 있는 항목보다 예문이 더 풍부하면 교체
        final existing = globalWordMap[word]?[kv.key];
        final candidate = kv.value;
        if (existing == null ||
            (candidate.exampleKr.isNotEmpty && existing.exampleKr.isEmpty)) {
          globalWordMap.putIfAbsent(word, () => {})[kv.key] = candidate;
          added++;
        }
      }
    }
    totalEntries += added;
    print('완료 (명사 항목 +$added, 누적 $totalEntries)');
  }

  // 동음이의어 쌍(homonymNo 2개 이상)만 필터링 + 품질 검증
  final List<VocabEntry> pairs = [];
  int skippedNoExample = 0;

  for (final homoMap in globalWordMap.values) {
    if (homoMap.length < 2) continue; // 동음이의어 아님

    // 2개 이상 유효한 homonym이 있어야 문제로 출제 가능
    final validEntries = homoMap.values
        .where((e) => e.exampleKr.isNotEmpty || e.definitionEn.isNotEmpty)
        .toList();
    if (validEntries.length < 2) {
      skippedNoExample++;
      continue;
    }

    pairs.addAll(homoMap.values);
  }

  // 정렬: 단어 → homonymNo
  pairs.sort((a, b) {
    final w = a.word.compareTo(b.word);
    return w != 0 ? w : a.homonymNo.compareTo(b.homonymNo);
  });

  print('');
  print('=== 결과 ===');
  print('동음이의어 쌍 총 항목 수 : ${pairs.length}');
  print('예문 없어 제외된 단어   : $skippedNoExample');

  // 레벨별 통계
  final levels = <String, int>{};
  for (final e in pairs) {
    levels[e.level.isEmpty ? '(없음)' : e.level] =
        (levels[e.level.isEmpty ? '(없음)' : e.level] ?? 0) + 1;
  }
  levels.forEach((k, v) => print('  $k: $v항목'));

  // Dart 파일 생성
  final buf = StringBuffer();
  buf.writeln('// GENERATED FILE — DO NOT EDIT MANUALLY.');
  buf.writeln('// Regenerate by running (from playingkorean/ directory):');
  buf.writeln('//   dart run scripts/generate_vocabulary.dart');
  buf.writeln('//');
  buf.writeln('// Generated : ${DateTime.now().toIso8601String()}');
  buf.writeln('// Total entries : ${pairs.length}');
  buf.writeln('');
  buf.writeln('// ignore_for_file: lines_longer_than_80_chars');
  buf.writeln('');
  buf.writeln('/// 사전에서 사전 추출된 동음이의어 쌍 데이터. 런타임 JSON 스캔 없이 즉시 사용 가능.');
  buf.writeln('const List<Map<String, String>> kPrecomputedHomonyms = [');

  for (final e in pairs) {
    buf.write("  {'id':'${_esc(e.id)}'");
    buf.write(",'word':'${_esc(e.word)}'");
    buf.write(",'level':'${_esc(e.level)}'");
    buf.write(",'homonymNo':'${e.homonymNo}'");
    buf.write(",'definitionKr':'${_esc(e.definitionKr)}'");
    buf.write(",'definitionEn':'${_esc(e.definitionEn)}'");
    buf.write(",'lemmaEn':'${_esc(e.lemmaEn)}'");
    buf.writeln(",'exampleKr':'${_esc(e.exampleKr)}'},");
  }

  buf.writeln('];');

  // 중복 코드를 걷어내고, 최종 쓰기 인코딩 강제 고정!!
  await File(outputPath).writeAsString(buf.toString(), encoding: utf8);
  print('');
  print('✓ 출력 파일: $outputPath');
  print('  (앱 재빌드 후 적용됩니다)');
}
