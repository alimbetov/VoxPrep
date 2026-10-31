import 'package:careerspeak_app/app/mock_visual_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visual qualification settings remain independent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(mockVisualPreferencesProvider.notifier);
    controller.setTextScale(MockTextScalePreview.extraLarge);
    controller.setRtlPreview(true);
    controller.setReducedMotionPreview(true);

    final state = container.read(mockVisualPreferencesProvider);
    expect(state.textScale, MockTextScalePreview.extraLarge);
    expect(state.textScale.factor, 2.0);
    expect(state.rtlPreview, isTrue);
    expect(state.reducedMotionPreview, isTrue);
  });
}
