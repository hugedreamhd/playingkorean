import 'dart:convert';
import 'dart:io';

void main() async {
  final assetsDir = Directory('assets');
  final jsonFiles = assetsDir.listSync().where((f) => f.path.endsWith('.json') && f.path.contains('1537907_')).toList();

  final Map<String, List<String>> meaningfulHomonyms = {};

  for (var fileEntity in jsonFiles) {
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

        if (senseType == '일반어' && pos == '명사') {
          if (word.length >= 1 && word.length <= 3 && !word.runes.any((c) => c >= 0xE000 && c <= 0xF8FF)) {
            meaningfulHomonyms.putIfAbsent(word, () => []).add(senseinfo?['definition'] ?? '');
          }
        }
      }
    } catch (e) {}
  }

  final finalWords = meaningfulHomonyms.keys.where((word) => meaningfulHomonyms[word]!.length >= 2).toList();
  finalWords.sort();

  print('\n--- Detailed Breakdown of 47,471 Homonyms ---');

  // 1. 뜻이 매우 많은 다의어 (고전적 상용어)
  final highSenseWords = finalWords.where((w) => meaningfulHomonyms[w]!.length >= 10).toList();
  print('\n[1] 상용 빈도가 매우 높은 다의어 (뜻 10개 이상: ${highSenseWords.length}개)');
  print(highSenseWords.take(15).join(', ') + ' 등...');

  // 2. 일상적인 2글자 명사 (가장 퀴즈에 적합)
  final twoCharWords = finalWords.where((w) => w.length == 2).toList();
  print('\n[2] 일상적인 2글자 동음이의어 (총 ${twoCharWords.length}개)');
  print(twoCharWords.skip(100).take(15).join(', ') + ' 등...');

  // 3. 한자어가 섞인 동음이의어 (조금 더 어려움)
  print('\n[3] 한자어 기반 동음이의어 예시');
  final hanjaLike = ['사고', '의사', '수도', '기록', '발행', '정지', '이동'];
  for(var h in hanjaLike) {
    if(meaningfulHomonyms.containsKey(h)) {
      print('- $h: ${meaningfulHomonyms[h]!.length}개 뜻 (예: 思考 vs 事故)');
    }
  }

  // 4. 아주 생소하지만 표준어인 경우
  print('\n[4] 표준어지만 생소할 수 있는 단어 (알파벳순 중간 지점 샘플)');
  print(finalWords.skip(finalWords.length ~/ 2).take(15).join(', ') + ' 등...');
}
