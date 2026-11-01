import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/application/query/page.dart' as app_page;
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/learn/learn_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('O5 Learn opens dedicated learning-direction flow', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/learn',
      routes: [
        GoRoute(
          path: '/learn',
          builder: (context, state) => const Scaffold(body: LearnScreen()),
        ),
        GoRoute(
          path: '/learn/direction',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('direction-screen')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentPageProvider.overrideWith(
            (ref) => Stream<app_page.Page<ContentItem>>.value(
              const app_page.Page<ContentItem>(items: [], hasMore: false),
            ),
          ),
          contentMarkersProvider.overrideWith(
            (ref) => Stream<Map<ContentIdentity, ContentMarkerState>>.value(
              const <ContentIdentity, ContentMarkerState>{},
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Change direction'), findsOneWidget);
    await tester.tap(find.text('Change direction'));
    await tester.pumpAndSettle();

    expect(find.text('direction-screen'), findsOneWidget);
  });
}
