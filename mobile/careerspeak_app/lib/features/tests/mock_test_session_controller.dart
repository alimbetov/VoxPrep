import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockTestSessionState {
  const MockTestSessionState({
    this.testCode,
    this.currentIndex = 0,
    this.answers = const {},
    this.submitted = false,
  });

  final String? testCode;
  final int currentIndex;
  final Map<int, int> answers;
  final bool submitted;

  bool get started => testCode != null;

  MockTestSessionState copyWith({
    String? testCode,
    int? currentIndex,
    Map<int, int>? answers,
    bool? submitted,
  }) {
    return MockTestSessionState(
      testCode: testCode ?? this.testCode,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      submitted: submitted ?? this.submitted,
    );
  }
}

final mockTestSessionProvider =
    NotifierProvider<MockTestSessionController, MockTestSessionState>(
  MockTestSessionController.new,
);

class MockTestSessionController extends Notifier<MockTestSessionState> {
  @override
  MockTestSessionState build() => const MockTestSessionState();

  void start(String testCode) {
    state = MockTestSessionState(testCode: testCode);
  }

  void selectAnswer(int optionIndex) {
    if (!state.started || state.submitted) return;
    state = state.copyWith(
      answers: {...state.answers, state.currentIndex: optionIndex},
    );
  }

  void goTo(int index, int totalQuestions) {
    if (!state.started || index < 0 || index >= totalQuestions) return;
    state = state.copyWith(currentIndex: index);
  }

  void next(int totalQuestions) {
    if (state.currentIndex >= totalQuestions - 1) return;
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  void previous() {
    if (state.currentIndex <= 0) return;
    state = state.copyWith(currentIndex: state.currentIndex - 1);
  }

  void submit() {
    if (!state.started) return;
    state = state.copyWith(submitted: true);
  }

  void reset() {
    state = const MockTestSessionState();
  }
}
