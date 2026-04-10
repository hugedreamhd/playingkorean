import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:playingkorean/core/data/database_helper.dart';

class VocabularySeeder {
  static const List<String> jsonFiles = [
    'assets/data/1_5000_20260319.json',
    'assets/data/2_5000_20260319.json',
    'assets/data/3_5000_20260319.json',
    'assets/data/4_5000_20260319.json',
    'assets/data/5_5000_20260319.json',
    'assets/data/6_5000_20260319.json',
    'assets/data/7_5000_20260319.json',
    'assets/data/8_5000_20260319.json',
    'assets/data/9_5000_20260319.json',
    'assets/data/10_5000_20260319.json',
    'assets/data/11_3439_20260319.json',
  ];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const int _defaultMaxEntriesPerFile = 600; // 파일당 파싱 상한
  static const int _defaultMaxTotalItems = 6000; // 다양성 확보용 상한

  static String _readWrittenForm(dynamic lemmaNode) {
    // Lemma: { feat: { att: writtenForm, val: "가" } }
    // 또는 feat가 List인 케이스도 대비
    if (lemmaNode is Map) {
      final feat = lemmaNode['feat'];
      if (feat is Map) return (feat['val'] ?? '').toString();
      if (feat is List) {
        final wf = feat.cast<dynamic>().firstWhere(
          (f) => f is Map && f['att'] == 'writtenForm',
          orElse: () => const <String, dynamic>{},
        );
        if (wf is Map) return (wf['val'] ?? '').toString();
      }
    }
    return '';
  }

  static Iterable<dynamic> _asList(dynamic v) sync* {
    if (v == null) return;
    if (v is List) {
      yield* v;
    } else {
      yield v;
    }
  }

  static List<Map<String, dynamic>> _asFeatList(dynamic feat) {
    // feat: List<Map> 또는 Map 하나일 수 있음
    final out = <Map<String, dynamic>>[];
    if (feat is List) {
      for (final f in feat) {
        if (f is Map<String, dynamic>) out.add(f);
        if (f is Map) out.add(Map<String, dynamic>.from(f));
      }
    } else if (feat is Map) {
      out.add(Map<String, dynamic>.from(feat));
    }
    return out;
  }

  static String _featVal(List<Map<String, dynamic>> feats, String att) {
    for (final f in feats) {
      if (f['att'] == att) return (f['val'] ?? '').toString();
    }
    return '';
  }

  static Map<String, String> _extractEnglishEquivalent(dynamic equivalentsNode) {
    // Equivalent: List of { feat: [ {att: language,val: 영어}, {att: lemma,...}, {att: definition,...} ] }
    for (final eq in _asList(equivalentsNode)) {
      if (eq is! Map) continue;
      final feats = _asFeatList(eq['feat']);
      final lang = _featVal(feats, 'language');
      if (lang != '영어') continue;
      return {
        'lemma': _featVal(feats, 'lemma'),
        'definition': _featVal(feats, 'definition'),
      };
    }
    return {'lemma': '', 'definition': ''};
  }

  static String _extractFirstExample(dynamic senseExampleNode) {
    // SenseExample: List or Map. 내부에 feat(List)로 example att를 가짐
    for (final ex in _asList(senseExampleNode)) {
      if (ex is! Map) continue;
      final feats = _asFeatList(ex['feat']);
      final example = _featVal(feats, 'example');
      if (example.isNotEmpty) return example;
    }
    return '';
  }

