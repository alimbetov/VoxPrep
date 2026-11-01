String? onboardingRedirect({
  required bool? onboardingCompleted,
  required String matchedLocation,
}) {
  if (onboardingCompleted == null) return null;

  final isOnboarding = matchedLocation == '/onboarding';
  final isLegacyOnboarding = matchedLocation == '/onboarding/locale';

  if (!onboardingCompleted && !isOnboarding) {
    return '/onboarding';
  }
  if (onboardingCompleted && (isOnboarding || isLegacyOnboarding)) {
    return '/';
  }
  return null;
}
