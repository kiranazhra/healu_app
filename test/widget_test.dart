// Widget test dasar untuk aplikasi HealU.
//
// Test ini memverifikasi bahwa HealUApp berhasil dibangun tanpa error
// dan splash screen menampilkan judul aplikasi dengan benar.

import 'package:flutter_test/flutter_test.dart';

import 'package:healu_app/main.dart';

void main() {
  testWidgets('HealU app builds and shows splash screen', (
    WidgetTester tester,
  ) async {
    // Build aplikasi dan trigger satu frame.
    await tester.pumpWidget(const HealUApp());

    // Verifikasi judul "HealU" muncul di splash screen.
    expect(find.text('HealU'), findsOneWidget);

    // Verifikasi slogan aplikasi juga muncul.
    expect(find.text('You Matter, We Care ❤️'), findsOneWidget);
  });
}