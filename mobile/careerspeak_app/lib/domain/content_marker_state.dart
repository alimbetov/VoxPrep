class ContentMarkerState {
  const ContentMarkerState({
    this.favorite = false,
    this.listened = false,
    this.completed = false,
    this.lastPositionMs,
  });

  final bool favorite;
  final bool listened;
  final bool completed;
  final int? lastPositionMs;

  ContentMarkerState copyWith({
    bool? favorite,
    bool? listened,
    bool? completed,
    int? lastPositionMs,
    bool clearLastPosition = false,
  }) {
    return ContentMarkerState(
      favorite: favorite ?? this.favorite,
      listened: listened ?? this.listened,
      completed: completed ?? this.completed,
      lastPositionMs: clearLastPosition
          ? null
          : lastPositionMs ?? this.lastPositionMs,
    );
  }
}
