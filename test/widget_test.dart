import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leadloop/screens/login_page.dart';

void main() {
  testWidgets('login page shows the brand and sign-in action',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.text('LeadLoop'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