  static List<VocabularyModel> _extractVocabularyModelsStreaming(
    String jsonString, {
    required int maxModels,
  }) {
    // LexicalEntry 배열을 처음부터 끝까지 훑되,
    // "초급/중급 명사" 조건을 만족하는 모델이 maxModels개 모이면 즉시 중단한다.
    final keyIdx = jsonString.indexOf('"LexicalEntry"');
    if (keyIdx < 0) return const [];
    final arrStart = jsonString.indexOf('[', keyIdx);
    if (arrStart < 0) return const [];

    final List<VocabularyModel> out = [];

    int i = arrStart + 1;
    int depth = 0;
    bool inString = false;
    bool escape = false;
    int objStart = -1;

    while (i < jsonString.length && out.length < maxModels) {
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
            final level = _featVal(feats, 'vocabularyLevel');
            final pos = _featVal(feats, 'partOfSpeech');
            final hn = _featVal(feats, 'homonym_number');
            int homonymNo = 1;
            if (hn.isNotEmpty) homonymNo = int.tryParse(hn) ?? 1;

            // 조건: 명사만 추출
            // NOTE: 초급/중급만 고르면 파일 앞부분이 대부분 고급이라 "0개 삽입"이 자주 발생한다.
            // 먼저 명사 전체를 빠르게 시딩하고, 퀴즈 생성 단계에서 레벨을 선택/필터링한다.
            if (pos != '명사') {
              i++;
              continue;
            }

            for (final sense in _asList(entry['Sense'])) {
              if (sense is! Map) continue;

              final senseFeats = _asFeatList(sense['feat']);
              final defKr = _featVal(senseFeats, 'definition');
              final en = _extractEnglishEquivalent(sense['Equivalent']);
              final lemmaEn = en['lemma'] ?? '';
              final defEn = en['definition'] ?? '';
              final example = _extractFirstExample(sense['SenseExample']);

              out.add(
                VocabularyModel(
                  id: 'kr_${lemma}_${homonymNo}_${defKr.hashCode}',
                  word: lemma,
                  level: level,
                  pos: pos,
                  homonymNo: homonymNo,
                  definitionKr: defKr,
                  definitionEn: defEn,
                  lemmaEn: lemmaEn,
                  exampleKr: example,
                ),
              );

              if (out.length >= maxModels) break;
            }
          } catch (_) {
            // ignore per-entry parse error
          }
        }
      } else if (c == 0x5D && depth == 0) {
        // end of LexicalEntry array (객체 바깥 레벨에서만 종료)
        break;
      }

      i++;
    }

    return out;
  }

  /// JSON 파일을 순회하며 초급/중급 명사 데이터만 추출하여 DB에 저장
  /// - 테스트 단계에서는 OOM/무한로딩 방지를 위해 일부만 시딩한다.
  Future<void> seed({
    List<String>? files,
    int maxEntriesPerFile = _defaultMaxEntriesPerFile,
    int maxTotalItems = _defaultMaxTotalItems,
  }) async {
    final targetFiles = files ?? jsonFiles;
    print('Starting database seeding from ${targetFiles.length} JSON files...');

    int insertedTotal = 0;

    for (String filePath in targetFiles) {
      try {
        print('Processing $filePath...');
        // NOTE: rootBundle.loadString + json.decode 전체 트리 생성은 OOM이 발생할 수 있음.
        // 우선은 파일당 일부 LexicalEntry만 경량 추출하여 시딩한다.
        final String jsonString = await rootBundle.loadString(filePath);

        // 메모리 효율을 위해 Isolate 사용
        final List<VocabularyModel> items = await Isolate.run(() {
          final remaining = maxTotalItems - insertedTotal;
          final perFileCap = remaining > 0 ? remaining : 0;
          final cap = perFileCap < maxEntriesPerFile ? perFileCap : maxEntriesPerFile;
          return _extractVocabularyModelsStreaming(jsonString, maxModels: cap);
        });

        if (items.isNotEmpty) {
          await _dbHelper.insertVocabularies(items);
          insertedTotal += items.length;
          print('Inserted ${items.length} items from $filePath (total: $insertedTotal)');
          if (insertedTotal >= maxTotalItems) {
            print('Reached maxTotalItems=$maxTotalItems. Stopping early.');
            break;
          }
        }
      } catch (e) {
        print('Error processing $filePath: $e');
      }
    }
    print('Database seeding completed successfully!');
  }
}
