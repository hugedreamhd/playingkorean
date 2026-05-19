class KoreanRomanizer {
  static const List<String> _initials = [
    'g', 'kk', 'n', 'd', 'tt', 'r', 'm', 'b', 'pp', 's', 'ss', '', 'j', 'jj', 'ch', 'k', 't', 'p', 'h'
  ];

  static const List<String> _medials = [
    'a', 'ae', 'ya', 'yae', 'eo', 'e', 'yeo', 'ye', 'o', 'wa', 'wae', 'oe', 'yo', 'u', 'wo', 'we', 'wi', 'yu', 'eu', 'ui', 'i'
  ];

  static const List<String> _finals = [
    '', 'k', 'k', 'k', 'n', 'n', 'n', 't', 'l', 'k', 'm', 'p', 'l', 'l', 'l', 'l', 'm', 'p', 'p', 't', 't', 'ng', 't', 't', 'k', 't', 'p', 't'
  ];

  /// 한글 텍스트를 음절 단위로 로마자 변환하고 하이픈으로 연결합니다.
  /// 예: '봉사' → 'bong-sa', '눈' → 'nun'
  static String romanize(String text) {
    final syllables = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final charCode = text.codeUnitAt(i);
      if (charCode >= 0xAC00 && charCode <= 0xD7A3) {
        // 이전에 누적된 비한글 문자 처리
        if (buffer.isNotEmpty) {
          syllables.add(buffer.toString());
          buffer.clear();
        }
        final hangulCode = charCode - 0xAC00;
        final initialIndex = hangulCode ~/ (21 * 28);
        final medialIndex = (hangulCode % (21 * 28)) ~/ 28;
        final finalIndex = hangulCode % 28;

        syllables.add(
          _initials[initialIndex] +
          _medials[medialIndex] +
          _finals[finalIndex],
        );
      } else {
        buffer.write(text[i]);
      }
    }
    if (buffer.isNotEmpty) syllables.add(buffer.toString());

    return syllables.join('-');
  }
}
