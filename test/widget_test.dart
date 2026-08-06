import 'package:flutter_test/flutter_test.dart';

import 'package:rakbaan_page1/main.dart';

void main() {
  testWidgets('App boots into the home tab with bottom nav visible', (tester) async {
    await tester.pumpWidget(const RakBaanApp());
    await tester.pumpAndSettle();

    expect(find.text('รักบ้าน@CNX'), findsOneWidget);
    expect(find.text('แจ้งซ่อม'), findsOneWidget);
    expect(find.text('ติดตามงาน'), findsOneWidget);
    expect(find.text('แชทมะลิ'), findsOneWidget);
    expect(find.text('โปรไฟล์'), findsOneWidget);
  });
}
