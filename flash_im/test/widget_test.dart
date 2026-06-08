import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flash_im/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(FlashImApp(navigatorKey: navigatorKey));
    await tester.pump();
    expect(find.byType(FlashImApp), findsOneWidget);
  });
}