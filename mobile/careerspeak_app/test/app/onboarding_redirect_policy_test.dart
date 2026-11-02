import 'package:careerspeak_app/app/onboarding_redirect_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('onboardingRedirect', () {
    test('does not redirect while onboarding state is loading', () {
      expect(
        onboardingRedirect(onboardingCompleted: null, matchedLocation: '/'),
        isNull,
      );
    });

    test('incomplete onboarding redirects normal routes to onboarding', () {
      expect(
        onboardingRedirect(onboardingCompleted: false, matchedLocation: '/'),
        '/onboarding',
      );
      expect(
        onboardingRedirect(
          onboardingCompleted: false,
          matchedLocation: '/catalogue',
        ),
        '/onboarding',
      );
    });

    test('incomplete onboarding does not redirect onboarding itself', () {
      expect(
        onboardingRedirect(
          onboardingCompleted: false,
          matchedLocation: '/onboarding',
        ),
        isNull,
      );
    });

    test('completed onboarding leaves normal routes alone', () {
      expect(
        onboardingRedirect(onboardingCompleted: true, matchedLocation: '/'),
        isNull,
      );
      expect(
        onboardingRedirect(
          onboardingCompleted: true,
          matchedLocation: '/catalogue',
        ),
        isNull,
      );
    });

    test('completed onboarding redirects onboarding routes home', () {
      expect(
        onboardingRedirect(
          onboardingCompleted: true,
          matchedLocation: '/onboarding',
        ),
        '/',
      );
      expect(
        onboardingRedirect(
          onboardingCompleted: true,
          matchedLocation: '/onboarding/locale',
        ),
        '/',
      );
    });
  });
}
