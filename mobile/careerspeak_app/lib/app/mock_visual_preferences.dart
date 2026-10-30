import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MockUiLanguage {
  english('English'),
  russian('Русский'),
  kazakh('Қазақша');

  const MockUiLanguage(this.label);
  final String label;
}

enum MockTranslationLanguage {
  english('English'),
  russian('Русский'),
  kazakh('Қазақша');

  const MockTranslationLanguage(this.label);
  final String label;
}

enum MockAccent {
  us('US English'),
  uk('UK English'),
  australian('Australian English');

  const MockAccent(this.label);
  final String label;
}

enum MockTextScalePreview {
  normal(1.0, '1.0×'),
  large(1.6, '1.6×'),
  extraLarge(2.0, '2.0×');

  const MockTextScalePreview(this.factor, this.label);
  final double factor;
  final String label;
}

class MockVisualPreferences {
  const MockVisualPreferences({
    this.uiLanguage = MockUiLanguage.english,
    this.translationLanguage = MockTranslationLanguage.russian,
    this.accent = MockAccent.us,
    this.textScale = MockTextScalePreview.normal,
    this.rtlPreview = false,
  });

  final MockUiLanguage uiLanguage;
  final MockTranslationLanguage translationLanguage;
  final MockAccent accent;
  final MockTextScalePreview textScale;
  final bool rtlPreview;

  MockVisualPreferences copyWith({
    MockUiLanguage? uiLanguage,
    MockTranslationLanguage? translationLanguage,
    MockAccent? accent,
    MockTextScalePreview? textScale,
    bool? rtlPreview,
  }) {
    return MockVisualPreferences(
      uiLanguage: uiLanguage ?? this.uiLanguage,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      accent: accent ?? this.accent,
      textScale: textScale ?? this.textScale,
      rtlPreview: rtlPreview ?? this.rtlPreview,
    );
  }
}

final mockVisualPreferencesProvider =
    NotifierProvider<MockVisualPreferencesController, MockVisualPreferences>(
  MockVisualPreferencesController.new,
);

class MockVisualPreferencesController extends Notifier<MockVisualPreferences> {
  @override
  MockVisualPreferences build() => const MockVisualPreferences();

  void setUiLanguage(MockUiLanguage value) {
    state = state.copyWith(uiLanguage: value);
  }

  void setTranslationLanguage(MockTranslationLanguage value) {
    state = state.copyWith(translationLanguage: value);
  }

  void setAccent(MockAccent value) {
    state = state.copyWith(accent: value);
  }

  void setTextScale(MockTextScalePreview value) {
    state = state.copyWith(textScale: value);
  }

  void setRtlPreview(bool value) {
    state = state.copyWith(rtlPreview: value);
  }
}
