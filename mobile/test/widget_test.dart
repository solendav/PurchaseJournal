import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_journal/bootstrap_app.dart';

void main() {
  testWidgets('App boots', (tester) async {
    await tester.pumpWidget(const BootstrapApp());
    expect(find.byType(BootstrapApp), findsOneWidget);
  });
}
