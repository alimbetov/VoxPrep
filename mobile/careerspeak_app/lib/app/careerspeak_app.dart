import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/careerspeak_theme.dart';

class CareerSpeakApp extends ConsumerWidget {
  const CareerSpeakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CareerSpeak',
      debugShowCheckedModeBanner: false,
      theme: CareerSpeakTheme.light(),
      darkTheme: CareerSpeakTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
