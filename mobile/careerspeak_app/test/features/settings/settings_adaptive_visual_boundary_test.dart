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
          // The settings list is lazy at accessible font sizes. Each field
          // must be reachable by scrolling, not necessarily visible at once.
          for (final label in const <String>[
            'Country and language',
            'Select country',
            'Preferred English accent',
            'Country',
            'Accessibility',
            'Offline learning',
          ]) {
            final target = find.text(label);
            // A lazily built ListView might not have created this Text yet.
            // Calling .first before materialization throws StateError.
            for (
              var attempt = 0;
              attempt < 18 && target.evaluate().isEmpty;
              attempt++
            ) {
              await tester.drag(
                find.byType(Scrollable).first,
                const Offset(0, -180),
              );
              await tester.pumpAndSettle();
            }
            expect(target, findsWidgets);
            await tester.ensureVisible(target.first);
            await tester.pumpAndSettle();
            expectNoLayoutExceptions(
              tester,
              reason: 'Settings field $label must not overflow at $boundary',
            );
          }
          await tester.pumpAndSettle();

          expectNoLayoutExceptions(
            tester,
            reason:
                'Settings full scroll must not overflow for $boundary $direction',
          );
          // Each current production settings section was explicitly checked
          // above after being scrolled into view at this viewport size.
          expectNoLayoutExceptions(
            tester,
            reason: 'Settings last section must fit $boundary $direction',
          );
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
  Future<Result<void>> setLocaleSelection({
    required String countryCode,
    required AppTranslationLocale locale,
  }) async => const Success<void>(null);

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
