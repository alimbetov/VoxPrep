import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.textScale = MockTextScalePreview.normal,
    this.rtlPreview = false,
    this.reducedMotionPreview = false,
  });

  final MockTextScalePreview textScale;
  final bool rtlPreview;
  final bool reducedMotionPreview;

  MockVisualPreferences copyWith({
    MockTextScalePreview? textScale,
    bool? rtlPreview,
    bool? reducedMotionPreview,
  }) {
    return MockVisualPreferences(
      textScale: textScale ?? this.textScale,
      rtlPreview: rtlPreview ?? this.rtlPreview,
      reducedMotionPreview: reducedMotionPreview ?? this.reducedMotionPreview,
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

  void setTextScale(MockTextScalePreview value) {
    state = state.copyWith(textScale: value);
  }

  void setRtlPreview(bool value) {
    state = state.copyWith(rtlPreview: value);
  }

  void setReducedMotionPreview(bool value) {
    state = state.copyWith(reducedMotionPreview: value);
  }
}
