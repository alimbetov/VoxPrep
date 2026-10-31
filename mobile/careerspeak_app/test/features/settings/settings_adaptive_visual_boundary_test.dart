import 'package:careerspeak_app/app/app_preferences_providers.dart';
import 'package:careerspeak_app/application/ports/app_preferences_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:careerspeak_app/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/ui_boundary_harness.dart';

void main() {
  for (final boundary in adaptiveUiBoundaryCases) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'Settings stays within visual boundaries for $boundary $direction',
        (tester) async {
          await pumpAdaptiveSurface(
            tester,
            boundary: boundary,
            child: ProviderScope(
              overrides: [
                appPreferencesRepositoryProvider.overrideWithValue(
                  const _PreferencesRepository(),
                ),
              ],
              child: MaterialApp(
                home: Directionality(
                  textDirection: direction,
                  child: const Scaffold(body: SettingsScreen()),
                ),
              ),
            ),
          );

          expectNoLayoutExceptions(
            tester,
            reason:
                'Settings initial viewport must not overflow for $boundary $direction',
          );

          expect(find.text('Settings'), findsOneWidget);
          expect(find.text('UI language'), findsOneWidget);
          expect(find.text('Translation language'), findsOneWidget);
          expect(find.text('Preferred accent'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('Storage'),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();

          expectNoLayoutExceptions(
            tester,
            reason:
                'Settings full scroll must not overflow for $boundary $direction',
          );
          expect(find.text('RTL layout preview'), findsOneWidget);
          expect(find.text('Reduced motion preview'), findsOneWidget);
          expect(find.text('Storage'), findsOneWidget);
        },
      );
    }
  }
}

final class _PreferencesRepository implements AppPreferencesRepository {
  const _PreferencesRepository();

  @override
  Stream<Result<ApplicationPreferences>> watchPreferences() =>
      Stream<Result<ApplicationPreferences>>.value(
        const Success<ApplicationPreferences>(ApplicationPreferences.defaults),
      );

  @override
  Future<Result<ApplicationPreferences>> getPreferences() async =>
      const Success<ApplicationPreferences>(ApplicationPreferences.defaults);

  @override
  Future<Result<void>> setFocusMode(bool enabled) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setPreferredAccent(
    PreferredEnglishAccent? accent,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> setStorageQuotaBytes(int? bytes) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setTheme(AppThemePreference theme) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setTranslationLocale(
    AppTranslationLocale locale,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> setUiLocale(AppUiLocale locale) async =>
      const Success<void>(null);
}
