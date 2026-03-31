import 'dart:convert';
import 'dart:io';

void main() async {
  final assetsDir = Directory('assets');
  final jsonFiles = assetsDir.listSync().where((f) => f.path.endsWith('.json') && f.path.contains('1537907_')).toList();

  print('Found ${jsonFiles.length} dictionary files.');

  final Map<String, List<String>> meaningfulHomonyms = {};
  int standardNounCount = 0;

  for (var fileEntity in jsonFiles) {
    print('Analyzing ${fileEntity.path}...');
    try {
      final content = await File(fileEntity.path).readAsString(encoding: utf8);
      final dynamic data = json.decode(content);
      final List items = (data is Map && data['channel'] != null) ? (data['channel']['item'] ?? []) : [];

      for (var item in items) {
        final String wordRaw = item['wordinfo']?['word'] ?? '';
        final word = wordRaw.replaceAll('-', '').replaceAll('^', '');
        final senseinfo = item['senseinfo'];
        final senseType = senseinfo?['type'] ?? '';
        final pos = senseinfo?['pos'] ?? '';

        // 1. 일반어(Standard)이면서 명사(Noun)인 것만 필터링
        if (senseType == '일반어' && pos == '명사') {
          // 2. 글자 수 제한 (1~3자) 및 특수문자 제외
          if (word.length >= 1 && word.length <= 3 && !word.runes.any((c) => c >= 0xE000 && c <= 0xF8FF)) {
            standardNounCount++;
            meaningfulHomonyms.putIfAbsent(word, () => []).add(senseinfo?['definition'] ?? '');
          }
        }
      }
    } catch (e) {
      print('Error in ${fileEntity.path}: $e');
    }
  }

  // 필터링: 뜻이 2개 이상인 것만 (동음이의어)
  final finalWords = meaningfulHomonyms.keys.where((word) => meaningfulHomonyms[word]!.length >= 2).toList();
  finalWords.sort();

  print('\n--- Refined Analysis Result (Nouns Only) ---');
  print('Total Standard Nouns (1-3 chars): $standardNounCount');
  print('Unique Meaningful Homonyms (Nouns, 2+ senses): ${finalWords.length}');
  
  print('\nSome examples of Everyday Homonyms (Top 100):');
  for (var i = 0; i < (finalWords.length > 100 ? 100 : finalWords.length); i++) {
    stdout.write('${finalWords[i]} ');
    if ((i + 1) % 10 == 0) print('');
  }
  print('\n');
  
  // 구체적인 사례 확인 (유명한 단어들)
  final targetWords = ['밤', '눈', '말', '배', '다리', '벌', '감', '김', '차', '물'];
  print('\nSpecific Checks:');
  for (var tw in targetWords) {
    if (meaningfulHomonyms.containsKey(tw)) {
      print('- $tw: ${meaningfulHomonyms[tw]!.length} senses found');
    } else {
      print('- $tw: NOT FOUND as standard noun');
    }
  }
}
