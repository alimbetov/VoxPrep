import 'package:flutter/material.dart';
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

    return MaterialApp.router(
      title: 'CareerSpeak',
      debugShowCheckedModeBanner: false,
      theme: CareerSpeakTheme.light(),
      darkTheme: CareerSpeakTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scaledMediaQuery = mediaQuery.copyWith(
          textScaler: TextScaler.linear(visualPreferences.textScale.factor),
          disableAnimations:
              mediaQuery.disableAnimations ||
              visualPreferences.reducedMotionPreview,
        );
        final rtl = visualPreferences.rtlPreview || preferences.uiLocale.isRtl;

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
