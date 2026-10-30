import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('favorite listened and completed are independent markers', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const code = 'TEST_ITEM';
    final controller = container.read(contentMarkersProvider.notifier);

    controller.toggleFavorite(code);
    var state = container.read(contentMarkersProvider)[code]!;
    expect(state.favorite, isTrue);
    expect(state.listened, isFalse);
    expect(state.completed, isFalse);

    controller.toggleListened(code);
    state = container.read(contentMarkersProvider)[code]!;
    expect(state.favorite, isTrue);
    expect(state.listened, isTrue);
    expect(state.completed, isFalse);

    controller.toggleCompleted(code);
    state = container.read(contentMarkersProvider)[code]!;
    expect(state.favorite, isTrue);
    expect(state.listened, isTrue);
    expect(state.completed, isTrue);
  });
}
