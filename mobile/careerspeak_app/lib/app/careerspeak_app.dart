import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/application_preferences.dart';
import 'app_preferences_providers.dart';
import 'mock_visual_preferences.dart';
import 'router.dart';
import 'theme/careerspeak_theme.dart';

class CareerSpeakApp extends ConsumerWidget {
  const CareerSpeakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final visualPreferences = ref.watch(mockVisualPreferencesProvider);
    final preferences =
        ref.watch(applicationPreferencesProvider).asData?.value ??
        ApplicationPreferences.defaults;
    final appLocale = _toFlutterLocale(preferences.selectedLocale.code);

    return MaterialApp.router(
      title: 'CareerSpeak',
      debugShowCheckedModeBanner: false,
      theme: CareerSpeakTheme.light(),
      darkTheme: CareerSpeakTheme.dark(),
      themeMode: themeMode,
      locale: appLocale,
      supportedLocales: AppUiLocale.values
          .map((locale) => _toFlutterLocale(locale.code))
          .toList(growable: false),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        CountryLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scaledMediaQuery = mediaQuery.copyWith(
          textScaler: TextScaler.linear(visualPreferences.textScale.factor),
          disableAnimations:
              mediaQuery.disableAnimations ||
              visualPreferences.reducedMotionPreview,
        );
        final rtl =
            visualPreferences.rtlPreview || preferences.selectedLocale.isRtl;

        return MediaQuery(
          data: scaledMediaQuery,
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

Locale _toFlutterLocale(String code) {
  final parts = code.split('-');
  if (parts.length == 1) return Locale(parts.first);
  if (parts.length == 2) {
    return Locale.fromSubtags(
      languageCode: parts.first,
      countryCode: parts[1].length == 2 ? parts[1] : null,
      scriptCode: parts[1].length == 4 ? parts[1] : null,
    );
  }
  return Locale.fromSubtags(
    languageCode: parts.first,
    scriptCode: parts[1].length == 4 ? parts[1] : null,
    countryCode: parts.last.length == 2 ? parts.last : null,
  );
}
