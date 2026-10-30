import 'content_item.dart';

class ContentIdentity {
  const ContentIdentity({required this.code, required this.type});

  factory ContentIdentity.fromItem(ContentItem item) {
    return ContentIdentity(code: item.code, type: item.type);
  }

  final String code;
  final ContentType type;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ContentIdentity && other.code == code && other.type == type;
  }

  @override
  int get hashCode => Object.hash(code, type);
}
