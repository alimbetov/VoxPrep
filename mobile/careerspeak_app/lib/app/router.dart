import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/adaptive/careerspeak_adaptive_scaffold.dart';
import '../features/content/content_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/review/review_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tests/test_session_screen.dart';
import '../features/tests/tests_screen.dart';
import 'content_locations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            CareerSpeakAdaptiveScaffold(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/learn',
            builder: (context, state) => const LearnScreen(),
          ),
          GoRoute(
            path: '/tests',
            builder: (context, state) => const TestsScreen(),
          ),
          GoRoute(
            path: '/tests/:code',
            builder: (context, state) =>
                TestSessionScreen(code: state.pathParameters['code']!),
          ),
          GoRoute(
            path: '/review',
            builder: (context, state) => const ReviewScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/content/:type/:code',
            redirect: (context, state) {
              final identity = contentIdentityFromRoute(
                typeCode: state.pathParameters['type'],
                code: state.pathParameters['code'],
              );
              return identity == null ? '/learn' : null;
            },
            builder: (context, state) => ContentDetailScreen(
              identity: contentIdentityFromRoute(
                typeCode: state.pathParameters['type'],
                code: state.pathParameters['code'],
              )!,
            ),
          ),
        ],
      ),
    ],
  );
});
