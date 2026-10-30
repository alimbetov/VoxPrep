import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentMarkerState {
  const ContentMarkerState({
    this.favorite = false,
    this.listened = false,
    this.completed = false,
  });

  final bool favorite;
  final bool listened;
  final bool completed;

  ContentMarkerState copyWith({
    bool? favorite,
    bool? listened,
    bool? completed,
  }) {
    return ContentMarkerState(
      favorite: favorite ?? this.favorite,
      listened: listened ?? this.listened,
      completed: completed ?? this.completed,
    );
  }
}

final contentMarkersProvider = NotifierProvider<ContentMarkersController,
    Map<String, ContentMarkerState>>(ContentMarkersController.new);

class ContentMarkersController
    extends Notifier<Map<String, ContentMarkerState>> {
  @override
  Map<String, ContentMarkerState> build() {
    return const {
      'JAVA_DI_001': ContentMarkerState(listened: true),
      'IELTS_ENV_001': ContentMarkerState(
        favorite: true,
        listened: true,
        completed: true,
      ),
      'VOCAB_SIGNIFICANT': ContentMarkerState(favorite: true),
    };
  }

  ContentMarkerState _current(String code) =>
      state[code] ?? const ContentMarkerState();

  void toggleFavorite(String code) {
    final current = _current(code);
    state = {
      ...state,
      code: current.copyWith(favorite: !current.favorite),
    };
  }

  void toggleListened(String code) {
    final current = _current(code);
    state = {
      ...state,
      code: current.copyWith(listened: !current.listened),
    };
  }

  void toggleCompleted(String code) {
    final current = _current(code);
    state = {
      ...state,
      code: current.copyWith(completed: !current.completed),
    };
  }
}
