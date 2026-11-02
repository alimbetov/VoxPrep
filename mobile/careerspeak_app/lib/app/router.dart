import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/adaptive/careerspeak_adaptive_scaffold.dart';
import '../core/motion/careerspeak_motion.dart';
import '../features/access/full_unlock_screen.dart';
import '../features/catalogue/catalogue_home_screen.dart';
import '../features/catalogue/catalogue_screen.dart';
import '../features/content/content_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/learning_direction/learning_direction_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/review/review_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tests/test_session_screen.dart';
import '../features/tests/tests_screen.dart';
import 'content_locations.dart';
import 'onboarding_providers.dart';
import 'onboarding_redirect_policy.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingCompleted = ref.watch(
    onboardingStateProvider.select((state) => state.asData?.value.completed),
  );

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) => onboardingRedirect(
      onboardingCompleted: onboardingCompleted,
      matchedLocation: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/locale',
        redirect: (context, state) => '/onboarding',
      ),
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
            path: '/catalogue',
            pageBuilder: (context, state) =>
                _page(state: state, child: const CatalogueHomeScreen()),
          ),
          GoRoute(
            path: '/catalogue/all',
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: const CatalogueAllScreen(),
            ),
          ),
          GoRoute(
            path: '/catalogue/vertical/:verticalCode',
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: CatalogueVerticalScreen(
                verticalCode: state.pathParameters['verticalCode']!,
              ),
            ),
          ),
          GoRoute(
            path: '/catalogue/vertical/:verticalCode/goal/:goalCode',
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: CatalogueGoalScreen(
                verticalCode: state.pathParameters['verticalCode']!,
                goalCode: state.pathParameters['goalCode']!,
              ),
            ),
          ),
          GoRoute(
            path:
                '/catalogue/vertical/:verticalCode/goal/:goalCode/track/:trackCode',
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: CatalogueTrackScreen(
                verticalCode: state.pathParameters['verticalCode']!,
                goalCode: state.pathParameters['goalCode']!,
                trackCode: state.pathParameters['trackCode']!,
              ),
            ),
          ),
          GoRoute(
            path:
                '/catalogue/vertical/:verticalCode/goal/:goalCode/track/:trackCode/collection/:collectionCode',
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: CatalogueCollectionScreen(
                verticalCode: state.pathParameters['verticalCode']!,
                goalCode: state.pathParameters['goalCode']!,
                trackCode: state.pathParameters['trackCode']!,
                collectionCode: state.pathParameters['collectionCode']!,
              ),
            ),
          ),
          GoRoute(
            path: '/unlock',
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: const FullUnlockScreen(),
            ),
          ),
          GoRoute(
            path: '/learn',
            pageBuilder: (context, state) =>
                _page(state: state, child: const LearnScreen()),
          ),
          GoRoute(
            path: '/learn/direction',
            pageBuilder: (context, state) => _page(
              state: state,
              hierarchical: true,
              child: const LearningDirectionScreen(),
            ),
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
              return identity == null ? '/catalogue' : null;
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
