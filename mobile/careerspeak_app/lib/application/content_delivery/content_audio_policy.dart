import '../../domain/content_item.dart';

enum AudioRequirement { optional, recommended, required }

enum ContentAudioRole {
  pronunciation('pronunciation'),
  question('question'),
  sampleAnswer('sampleAnswer'),
  narration('narration'),
  shadowing('shadowing');

  const ContentAudioRole(this.wireName);

  final String wireName;

  static ContentAudioRole? fromWireName(String value) {
    for (final role in values) {
      if (role.wireName == value) return role;
    }
    return null;
  }
}

final class ContentAudioPolicyEntry {
  const ContentAudioPolicyEntry({
    required this.role,
    required this.requirement,
  });

  final ContentAudioRole role;
  final AudioRequirement requirement;
}

final class ContentAudioPolicy {
  const ContentAudioPolicy._();

  static List<ContentAudioPolicyEntry> forType(ContentType type) => switch (type) {
    ContentType.vocabulary => const <ContentAudioPolicyEntry>[
      ContentAudioPolicyEntry(
        role: ContentAudioRole.pronunciation,
        requirement: AudioRequirement.optional,
      ),
    ],
    ContentType.phrase => const <ContentAudioPolicyEntry>[
      ContentAudioPolicyEntry(
        role: ContentAudioRole.pronunciation,
        requirement: AudioRequirement.recommended,
      ),
    ],
    ContentType.interview => const <ContentAudioPolicyEntry>[
      ContentAudioPolicyEntry(
        role: ContentAudioRole.question,
        requirement: AudioRequirement.recommended,
      ),
      ContentAudioPolicyEntry(
        role: ContentAudioRole.sampleAnswer,
        requirement: AudioRequirement.recommended,
      ),
    ],
    ContentType.topic => const <ContentAudioPolicyEntry>[
      ContentAudioPolicyEntry(
        role: ContentAudioRole.narration,
        requirement: AudioRequirement.optional,
      ),
    ],
    ContentType.shadowing => const <ContentAudioPolicyEntry>[
      ContentAudioPolicyEntry(
        role: ContentAudioRole.shadowing,
        requirement: AudioRequirement.required,
      ),
    ],
  };

  static bool allows(ContentType type, ContentAudioRole role) {
    return forType(type).any((entry) => entry.role == role);
  }

  static List<ContentAudioRole> requiredRoles(ContentType type) {
    return List<ContentAudioRole>.unmodifiable(
      forType(type)
          .where((entry) => entry.requirement == AudioRequirement.required)
          .map((entry) => entry.role),
    );
  }

  static List<ContentAudioRole> recommendedRoles(ContentType type) {
    return List<ContentAudioRole>.unmodifiable(
      forType(type)
          .where((entry) => entry.requirement == AudioRequirement.recommended)
          .map((entry) => entry.role),
    );
  }

  static ContentAudioRole primaryRole(ContentType type) => switch (type) {
    ContentType.vocabulary || ContentType.phrase =>
      ContentAudioRole.pronunciation,
    ContentType.interview => ContentAudioRole.question,
    ContentType.topic => ContentAudioRole.narration,
    ContentType.shadowing => ContentAudioRole.shadowing,
  };
}
