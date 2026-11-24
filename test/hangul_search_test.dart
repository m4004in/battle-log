import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/utils/hangul_search.dart';
import 'package:battle_log/data/pokemon_data.dart';

void main() {
  group('초성 변환', () {
    test('드래펄트 -> ㄷㄹㅍㅌ', () {
      expect(toChosung('드래펄트'), 'ㄷㄹㅍㅌ');
    });

    test('피카츄 -> ㅍㅋㅊ', () {
      expect(toChosung('피카츄'), 'ㅍㅋㅊ');
    });

    test('한글이 아닌 글자는 그대로 둔다', () {
      expect(toChosung('메가리자몽X'), 'ㅁㄱㄹㅈㅁX');
    });
  });

  group('초성 검색 판정', () {
    test('한 글자 초성은 초성 검색으로 보지 않는다', () {
      expect(isChosungSearch('ㄷ'), isFalse);
    });

    test('두 글자 이상 초성은 초성 검색', () {
      expect(isChosungSearch('ㄷㄹ'), isTrue);
      expect(isChosungSearch('ㄷㄹㅍㅌ'), isTrue);
    });

    test('일반 텍스트는 초성 검색이 아니다', () {
      expect(isChosungSearch('드래'), isFalse);
      expect(isChosungSearch('pika'), isFalse);
    });
  });

  group('포켓몬 검색 매칭', () {
    final drapult = allPokemon.firstWhere((p) => p.nameKo == '드래펄트');

    test('ㄷㄹ 로 드래펄트가 검색된다', () {
      expect(
        matchesPokemonQuery(
          nameKo: drapult.nameKo,
          name: drapult.name,
          id: drapult.id,
          query: 'ㄷㄹ',
        ),
        isTrue,
      );
    });

    test('ㄷㄹㅍㅌ 로도 검색된다', () {
      expect(
        matchesPokemonQuery(
          nameKo: drapult.nameKo,
          name: drapult.name,
          id: drapult.id,
          query: 'ㄷㄹㅍㅌ',
        ),
        isTrue,
      );
    });

    test('ㄴㄴ 초성은 드래펄트와 맞지 않는다', () {
      expect(
        matchesPokemonQuery(
          nameKo: drapult.nameKo,
          name: drapult.name,
          id: drapult.id,
          query: 'ㄴㄴ',
        ),
        isFalse,
      );
    });

    test('한 글자 초성은 이름 전체 검색으로 처리된다', () {
      // 'ㄷ' 은 초성 검색이 아니므로 이름 문자열 매칭 결과를 따른다
      expect(
        matchesPokemonQuery(
          nameKo: drapult.nameKo,
          name: drapult.name,
          id: drapult.id,
          query: 'ㄷ',
        ),
        isFalse,
      );
    });

    test('일반 한글 검색과 번호 검색도 동작한다', () {
      expect(
        matchesPokemonQuery(
          nameKo: drapult.nameKo,
          name: drapult.name,
          id: drapult.id,
          query: '드래',
        ),
        isTrue,
      );
      expect(
        matchesPokemonQuery(
          nameKo: drapult.nameKo,
          name: drapult.name,
          id: drapult.id,
          query: drapult.id.toString(),
        ),
        isTrue,
      );
    });
  });

  group('메가진화/폼 초성 검색', () {
    test('메가리자몽이 초성 ㅁㄱㄹㅈㅁ 로 검색된다', () {
      final mega = megaPokemon.firstWhere((p) => p.nameKo == '메가리자몽X');
      expect(
        matchesPokemonQuery(
          nameKo: mega.nameKo,
          name: mega.name,
          id: mega.id,
          query: 'ㅁㄱㄹㅈㅁ',
        ),
        isTrue,
      );
    });

    test('초성 ㄷㄹ 로 메가진화 이름도 걸러진다', () {
      // 메가드래캄 -> ㅁㄱㄷㄹㅋ 에 ㄷㄹ 이 들어간다
      final hits = megaPokemon.where((p) => matchesChosung(p.nameKo, 'ㄷㄹ'));
      expect(hits.map((p) => p.nameKo), contains('메가드래캄'));
      // 이름 중간이 아니라 앞에서부터 매칭되는 초성도 잡힌다
      expect(matchesChosung('메가드닐레이브', 'ㄷㄴ'), isTrue);
    });

    test('오거폰 가면 폼도 초성 검색된다', () {
      final form = ogerponForms.first;
      expect(matchesChosung(form.nameKo, 'ㅇㄱㅍ'), isTrue);
    });
  });
}
