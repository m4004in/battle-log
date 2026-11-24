/// 한글 초성 검색 도우미
///
/// 예) '드래펄트' -> 'ㄷㄹㅍㅌ'  이므로 'ㄷㄹ' 로 검색하면 찾을 수 있다.
const List<String> _chosungList = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', //
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

const int _hangulStart = 0xAC00;
const int _hangulEnd = 0xD7A3;

/// 초성으로만 이루어진 검색어에 쓰이는 자모(겹받침/겹모음 포함)
const Set<String> _jamoChars = {
  'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', //
  'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', //
  'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ', //
  'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', //
  'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ',
};

/// 문자열을 초성 문자열로 변환한다. (한글이 아닌 글자는 그대로 둔다)
String toChosung(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= _hangulStart && rune <= _hangulEnd) {
      final index = (rune - _hangulStart) ~/ 588;
      buffer.write(_chosungList[index]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// 검색어가 자모(초성)로만 이루어져 있는지
bool isChosungQuery(String query) {
  if (query.isEmpty) return false;
  for (final ch in query.split('')) {
    if (!_jamoChars.contains(ch)) return false;
  }
  return true;
}

/// 초성 검색 대상인지 (2글자 이상의 초성)
bool isChosungSearch(String query) => query.length >= 2 && isChosungQuery(query);

/// 이름이 초성 검색어와 맞는지
bool matchesChosung(String name, String chosungQuery) {
  if (chosungQuery.isEmpty) return false;
  return toChosung(name).contains(chosungQuery);
}

/// 일반 텍스트/번호 검색어와 맞는지
bool matchesText(String nameKo, String name, int id, String query) {
  if (query.isEmpty) return false;
  final q = query.toLowerCase();
  return nameKo.toLowerCase().contains(q) ||
      name.toLowerCase().contains(q) ||
      id.toString() == q;
}

/// 포켓몬 이름 하나를 검색어와 비교한다. (초성 / 일반 텍스트 모두 지원)
bool matchesPokemonQuery({
  required String nameKo,
  required String name,
  required int id,
  required String query,
}) {
  final q = query.trim();
  if (q.isEmpty) return true;
  if (isChosungSearch(q)) return matchesChosung(nameKo, q);
  return matchesText(nameKo, name, id, q);
}
