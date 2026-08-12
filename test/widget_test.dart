import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic smoke test', (WidgetTester tester) async {
    // Test minimal volontaire : QotaApp dépend de Supabase.initialize()
    // (accès réseau), donc pas testable tel quel sans mock. Ce test
    // vérifie seulement que le moteur de test Flutter fonctionne.
    // Des tests plus poussés (par écran, avec mocks Supabase) sont à
    // ajouter au fil du développement, écran par écran.
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
