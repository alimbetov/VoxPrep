import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/repository_providers.dart';
import '../../application/result/result.dart';
import '../../domain/practice_test_attempt.dart';

class PracticeTestSessionState {
  const PracticeTestSessionState({
    this.testCode,
    this.testRevision,
    this.currentIndex = 0,
    this.answers = const {},
    this.startedAt,
    this.submitted = false,
  });

  final String? testCode;
  final int? testRevision;
  final int currentIndex;
  final Map<int, int> answers;
  final DateTime? startedAt;
  final bool submitted;

  bool get started =>
      testCode != null && testRevision != null && startedAt != null;

  PracticeTestSessionState copyWith({
    String? testCode,
    int? testRevision,
    int? currentIndex,
    Map<int, int>? answers,
    DateTime? startedAt,
    bool? submitted,
  }) {
    return PracticeTestSessionState(
      testCode: testCode ?? this.testCode,
      testRevision: testRevision ?? this.testRevision,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      startedAt: startedAt ?? this.startedAt,
      submitted: submitted ?? this.submitted,
    );
  }

  factory PracticeTestSessionState.fromAttempt(PracticeTestAttempt attempt) {
    return PracticeTestSessionState(
      testCode: attempt.practiceTestCode,
      testRevision: attempt.practiceTestRevision,
      currentIndex: attempt.currentIndex,
      answers: Map<int, int>.unmodifiable(attempt.answers),
      startedAt: attempt.startedAt,
    );
  }
}

final practiceTestSessionProvider =
    NotifierProvider<PracticeTestSessionController, PracticeTestSessionState>(
      PracticeTestSessionController.new,
    );

class PracticeTestSessionController extends Notifier<PracticeTestSessionState> {
  int _mutationEpoch = 0;
  Future<void> _writeTail = Future<void>.value();

  @override
  PracticeTestSessionState build() {
    final expectedEpoch = _mutationEpoch;
    unawaited(_restore(expectedEpoch));
    return const PracticeTestSessionState();
  }

  Future<void> start(String testCode) {
    _mutationEpoch++;
    return _enqueue(() async {
      final result = await ref
          .read(practiceTestAttemptRepositoryProvider)
          .startActiveAttempt(testCode);
      final attempt = result.getOrThrow();
      state = PracticeTestSessionState.fromAttempt(attempt);
    });
  }

  Future<void> selectAnswer(int optionIndex) {
    if (!state.started || state.submitted || optionIndex < 0) {
      return Future<void>.value();
    }
    final next = state.copyWith(
      answers: {...state.answers, state.currentIndex: optionIndex},
    );
    state = next;
    return _enqueuePersist(next);
  }

  Future<void> goTo(int index, int totalQuestions) {
    if (!state.started || index < 0 || index >= totalQuestions) {
      return Future<void>.value();
    }
    final next = state.copyWith(currentIndex: index);
    state = next;
    return _enqueuePersist(next);
  }

  Future<void> next(int totalQuestions) {
    if (!state.started || state.currentIndex >= totalQuestions - 1) {
      return Future<void>.value();
    }
    final next = state.copyWith(currentIndex: state.currentIndex + 1);
    state = next;
    return _enqueuePersist(next);
  }

  Future<void> previous() {
    if (!state.started || state.currentIndex <= 0) {
      return Future<void>.value();
    }
    final next = state.copyWith(currentIndex: state.currentIndex - 1);
    state = next;
    return _enqueuePersist(next);
  }

  Future<void> submit() {
    if (!state.started) return Future<void>.value();
    _mutationEpoch++;
    state = state.copyWith(submitted: true);
    return _enqueue(() async {
      final result = await ref
          .read(practiceTestAttemptRepositoryProvider)
          .completeActiveAttempt();
      result.getOrThrow();
    });
  }

  Future<void> reset() {
    _mutationEpoch++;
    state = const PracticeTestSessionState();
    return _enqueue(() async {
      final result = await ref
          .read(practiceTestAttemptRepositoryProvider)
          .clearActiveAttempt();
      result.getOrThrow();
    });
  }

  Future<void> _restore(int expectedEpoch) async {
    final result = await ref
        .read(practiceTestAttemptRepositoryProvider)
        .getActiveAttempt();
    if (_mutationEpoch != expectedEpoch) return;
    if (result case Success<PracticeTestAttempt?>(:final value)) {
      if (value != null) {
        state = PracticeTestSessionState.fromAttempt(value);
      }
    }
  }

  Future<void> _enqueuePersist(PracticeTestSessionState next) {
    final attempt = PracticeTestAttempt(
      practiceTestCode: next.testCode!,
      practiceTestRevision: next.testRevision!,
      currentIndex: next.currentIndex,
      answers: Map<int, int>.unmodifiable(next.answers),
      startedAt: next.startedAt!,
      updatedAt: DateTime.now().toUtc(),
    );
    return _enqueue(() async {
      final result = await ref
          .read(practiceTestAttemptRepositoryProvider)
          .saveActiveAttempt(attempt);
      result.getOrThrow();
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (_) {});
    return next;
  }
}
