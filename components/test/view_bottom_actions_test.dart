import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows custom actions before the fixed back button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ViewBottomActions(
            optionButton1: ViewBottomAction(text: 'Ação 1', onPressed: () {}),
            optionButton2: ViewBottomAction(text: 'Ação 2', onPressed: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Ação 1'), findsOneWidget);
    expect(find.text('Ação 2'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);

    final labels = tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).toList();
    expect(labels.indexOf('Ação 1'), lessThan(labels.indexOf('Ação 2')));
    expect(labels.indexOf('Ação 2'), lessThan(labels.indexOf('Voltar')));
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('can hide or disable individual custom actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ViewBottomActions(
            optionButton1: ViewBottomAction(text: 'Oculta', onPressed: () {}, isVisible: false),
            optionButton2: const ViewBottomAction(text: 'Desabilitada', isEnabled: false),
          ),
        ),
      ),
    );

    expect(find.text('Oculta'), findsNothing);
    expect(find.text('Desabilitada'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.ancestor(of: find.text('Desabilitada'), matching: find.byType(FilledButton)))
          .onPressed,
      isNull,
    );
  });

  testWidgets('can hide the entire bottom action component', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(bottomNavigationBar: ViewBottomActions(isVisible: false))),
    );

    expect(find.text('Voltar'), findsNothing);
  });

  testWidgets('can collapse and expand the bottom actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ViewBottomActions(
            optionButton1: ViewBottomAction(text: 'Ação 1', onPressed: () {}),
            optionButton2: ViewBottomAction(text: 'Ação 2', onPressed: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Voltar'), findsOneWidget);
    await tester.tap(find.byTooltip('Ocultar ações inferiores'));
    await tester.pumpAndSettle();

    expect(find.text('Ação 1'), findsNothing);
    expect(find.text('Ação 2'), findsNothing);
    expect(find.text('Voltar'), findsNothing);

    await tester.tap(find.byTooltip('Exibir ações inferiores'));
    await tester.pumpAndSettle();

    expect(find.text('Ação 1'), findsOneWidget);
    expect(find.text('Ação 2'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
  });

  testWidgets('supports localized back and expansion labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ViewBottomActions(
            backLabel: 'Back',
            hideActionsTooltip: 'Hide actions',
            showActionsTooltip: 'Show actions',
          ),
        ),
      ),
    );

    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Hide actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show actions'));
    await tester.pumpAndSettle();
    expect(find.text('Back'), findsOneWidget);
  });
}
