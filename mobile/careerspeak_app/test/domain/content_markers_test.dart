import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('favorite listened completed and playback position are independent', () {
    var state = const ContentMarkerState();

    state = state.copyWith(favorite: true);
    expect(state.favorite, isTrue);
    expect(state.listened, isFalse);
    expect(state.completed, isFalse);
    expect(state.lastPositionMs, isNull);

    state = state.copyWith(listened: true, lastPositionMs: 1250);
    expect(state.favorite, isTrue);
    expect(state.listened, isTrue);
    expect(state.completed, isFalse);
    expect(state.lastPositionMs, 1250);

    state = state.copyWith(completed: true);
    expect(state.favorite, isTrue);
    expect(state.listened, isTrue);
    expect(state.completed, isTrue);
    expect(state.lastPositionMs, 1250);

    state = state.copyWith(clearLastPosition: true);
    expect(state.lastPositionMs, isNull);
  });
}
