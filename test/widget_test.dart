// Basic smoke test: the app boots and shows a splash screen while it
// restores the session, without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storepass/app.dart';

void main() {
  testWidgets('StorePassApp boots to a splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StorePassApp());
    await tester.pump();

    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
  });
}
