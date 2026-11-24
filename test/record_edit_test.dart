import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/models/tournament_record.dart';
import 'package:battle_log/screens/record_edit_screen.dart';
import 'package:battle_log/widgets/pokemon_picker_dialog.dart';

TournamentRecord _record() => TournamentRecord(
      id: 'r1',
      date: DateTime(2025, 9, 1),
      tournamentName: '테스트 대회',
      myDeckName: '내 덱',
      myPokemonIds: const [25],
      rounds: [RoundRecord()],
    );

void main() {
  group('초성 검색', () {
    testWidgets('ㄷㄹ 을 치면 드래펄트가 결과에 나온다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PokemonPickerDialog(selectedIds: [], maxSelect: 3),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField).first, 'ㄷㄹ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 결과가 많아 화면 밖에 있을 수 있으므로 그리드를 스크롤하며 찾는다
      await tester.scrollUntilVisible(
        find.text('드래펄트'),
        200,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 60,
      );
      await tester.pump();

      expect(find.text('드래펄트'), findsOneWidget);
    });

    testWidgets('메가진화도 초성으로 검색된다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PokemonPickerDialog(selectedIds: [], maxSelect: 3),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField).first, 'ㅁㄱㄹㅈㅁ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('메가리자몽X'), findsOneWidget);
    });

    testWidgets('초성 1글자는 결과를 좁히지 않는다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PokemonPickerDialog(selectedIds: [], maxSelect: 3),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField).first, 'ㄷ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 'ㄷ' 하나는 초성 검색이 아니므로 드래펄트는 나오지 않는다
      expect(find.text('드래펄트'), findsNothing);
    });

    testWidgets('검색 후 포켓몬을 누르면 검색어가 지워진다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PokemonPickerDialog(selectedIds: [], maxSelect: 3),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final field = find.byType(TextField).first;
      await tester.enterText(field, 'ㄷㄹ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.widget<TextField>(field).controller!.text, 'ㄷㄹ');

      // 검색 결과에서 드래펄트 선택
      await tester.tap(find.text('드래펄트'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 검색창이 비워진다
      expect(tester.widget<TextField>(field).controller!.text, '');
      // 선택은 유지된다
      expect(find.text('선택 완료 (1마리)'), findsOneWidget);
    });

    testWidgets('검색 중 이미 고른 포켓몬을 다시 눌러 해제해도 검색어가 비워진다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PokemonPickerDialog(selectedIds: [887], maxSelect: 3),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final field = find.byType(TextField).first;
      await tester.enterText(field, 'ㄷㄹ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('드래펄트'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.widget<TextField>(field).controller!.text, '');
      expect(find.text('선택 완료 (선택 없음)'), findsOneWidget);
    });

    testWidgets('검색하지 않은 상태에서 눌러도 문제없다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PokemonPickerDialog(selectedIds: [], maxSelect: 3),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 검색 없이 첫 카드 선택 (이상해씨)
      await tester.tap(find.text('이상해씨'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('선택 완료 (1마리)'), findsOneWidget);
      // 검색어는 원래 없었으므로 그대로 비어있다
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '',
      );
    });
  });

  group('접힌 라운드 스프라이트', () {
    testWidgets('접으면 선택한 상대 포켓몬 스프라이트가 헤더에 보인다', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final record = _record();
      record.rounds = [
        RoundRecord(opponentPokemonIds: const [25, 6, 9]),
      ];

      await tester.pumpWidget(
          MaterialApp(home: RecordEditScreen(record: record, isNew: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 펼친 상태에서는 헤더 스프라이트 없음
      expect(find.byKey(const Key('collapsed-opp-sprites')), findsNothing);

      await tester.tap(find.text('접기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('collapsed-opp-sprites')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('좁은 화면에서도 접힌 헤더에 스프라이트가 넘침 없이 보인다', (tester) async {
      for (final size in [const Size(360, 1400), const Size(375, 1400)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final record = _record();
        record.rounds = [
          RoundRecord(opponentPokemonIds: const [887, 6, 1000]),
          RoundRecord(opponentPokemonIds: const [25, 26, 27]),
        ];

        await tester.pumpWidget(
            MaterialApp(home: RecordEditScreen(record: record, isNew: true)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        await tester.tap(find.text('접기').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull, reason: '$size 넘침 없음');
        expect(find.byKey(const Key('collapsed-opp-sprites')),
            findsAtLeastNWidgets(1));
      }
    });

    testWidgets('상대 포켓몬이 없으면 접어도 스프라이트 영역이 없다', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final record = _record();
      record.rounds = [RoundRecord()];

      await tester.pumpWidget(
          MaterialApp(home: RecordEditScreen(record: record, isNew: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('접기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('collapsed-opp-sprites')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('선택된 포켓몬 X 버튼', () {
    testWidgets('아이콘은 그대로, 터치 영역만 넓어져 살짝 빗나가도 삭제된다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PokemonPickerDialog(selectedIds: [25], maxSelect: 3),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 선택된 피카츄의 X 버튼 (다이얼로그 닫기 버튼과 구분)
      final removeBtn = find.byKey(const ValueKey('remove-selected-25'));
      expect(removeBtn, findsOneWidget);

      // X 배지 중심에서 살짝 벗어난 지점을 눌러도 삭제되어야 한다 (터치 영역 확대)
      final center = tester.getCenter(removeBtn);
      await tester.tapAt(center + const Offset(9, 9));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('선택 완료 (선택 없음)'), findsOneWidget);
    });

    testWidgets('X 아이콘 크기는 10으로 유지된다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PokemonPickerDialog(selectedIds: [25], maxSelect: 3),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final icon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey('remove-selected-25')),
        matching: find.byIcon(Icons.close),
      ));
      expect(icon.size, 10);
    });
  });

  group('라운드 기록', () {
    testWidgets('상대 덱 이름 입력칸이 없다', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          MaterialApp(home: RecordEditScreen(record: _record(), isNew: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('상대 덱 이름 (예: 피카츄 ex)'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('접기 버튼을 누르면 내용이 접히고 펴기로 바뀐다', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          MaterialApp(home: RecordEditScreen(record: _record(), isNew: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 펼친 상태: 매치 결과 보임
      expect(find.text('매치 결과'), findsOneWidget);
      expect(find.text('접기'), findsOneWidget);
      expect(find.text('펴기'), findsNothing);

      await tester.tap(find.text('접기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('매치 결과'), findsNothing);
      expect(find.text('펴기'), findsOneWidget);
      expect(find.text('접기'), findsNothing);

      // 다시 펴기
      await tester.tap(find.text('펴기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('매치 결과'), findsOneWidget);
      expect(find.text('접기'), findsOneWidget);
    });

    testWidgets('마이너스 버튼을 누르면 삭제 확인 문구가 뜬다', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final record = _record()..rounds = [RoundRecord(), RoundRecord()];

      await tester.pumpWidget(
          MaterialApp(home: RecordEditScreen(record: record, isNew: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('2라운드'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('기록을 삭제하겠습니까?'), findsOneWidget);
      expect(find.text('예'), findsOneWidget);
      expect(find.text('아니오'), findsOneWidget);

      // 아니오 -> 유지
      await tester.tap(find.text('아니오'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('2라운드'), findsOneWidget);

      // 다시 열고 예 -> 삭제
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('예'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('2라운드'), findsNothing);
      expect(find.text('1라운드'), findsOneWidget);
    });
    testWidgets('좁은 화면에서도 라운드 헤더가 넘치지 않는다', (tester) async {
      for (final size in [const Size(360, 1400), const Size(375, 1400)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final record = _record()
          ..rounds = [RoundRecord(), RoundRecord(), RoundRecord()];

        await tester.pumpWidget(
            MaterialApp(home: RecordEditScreen(record: record, isNew: true)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull, reason: '$size 넘침 없음');

        // 접었다 펴도 문제 없어야 한다
        await tester.tap(find.text('접기').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: '$size 접은 상태 넘침 없음');
      }
    });
  });

  group('라운드 접힘 상태 유지', () {
    test('저장/재로딩(JSON 변환) 후에도 접힌 상태가 유지된다', () {
      final record = _record()
        ..rounds = [
          RoundRecord(collapsed: true),
          RoundRecord(),
        ];

      final reloaded =
          TournamentRecord.fromJson(Map<String, dynamic>.from(record.toJson()));

      expect(reloaded.rounds[0].collapsed, isTrue);
      expect(reloaded.rounds[1].collapsed, isFalse);
    });

    testWidgets('접힌 라운드는 화면에 다시 들어와도 접힌 채로 보인다', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final record = _record()
        ..rounds = [
          RoundRecord(opponentPokemonIds: const [25], collapsed: true),
        ];

      await tester.pumpWidget(
          MaterialApp(home: RecordEditScreen(record: record, isNew: false)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('펴기'), findsOneWidget);
      expect(find.text('접기'), findsNothing);
      // 접힌 상태이므로 내용(게임 결과)은 보이지 않는다
      expect(find.text('매치 결과'), findsNothing);
    });

    testWidgets('접은 뒤 저장하면 결과 레코드에 접힘이 담긴다', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      TournamentRecord? returned;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  returned = await Navigator.push<TournamentRecord>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RecordEditScreen(record: _record(), isNew: false),
                    ),
                  );
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('열기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('접기').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('저장'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(returned, isNotNull);
      expect(returned!.rounds.first.collapsed, isTrue);
    });

    testWidgets('접힌 라운드는 다른 필드를 건드려도 저절로 펴지지 않는다', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          MaterialApp(home: RecordEditScreen(record: _record(), isNew: false)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('접기').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('펴기'), findsOneWidget);

      // 다른 입력칸을 눌러도 접힘이 풀리지 않아야 한다
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('펴기'), findsOneWidget);
      expect(find.text('매치 결과'), findsNothing);

      // '펴기'를 눌러야만 풀린다
      await tester.tap(find.text('펴기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('접기'), findsOneWidget);
      expect(find.text('매치 결과'), findsOneWidget);
    });
  });
}
