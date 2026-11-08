import '../../domain/content_identity.dart';

/// Opt-in v2 video metadata. Never a binary offline asset or audio role.
final class ExternalLearningVideo {
  ExternalLearningVideo({
    required this.identity,
    required this.revision,
    required this.title,
    required this.providerVideoId,
    required this.rootSha256,
  }) {
    if (revision < 1 ||
        title.trim().isEmpty ||
        title.length > 160 ||
        !_videoId.hasMatch(providerVideoId) ||
        !_sha256.hasMatch(rootSha256)) {
      throw const FormatException('Invalid external learning video');
    }
  }

  final ContentIdentity identity;
  final int revision;
  final String title;
  final String providerVideoId;
  final String rootSha256;

  Uri get uri => Uri.https('www.youtube.com', '/watch', <String, String>{
    'v': providerVideoId,
  });

  static ExternalLearningVideo parse(
    Object? json, {
    required ContentIdentity identity,
    required int revision,
  }) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Video metadata must be an object');
    }
    const keys = <String>{
      'schemaVersion', 'contentType', 'contentCode', 'revision',
      'contentVersion', 'rootSha256', 'provider', 'providerVideoId',
      'title', 'url',
    };
    if (json.keys.toSet().difference(keys).isNotEmpty ||
        json.keys.toSet().difference(keys).isNotEmpty ||
        json.length != keys.length ||
        json['schemaVersion'] != 1 ||
        json['contentType'] != identity.type.name ||
        json['contentCode'] != identity.code ||
        json['revision'] != revision ||
        json['contentVersion'] is! int ||
        (json['contentVersion'] as int) < 1 ||
        json['provider'] != 'YOUTUBE' ||
        json['providerVideoId'] is! String ||
        json['title'] is! String ||
        json['rootSha256'] is! String ||
        json['url'] is! String) {
      throw const FormatException('Video metadata does not match exact content');
    }
    final video = ExternalLearningVideo(
      identity: identity,
      revision: revision,
      title: json['title'] as String,
      providerVideoId: json['providerVideoId'] as String,
      rootSha256: json['rootSha256'] as String,
    );
    if (json['url'] != video.uri.toString()) {
      throw const FormatException('Non-canonical video URL');
    }
    return video;
  }

  static final RegExp _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
}
