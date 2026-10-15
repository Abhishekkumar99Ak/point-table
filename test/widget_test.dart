// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointcalc_clone/main.dart';
import 'package:pointcalc_clone/models/pointcalc_models.dart';
import 'package:pointcalc_clone/services/admin_access_controller.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Pointcalc opens the tournament dashboard', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TournamentStore()),
          ChangeNotifierProvider(create: (_) => AdminAccessController()),
        ],
        child: const PointcalcApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Point Table'), findsOneWidget);
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('ALL TOURNAMENTS'), findsOneWidget);
  });
}
