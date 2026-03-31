import 'dart:convert';
import 'dart:io';

void main() async {
  final assetsDir = Directory('assets');
  final jsonFiles = assetsDir.listSync().where((f) => f.path.endsWith('.json') && f.path.contains('1537907_')).toList();
  final outputPath = 'assets/data/quizzes.json';

  print('Found ${jsonFiles.length} dictionary files.');
  Directory('assets/data').createSync(recursive: true);

  final imageMap = {
    '배': ['https://images.unsplash.com/photo-1615484477778-93660394222a', 'https://images.unsplash.com/photo-1544257750-572358f5da22', 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b'],
    '말': ['https://images.unsplash.com/photo-1553284965-83fd3e82fa5a', 'https://images.unsplash.com/photo-1557804506-669a67965ba0'],
    '눈': ['https://images.unsplash.com/photo-1542601039-4632f051523a', 'https://images.unsplash.com/photo-1558470598-a5dda9640f68'],
    '다리': ['https://images.unsplash.com/photo-1449034446853-66c86144b0ad', 'https://images.unsplash.com/photo-1525596662741-e94ff9f26de1'],
    '밤': ['https://images.unsplash.com/photo-1472552947727-b59aa9df4427', 'https://images.unsplash.com/photo-1509339022327-1e1e25360a41'],
    '벌': ['https://images.unsplash.com/photo-1587334274328-64186a80aeee', 'https://images.unsplash.com/photo-1591047139829-d91aec16adbb'],
    '감': ['https://images.unsplash.com/photo-1635345750275-c7e63b6528d2', 'https://images.unsplash.com/photo-1499209974431-9dac3adaf471'],
    '김': ['https://images.unsplash.com/photo-1542314831-068cd1dbfeeb', 'https://images.unsplash.com/photo-1516733725897-1aa73b87c8e8'],
    '차': ['https://images.unsplash.com/photo-1511125358155-082081512465', 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c'],
    '물': ['https://images.unsplash.com/photo-1548810930-e6bb51245310', 'https://images.unsplash.com/photo-1516782293442-f2fcc616e094'],
  };

  const defaultImage = 'https://images.unsplash.com/photo-1516321497487-e288fb19713f';

  String getDifficulty(String word) {
    if (['배', '말', '눈', '차', '물', '소', '개', '해', '달'].contains(word)) return 'Beginner';
    if (['다리', '밤', '벌', '감', '김', '풀', '병', '장', '전'].contains(word)) return 'Intermediate';
    return 'Advanced';
  }

  final List<Map<String, dynamic>> finalQuizzes = [];
  final Map<String, List> wordGroups = {};

  for (var fileEntity in jsonFiles) {
    if (finalQuizzes.length >= 100) break;

    print('Processing ${fileEntity.path}...');
    try {
      final content = await File(fileEntity.path).readAsString(encoding: utf8);
      final dynamic data = json.decode(content);
      final List items = (data is Map && data['channel'] != null) ? (data['channel']['item'] ?? []) : [];

      for (var item in items) {
        final String wordRaw = item['wordinfo']?['word'] ?? '';
        final word = wordRaw.replaceAll('-', '').replaceAll('^', '');

        if (word.runes.any((c) => c >= 0xE000 && c <= 0xF8FF)) continue;
        if (item['senseinfo']?['type'] == '옛말') continue;
        if (word.length < 1 || word.length > 3) continue; // 짧은 단어 위주 (동음이의어 많음)

        wordGroups.putIfAbsent(word, () => []).add(item);
      }

      final keys = wordGroups.keys.toList();
      for (var word in keys) {
        final List senses = wordGroups[word]!;
        if (senses.length >= 2) {
          final validSenses = senses.take(4).toList();
          final List<String> options = List<String>.from(List.filled(validSenses.length, word, growable: true));
          if (options.length < 4) {
             options.addAll(['사과', '포도', '오렌지', '딸기'].take(4 - options.length));
          }

          final images = imageMap[word] ?? List.filled(4, defaultImage);

          for (var i = 0; i < validSenses.length; i++) {
            final targetSense = validSenses[i];
            final quiz = {
              'id': '${word}_${i}_${DateTime.now().millisecondsSinceEpoch}',
              'imageUrl': i < images.length ? images[i] : defaultImage,
              'contextText': targetSense['senseinfo']?['definition'] ?? '',
              'options': options,
              'romaji': List.filled(4, ''),
              'englishMeanings': List.filled(4, ''),
              'optionImages': List.generate(4, (j) => j < images.length ? images[j] : defaultImage),
              'explanations': List.generate(4, (j) {
                if (j < validSenses.length) return validSenses[j]['senseinfo']?['definition'] ?? '';
                return '무관한 오답입니다.';
              }),
              'exampleSentences': List.generate(4, (j) {
                if (j < validSenses.length) {
                  final ex = validSenses[j]['senseinfo']?['example_info'];
                  if (ex != null && ex is List && ex.isNotEmpty) return ex[0]['example'] ?? '예문이 없습니다.';
                }
                return '예문이 없습니다.';
              }),
              'difficulty': getDifficulty(word),
              'answerIndex': i,
            };
            finalQuizzes.add(quiz);
          }
          wordGroups.remove(word);
        }
      }
    } catch (e) {
      print('Error in ${fileEntity.path}: $e');
    }
  }

  print('Total quizzes generated: ${finalQuizzes.length}');
  final outJson = json.encode(finalQuizzes.take(100).toList());
  await File(outputPath).writeAsString(outJson);
  print('Saved to $outputPath');
}
