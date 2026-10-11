import 'package:flutter_test/flutter_test.dart';
import 'package:warung_mama_fahri/app.dart';

void main() {
  testWidgets('renders the app title and main content', (tester) async {
    await tester.pumpWidget(const WarungMamaFahriApp());

    expect(find.text('Warung Mama Fahri'), findsOneWidget);
    expect(find.text('Layanan PPOB'), findsOneWidget);
  });
}
