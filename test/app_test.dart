import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:venered_social/main.dart';

void main() {
  testWidgets('La app muestra la pantalla de inicio de sesión', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Se puede navegar a la pantalla principal tras login', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.enterText(find.byType(TextField).first, 'juanito');
    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('Se muestra el badge de notificaciones', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.enterText(find.byType(TextField).first, 'juanito');
    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications), findsOneWidget);
  });

  testWidgets('Los usuarios verificados muestran el icono azul', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.enterText(find.byType(TextField).first, 'juanito');
    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.verified), findsWidgets);
  });
}
