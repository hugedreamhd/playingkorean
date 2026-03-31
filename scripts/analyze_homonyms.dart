import 'dart:convert';
import 'dart:io';

void main() async {
  final assetsDir = Directory('assets');
  final jsonFiles = assetsDir.listSync().where((f) => f.path.endsWith('.json') && f.path.contains('1537907_')).toList();

  print('Found ${jsonFiles.length} dictionary files.');

  final Map<String, List<String>> meaningfulHomonyms = {};
  int dialectCount = 0;
  int archaicCount = 0;
  int standardCount = 0;

  for (var fileEntity in jsonFiles) {
    print('Analyzing ${fileEntity.path}...');
    try {
      final content = await File(fileEntity.path).readAsString(encoding: utf8);
      final dynamic data = json.decode(content);
      final List items = (data is Map && data['channel'] != null) ? (data['channel']['item'] ?? []) : [];

      for (var item in items) {
        final String wordRaw = item['wordinfo']?['word'] ?? '';
        final word = wordRaw.replaceAll('-', '').replaceAll('^', '');
        final senseType = item['senseinfo']?['type'] ?? '';

        if (senseType == '방언') {
          dialectCount++;
          continue;
        }
        if (senseType == '옛말' || senseType == '옛말_방언') {
          archaicCount++;
          continue;
        }

        if (senseType == '일반어' || senseType == '전문어') {
          standardCount++;
          if (word.length >= 1 && word.length <= 3) {
            meaningfulHomonyms.putIfAbsent(word, () => []).add(item['senseinfo']?['definition'] ?? '');
          }
        }
      }
    } catch (e) {
      print('Error in ${fileEntity.path}: $e');
    }
  }

  // 필터링: 뜻이 2개 이상인 것만
  final finalWords = meaningfulHomonyms.keys.where((word) => meaningfulHomonyms[word]!.length >= 2).toList();
  finalWords.sort();

  print('\n--- Analysis Result ---');
  print('Total items processed (approx): ${standardCount + dialectCount + archaicCount}');
  print('Standard words (일반어/전문어): $standardCount');
  print('Dialects (방언): $dialectCount');
  print('Archaic (옛말): $archaicCount');
  print('Unique meaningful homonyms (Standard, 2+ senses, length 1-3): ${finalWords.length}');
  
  print('\nSome examples of meaningful homonyms (Top 50):');
  for (var i = 0; i < (finalWords.length > 50 ? 50 : finalWords.length); i++) {
    stdout.write('${finalWords[i]} ');
    if ((i + 1) % 10 == 0) print('');
  }
  print('\n');
}
