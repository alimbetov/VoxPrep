enum CareerSpeakWindowSizeClass {
  compact,
  medium,
  expanded,
  large,
}

CareerSpeakWindowSizeClass windowSizeClassFor(double width) {
  if (width < 600) return CareerSpeakWindowSizeClass.compact;
  if (width < 840) return CareerSpeakWindowSizeClass.medium;
  if (width < 1200) return CareerSpeakWindowSizeClass.expanded;
  return CareerSpeakWindowSizeClass.large;
}
