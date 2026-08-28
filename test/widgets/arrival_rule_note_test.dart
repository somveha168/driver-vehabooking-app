import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:veha_driver_app/app/core/i18n/app_translations.dart';
import 'package:veha_driver_app/app/core/widgets/arrival_rule_note.dart';

void main() {
  Future<void> pump(WidgetTester tester, Locale locale) => tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: AppTranslations.fallbackLocale,
      home: const Scaffold(body: ArrivalRuleNote()),
    ),
  );

  testWidgets('states the 15-minute rule in English', (tester) async {
    await pump(tester, const Locale('en', 'US'));
    expect(
      find.text('Arrive at the pickup at least 15 minutes early'),
      findsOneWidget,
    );
  });

  testWidgets('states the 15-minute rule in Khmer', (tester) async {
    await pump(tester, const Locale('km', 'KH'));
    expect(find.textContaining('១៥នាទី'), findsOneWidget);
  });
}
