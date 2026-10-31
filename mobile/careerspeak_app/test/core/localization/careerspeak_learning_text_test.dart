import 'package:careerspeak_app/core/localization/careerspeak_learning_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('canonical learning text remains LTR inside RTL application UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CareerSpeakLearningText('Dependency Injection'),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Dependency Injection'));
    final textContext = tester.element(find.text('Dependency Injection'));

    expect(text.data, 'Dependency Injection');
    expect(Directionality.of(textContext), TextDirection.ltr);
  });
}
