import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monetization uses the official in_app_purchase package', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('in_app_purchase: ^3.3.1'));
    expect(pubspec, isNot(contains('billingclient')));
    expect(pubspec, isNot(contains('flutter_inapp_purchase')));
  });
}
