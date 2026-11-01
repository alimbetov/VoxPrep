import 'content_identity.dart';

class LastOpenedContent {
  const LastOpenedContent({
    required this.identity,
    required this.contentRevision,
    required this.openedAt,
  });

  final ContentIdentity identity;
  final int contentRevision;
  final DateTime openedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LastOpenedContent &&
            other.identity == identity &&
            other.contentRevision == contentRevision &&
            other.openedAt == openedAt;
  }

  @override
  int get hashCode => Object.hash(identity, contentRevision, openedAt);
}
