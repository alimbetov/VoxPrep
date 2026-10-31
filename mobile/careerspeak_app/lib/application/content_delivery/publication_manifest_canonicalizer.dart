import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'catalogue_revision_ref.dart';
import 'content_manifest.dart';

/// Canonical C4.4 projection used to derive immutable manifest identity.
///
/// The declared `checksum` field is intentionally excluded from its own digest.
/// Runtime/security values (ETag, tokens, signed URLs, local state, timestamps of
/// access) are not representable by this projector and therefore cannot affect
/// publication identity.
final class PublicationManifestCanonicalizer {
  const PublicationManifestCanonicalizer();

  String rootDigest(RootContentManifest manifest) {
    return _sha256(_encode(_rootBody(manifest)));
  }

  String packDigest(PackContentManifest manifest) {
    return _sha256(_encode(_packBody(manifest)));
  }

  Map<String, Object?> _rootBody(RootContentManifest manifest) {
    return <String, Object?>{
      'schemaVersion': manifest.schemaVersion,
      'contentVersion': manifest.contentVersion,
      'minimumAppContractVersion': manifest.minimumAppContractVersion,
      'publishedAt': _canonicalUtc(manifest.publishedAt),
      'packs': manifest.packs
          .map(
            (ref) => <String, Object?>{
              'code': ref.identity.code,
              'variant': ref.identity.variant,
              'revision': ref.revision,
              'checksum': ref.checksum,
            },
          )
          .toList(growable: false),
      'practiceTests': manifest.practiceTests
          .map(
            (ref) => <String, Object?>{
              'practiceTestCode': ref.practiceTestCode,
              'revision': ref.revision,
              'checksum': ref.checksum,
            },
          )
          .toList(growable: false),
      'catalogues': manifest.catalogues
          .map(
            (ref) => <String, Object?>{
              'kind': ref.kind.wireName,
              'revision': ref.revision,
              'checksum': ref.checksum,
            },
          )
          .toList(growable: false),
      'localeFallbacks': manifest.localeFallbacks
          .map(
            (rule) => <String, Object?>{
              'locale': rule.locale,
              'fallbackLocales': rule.fallbackLocales,
            },
          )
          .toList(growable: false),
      'tombstones': manifest.tombstones
          .map(
            (tombstone) => <String, Object?>{
              'contentCode': tombstone.identity.code,
              'contentType': tombstone.identity.type.name,
              'revision': tombstone.revision,
              'reason': tombstone.reason,
            },
          )
          .toList(growable: false),
    };
  }

  Map<String, Object?> _packBody(PackContentManifest manifest) {
    return <String, Object?>{
      'schemaVersion': manifest.schemaVersion,
      'code': manifest.identity.code,
      'variant': manifest.identity.variant,
      'revision': manifest.revision,
      'contents': manifest.contents
          .map(
            (ref) => <String, Object?>{
              'contentCode': ref.identity.code,
              'contentType': ref.identity.type.name,
              'revision': ref.revision,
              'checksum': ref.checksum,
              'sortOrder': ref.sortOrder,
              'publishedAt': ref.publishedAt == null
                  ? null
                  : _canonicalUtc(ref.publishedAt!),
            },
          )
          .toList(growable: false),
      'localizations': manifest.localizations
          .map(
            (ref) => <String, Object?>{
              'contentCode': ref.identity.code,
              'contentType': ref.identity.type.name,
              'contentRevision': ref.contentRevision,
              'locale': ref.locale,
              'localizationRevision': ref.localizationRevision,
              'checksum': ref.checksum,
            },
          )
          .toList(growable: false),
      'assets': manifest.assets
          .map(
            (asset) => <String, Object?>{
              'assetId': asset.assetId,
              'checksumSha256': asset.checksumSha256,
              'deliveryKey': asset.deliveryKey,
              'sizeBytes': asset.sizeBytes,
              'mediaType': asset.mediaType,
              'requiredOffline': asset.requiredOffline,
            },
          )
          .toList(growable: false),
      'contentAssets': manifest.contentAssets
          .map(
            (ref) => <String, Object?>{
              'contentCode': ref.contentIdentity.code,
              'contentType': ref.contentIdentity.type.name,
              'contentRevision': ref.contentRevision,
              'assetId': ref.assetId,
              'role': ref.role,
            },
          )
          .toList(growable: false),
    };
  }

  String _encode(Map<String, Object?> value) => jsonEncode(value);

  String _sha256(String canonicalJson) {
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  String _canonicalUtc(DateTime value) {
    final utc = value.toUtc();
    if (utc.microsecond == 0 && utc.millisecond == 0) {
      return '${utc.toIso8601String().split('.').first}Z';
    }
    return utc.toIso8601String();
  }
}
