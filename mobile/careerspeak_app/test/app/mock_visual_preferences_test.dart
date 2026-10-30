import 'package:careerspeak_app/app/mock_visual_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visual preview settings remain independent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(mockVisualPreferencesProvider.notifier);
    controller.setUiLanguage(MockUiLanguage.kazakh);
    controller.setTranslationLanguage(MockTranslationLanguage.russian);
    controller.setAccent(MockAccent.uk);
    controller.setTextScale(MockTextScalePreview.extraLarge);
    controller.setRtlPreview(true);

    final state = container.read(mockVisualPreferencesProvider);
    expect(state.uiLanguage, MockUiLanguage.kazakh);
    expect(state.translationLanguage, MockTranslationLanguage.russian);
    expect(state.accent, MockAccent.uk);
    expect(state.textScale, MockTextScalePreview.extraLarge);
    expect(state.textScale.factor, 2.0);
    expect(state.rtlPreview, isTrue);
  });
}
