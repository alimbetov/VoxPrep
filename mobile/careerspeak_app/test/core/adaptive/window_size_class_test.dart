import 'package:careerspeak_app/core/adaptive/window_size_class.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps CareerSpeak adaptive breakpoints deterministically', () {
    expect(windowSizeClassFor(599), CareerSpeakWindowSizeClass.compact);
    expect(windowSizeClassFor(600), CareerSpeakWindowSizeClass.medium);
    expect(windowSizeClassFor(839), CareerSpeakWindowSizeClass.medium);
    expect(windowSizeClassFor(840), CareerSpeakWindowSizeClass.expanded);
    expect(windowSizeClassFor(1199), CareerSpeakWindowSizeClass.expanded);
    expect(windowSizeClassFor(1200), CareerSpeakWindowSizeClass.large);
  });
}
