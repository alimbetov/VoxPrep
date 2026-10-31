class ContentMarkerState {
  const ContentMarkerState({
    this.favorite = false,
    this.listened = false,
    this.completed = false,
    this.lastPositionMs,
    this.lastRevisionSeen,
  });

  final bool favorite;
  final bool listened;
  final bool completed;
  final int? lastPositionMs;
  final int? lastRevisionSeen;

  ContentMarkerState copyWith({
    bool? favorite,
    bool? listened,
    bool? completed,
    int? lastPositionMs,
    int? lastRevisionSeen,
    bool clearLastPosition = false,
    bool clearLastRevisionSeen = false,
  }) {
    return ContentMarkerState(
      favorite: favorite ?? this.favorite,
      listened: listened ?? this.listened,
      completed: completed ?? this.completed,
      lastPositionMs: clearLastPosition
          ? null
          : lastPositionMs ?? this.lastPositionMs,
      lastRevisionSeen: clearLastRevisionSeen
          ? null
          : lastRevisionSeen ?? this.lastRevisionSeen,
    );
  }
}
