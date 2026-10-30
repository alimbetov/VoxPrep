import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        );

        return MediaQuery(
          data: scaledMediaQuery,
          child: Directionality(
            textDirection: visualPreferences.rtlPreview
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
