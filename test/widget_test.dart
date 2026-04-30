// Smoke test placeholder for the JS bridge POC.
// Real webview interactions can't be exercised in unit tests without
// a platform channel mock, so we just verify the app boots.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:js_bridge_flutter/app.dart';

void main() {
  testWidgets('App boots inside ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('JS Bridge POC'), findsOneWidget);
  });
}
