import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venered_social/widgets/user_search_dialog.dart';

void main() {
  testWidgets('UserSearchDialog builds and contains input', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: UserSearchDialog())));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Buscar usuario'), findsOneWidget);
  });
}
