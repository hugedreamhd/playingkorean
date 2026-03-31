import 'dart:convert';
import 'dart:io';

// 간단한 한국어 로마자 변환기 (국어국립원 표준 방식 약식 구현)
String romanize(String hangul) {
  final initialDecomp = [
    'g', 'kk', 'n', 'd', 'tt', 'r', 'm', 'b', 'pp', 's', 'ss', '', 'j', 'jj', 'ch', 'k', 't', 'p', 'h'
  ];
  final vowelDecomp = [
    'a', 'ae', 'ya', 'yae', 'eo', 'e', 'ye', 'ye', 'o', 'wa', 'wae', 'oe', 'yo', 'u', 'wo', 'we', 'wi', 'yu', 'eu', 'ui', 'i'
  ];
  final finalDecomp = [
    '', 'k', 'kk', 'ks', 'n', 'nj', 'nh', 'd', 'l', 'lg', 'lm', 'lb', 'ls', 'lt', 'lp', 'lh', 'm', 'p', 'ps', 's', 'ss', 'ng', 'j', 'ch', 'k', 't', 'p', 'h'
  ];

  String result = '';
  for (int i = 0; i < hangul.length; i++) {
    int charCode = hangul.codeUnitAt(i);
    if (charCode >= 0xAC00 && charCode <= 0xD7AF) {
      int base = charCode - 0xAC00;
      int initialIdx = base ~/ (21 * 28);
      int vowelIdx = (base % (21 * 28)) ~/ 28;
      int finalIdx = base % 28;

      result += initialDecomp[initialIdx];
      result += vowelDecomp[vowelIdx];
      result += finalDecomp[finalIdx];
    } else {
      result += hangul[i];
    }
  }
  return result;
}

void main() async {
  final assetsDir = Directory('assets');
  final jsonFiles = assetsDir.listSync().where((f) => f.path.endsWith('.json') && f.path.contains('1537907_')).toList();
  final outputPath = 'assets/data/quizzes.json';

  print('Found ${jsonFiles.length} dictionary files.');
  Directory('assets/data').createSync(recursive: true);

  final Map<String, List<Map<String, dynamic>>> wordGroups = {};

  for (var fileEntity in jsonFiles) {
    print('Processing ${fileEntity.path}...');
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

        // 일반 명사이면서 1~3자 단어만 추출
        if (senseType == '일반어' && pos == '명사' && word.length >= 1 && word.length <= 3) {
          if (!word.runes.any((c) => c >= 0xE000 && c <= 0xF8FF)) {
            wordGroups.putIfAbsent(word, () => []).add(item);
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  final List<Map<String, dynamic>> finalQuizzes = [];
  final homonyms = wordGroups.keys.where((w) => wordGroups[w]!.length >= 2).toList();

  for (var word in homonyms) {
    final List<Map<String, dynamic>> senses = wordGroups[word]!;
    
    // 수준(Level) 판별 로직
    String level = '4';
    int senseCount = senses.length;
    if (word.length <= 2 && senseCount >= 12) level = '1';
    else if (word.length <= 2 && senseCount >= 6) level = '2';
    else if (word.length <= 3 && senseCount >= 2) level = '3';

    // 각 뜻에 대해 퀴즈 생성
    for (int i = 0; i < senses.length; i++) {
       final sense = senses[i];
       final senseInfo = sense['senseinfo'];
       final definition = senseInfo?['definition'] ?? '';
       
       // 예문 찾기
       final exampleInfo = senseInfo?['example_info'];
       String sentence = '문장이 없습니다.';
       if (exampleInfo != null && exampleInfo is List && exampleInfo.isNotEmpty) {
         final rawEx = exampleInfo[0]['example'] ?? '';
         sentence = rawEx.replaceAll(word, '(      )'); // 빈칸 처리
       } else {
         continue; // 예문 없는 것은 퀴즈에서 제외 (학습 효과를 위해)
       }

       // 보기 구성 (정답 단어 1개 + 다른 단어 3개)
       // 사실 동음이의어 퀴즈라면 '단어는 같은데 뜻이 다른 것' 중에서 고르는 것이 아니라,
       // '문맥에 맞는 단어'를 고르는 것이므로 오답은 무작위 상용어로 배정
       List<String> options = [word, '사과', '나무', '하늘']; // 실제로는 무작위 추출 권장
       
       final quiz = {
         'id': '${word}_${i}_${DateTime.now().microsecondsSinceEpoch}',
         'imageUrl': 'https://images.unsplash.com/photo-1516321497487-e288fb19713f',
         'contextText': sentence, // 문맥 예문
         'options': options,
         'romaji': options.map((o) => romanize(o)).toList(),
         'englishMeanings': List.filled(4, ''), // 추후 번역 엔진 연동 영역
         'optionImages': List.filled(4, 'https://images.unsplash.com/photo-1516321497487-e288fb19713f'),
         'explanations': options.map((o) => o == word ? definition : '해당 문맥에 맞지 않는 단어입니다.').toList(),
         'exampleSentences': List.filled(4, ''),
         'difficulty': level,
         'answerIndex': 0, // 항상 첫번째가 정답 (UI에서 셔플링 필요)
       };
       finalQuizzes.add(quiz);
    }
  }

  print('Generated ${finalQuizzes.length} quizzes.');
  final outJson = json.encode(finalQuizzes);
  await File(outputPath).writeAsString(outJson);
  print('Saved to $outputPath');
}
