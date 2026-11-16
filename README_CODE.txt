Battle Log - 소스 코드 (Flutter 3.35.4 / Dart 3.9.2)

[구조]
lib/main.dart                      앱 시작, 테마 3종 연결
lib/theme/app_theme.dart           색 팔레트, 테마 3종(흰색/다크/배경이미지), 전구 버튼, ArtBackground
lib/screens/home_screen.dart       메인 화면(카드 목록, 통계, 선택 저장, 폴더 버튼)
lib/screens/record_edit_screen.dart 기록 입력/수정
lib/screens/calendar_screen.dart   월별 달력
lib/screens/folder_screen.dart     폴더 목록/폴더 상세
lib/widgets/masonry_list.dart      목록(폰 1열 / 데스크탑 여러 열)
lib/widgets/backup_dialogs.dart    백업 코드 만들기/복원 창
lib/widgets/folder_picker_sheet.dart 폴더 이름 입력, 폴더 선택 시트
lib/widgets/pokemon_picker_dialog.dart 포켓몬 선택(세대 탭, 검색)
lib/widgets/pokemon_avatar_row.dart 포켓몬 아이콘 줄
lib/providers/tournament_provider.dart 기록/폴더 상태 + 저장(SharedPreferences)
lib/utils/backup_codec.dart        백업 코드 압축(BLOG2) / 예전 코드(BLOG1) 읽기
lib/data/pokemon_data.dart         포켓몬 1~9세대 이름/번호 목록
assets/bg/bg.png                   배경 이미지
assets/icon/app_icon.png           앱 아이콘 원본
web/index.html, web/manifest.json  웹/홈화면 추가 설정
android/.../AndroidManifest.xml    인터넷 권한 포함
android/app/build.gradle.kts       앱 ID, 릴리스 서명 설정

[빌드 방법]
1) flutter pub get
2) 웹: flutter build web --release --pwa-strategy=none
3) APK: flutter build apk --release --split-per-abi

[릴리스 서명 준비]
android/key.properties 파일을 만들고 아래 4줄을 채운다.
storePassword=...
keyPassword=...
keyAlias=battlelog
storeFile=../release-key.jks
키 파일(release-key.jks)은 보안상 이 압축에 넣지 않았다. 직접 만든 키를 쓰거나,
새로 만들려면: keytool -genkeypair -v -keystore release-key.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10950 -alias battlelog \
  -storepass <비밀번호> -keypass <비밀번호> -dname "CN=Battle Log, O=BattleLog, C=KR"

[데이터]
기록/폴더/테마는 기기 로컬(shared_preferences)에만 저장된다.
기기 이전은 앱 안의 ⋮ > 백업 코드 만들기 / 백업 코드로 복원 사용.
