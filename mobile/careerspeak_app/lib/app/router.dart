import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/adaptive/careerspeak_adaptive_scaffold.dart';
import '../core/motion/careerspeak_motion.dart';
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
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _page(state: state, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/learn',
            pageBuilder: (context, state) =>
                _page(state: state, child: const LearnScreen()),
          ),
          GoRoute(
            path: '/tests',
            pageBuilder: (context, state) =>
                _page(state: state, child: const TestsScreen()),
          ),
          GoRoute(
            path: '/tests/:code',
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: TestSessionScreen(code: state.pathParameters['code']!),
            ),
          ),
          GoRoute(
            path: '/review',
            pageBuilder: (context, state) =>
                _page(state: state, child: const ReviewScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _page(state: state, child: const SettingsScreen()),
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
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: ContentDetailScreen(
                identity: contentIdentityFromRoute(
                  typeCode: state.pathParameters['type'],
                  code: state.pathParameters['code'],
                )!,
              ),
            ),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _page({
  required GoRouterState state,
  required Widget child,
  bool hierarchical = false,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: CareerSpeakMotion.navigation,
    reverseTransitionDuration: CareerSpeakMotion.navigation,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CareerSpeakMotion.routeTransition(
        context: context,
        animation: animation,
        child: child,
        hierarchical: hierarchical,
      );
    },
  );
}
