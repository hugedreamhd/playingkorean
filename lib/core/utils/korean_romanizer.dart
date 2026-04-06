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

  static String romanize(String text) {
    StringBuffer result = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      if (charCode >= 0xAC00 && charCode <= 0xD7A3) {
        int hangulCode = charCode - 0xAC00;
        int initialIndex = hangulCode ~/ (21 * 28);
        int medialIndex = (hangulCode % (21 * 28)) ~/ 28;
        int finalIndex = hangulCode % 28;

        result.write(_initials[initialIndex]);
        result.write(_medials[medialIndex]);
        result.write(_finals[finalIndex]);
      } else {
        result.write(text[i]);
      }
    }
    return result.toString();
  }
}
