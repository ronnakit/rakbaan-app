import 'package:flutter_test/flutter_test.dart';

import 'package:rakbaan_page1/main.dart';
import 'package:rakbaan_page1/repositories/mock_job_repository.dart';

void main() {
  testWidgets('App boots into the home tab with bottom nav visible', (tester) async {
    // jobRepository override -- no Firebase app is initialized in this test,
    // so RakBaanApp must not construct a FirestoreJobRepository itself.
    await tester.pumpWidget(
      RakBaanApp(customerId: 'test-user', jobRepository: MockJobRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('รักบ้าน@CNX'), findsOneWidget);
    expect(find.text('แจ้งซ่อม'), findsOneWidget);
    expect(find.text('ติดตามงาน'), findsOneWidget);
    expect(find.text('แชทมะลิ'), findsOneWidget);
    expect(find.text('โปรไฟล์'), findsOneWidget);
  });
}
