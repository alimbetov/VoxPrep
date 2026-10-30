import '../../application/content_delivery/content_manifest.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';

final class ContentManifestDecoder {
  const ContentManifestDecoder();

  Result<RootContentManifest> decodeRoot(Object? value) {
    try {
      final object = _object(value, r'$');
      final schemaVersion = _integer(
        object,
        'schemaVersion',
        r'$.schemaVersion',
      );
      final schemaFailure = _schemaFailure(
        schemaVersion,
        invalidCode: 'MANIFEST_INVALID',
      );
      if (schemaFailure != null) {
        return FailureResult<RootContentManifest>(schemaFailure);
      }

      final minimumAppContractVersion = _integer(
        object,
        'minimumAppContractVersion',
        r'$.minimumAppContractVersion',
      );
      if (minimumAppContractVersion > careerSpeakAppContractVersion) {
        return FailureResult<RootContentManifest>(
          ApplicationFailure(
            code: 'APP_UPDATE_REQUIRED',
            message: 'The manifest requires a newer application contract.',
            details: <String, Object?>{
              'minimumAppContractVersion': minimumAppContractVersion,
              'appContractVersion': careerSpeakAppContractVersion,
            },
          ),
        );
      }

      final packs = <PackRevisionRef>[];
      final packValues = _list(object, 'packs', r'$.packs');
      for (var index = 0; index < packValues.length; index += 1) {
        final path = '\$.packs[$index]';
        final pack = _object(packValues[index], path);
        packs.add(
          PackRevisionRef(
            identity: PackIdentity(
              code: _string(pack, 'code', '$path.code'),
              variant: _string(pack, 'variant', '$path.variant'),
            ),
            revision: _integer(pack, 'revision', '$path.revision'),
            checksum: _string(pack, 'checksum', '$path.checksum'),
          ),
        );
      }

      final tombstones = <ContentTombstone>[];
      final tombstoneValues = _list(object, 'tombstones', r'$.tombstones');
      for (var index = 0; index < tombstoneValues.length; index += 1) {
        final path = '\$.tombstones[$index]';
        final tombstone = _object(tombstoneValues[index], path);
        tombstones.add(
          ContentTombstone(
            identity: _contentIdentity(tombstone, path),
            revision: _integer(tombstone, 'revision', '$path.revision'),
            reason: _string(tombstone, 'reason', '$path.reason'),
          ),
        );
      }

      return Success<RootContentManifest>(
        RootContentManifest(
          schemaVersion: schemaVersion,
          contentVersion: _integer(
            object,
            'contentVersion',
            r'$.contentVersion',
          ),
          minimumAppContractVersion: minimumAppContractVersion,
          publishedAt: _utcDateTime(object, 'publishedAt', r'$.publishedAt'),
          checksum: _string(object, 'checksum', r'$.checksum'),
          packs: packs,
          tombstones: tombstones,
        ),
      );
    } on _ContractViolation catch (error) {
      return FailureResult<RootContentManifest>(
        _invalidFailure('MANIFEST_INVALID', error),
      );
    } on ArgumentError catch (error) {
      return FailureResult<RootContentManifest>(
        _argumentFailure('MANIFEST_INVALID', error),
      );
    }
  }

  Result<PackContentManifest> decodePack(Object? value) {
    try {
      final object = _object(value, r'$');
      final schemaVersion = _integer(
        object,
        'schemaVersion',
        r'$.schemaVersion',
      );
      final schemaFailure = _schemaFailure(
        schemaVersion,
        invalidCode: 'PACK_MANIFEST_INVALID',
      );
      if (schemaFailure != null) {
        return FailureResult<PackContentManifest>(schemaFailure);
      }

      final contents = <PackContentRef>[];
      final contentValues = _list(object, 'contents', r'$.contents');
      for (var index = 0; index < contentValues.length; index += 1) {
        final path = '\$.contents[$index]';
        final content = _object(contentValues[index], path);
        contents.add(
          PackContentRef(
            identity: _contentIdentity(content, path),
            revision: _integer(content, 'revision', '$path.revision'),
            checksum: _string(content, 'checksum', '$path.checksum'),
            sortOrder: _optionalInteger(
              content,
              'sortOrder',
              '$path.sortOrder',
            ),
            publishedAt: _optionalUtcDateTime(
              content,
              'publishedAt',
              '$path.publishedAt',
            ),
          ),
        );
      }

      final assets = <ManifestAssetDescriptor>[];
      final assetValues = _list(object, 'assets', r'$.assets');
      for (var index = 0; index < assetValues.length; index += 1) {
        final path = '\$.assets[$index]';
        final asset = _object(assetValues[index], path);
        assets.add(
          ManifestAssetDescriptor(
            assetId: _string(asset, 'assetId', '$path.assetId'),
            checksumSha256: _string(
              asset,
              'checksumSha256',
              '$path.checksumSha256',
            ),
            deliveryKey: _string(asset, 'deliveryKey', '$path.deliveryKey'),
            sizeBytes: _integer(asset, 'sizeBytes', '$path.sizeBytes'),
            mediaType: _string(asset, 'mediaType', '$path.mediaType'),
            requiredOffline: _boolean(
              asset,
              'requiredOffline',
              '$path.requiredOffline',
            ),
          ),
        );
      }

      final contentAssets = <ContentAssetRef>[];
      final contentAssetValues = _list(
        object,
        'contentAssets',
        r'$.contentAssets',
      );
      for (var index = 0; index < contentAssetValues.length; index += 1) {
        final path = '\$.contentAssets[$index]';
        final ref = _object(contentAssetValues[index], path);
        contentAssets.add(
          ContentAssetRef(
            contentIdentity: _contentIdentity(ref, path),
            contentRevision: _integer(
              ref,
              'contentRevision',
              '$path.contentRevision',
            ),
            assetId: _string(ref, 'assetId', '$path.assetId'),
            role: _string(ref, 'role', '$path.role'),
          ),
        );
      }

      return Success<PackContentManifest>(
        PackContentManifest(
          schemaVersion: schemaVersion,
          identity: PackIdentity(
            code: _string(object, 'code', r'$.code'),
            variant: _string(object, 'variant', r'$.variant'),
          ),
          revision: _integer(object, 'revision', r'$.revision'),
          checksum: _string(object, 'checksum', r'$.checksum'),
          contents: contents,
          assets: assets,
          contentAssets: contentAssets,
        ),
      );
    } on _ContractViolation catch (error) {
      return FailureResult<PackContentManifest>(
        _invalidFailure('PACK_MANIFEST_INVALID', error),
      );
    } on ArgumentError catch (error) {
      return FailureResult<PackContentManifest>(
        _argumentFailure('PACK_MANIFEST_INVALID', error),
      );
    }
  }

  ApplicationFailure? _schemaFailure(
    int schemaVersion, {
    required String invalidCode,
  }) {
    if (schemaVersion > supportedContentManifestSchemaVersion) {
      return ApplicationFailure(
        code: 'SCHEMA_UNSUPPORTED',
        message: 'The content manifest schema is newer than this app supports.',
        details: <String, Object?>{
          'remoteSchemaVersion': schemaVersion,
          'supportedSchemaVersion': supportedContentManifestSchemaVersion,
        },
      );
    }
    if (schemaVersion < 1) {
      return ApplicationFailure(
        code: invalidCode,
        message: 'The content manifest schema version is invalid.',
        details: <String, Object?>{'remoteSchemaVersion': schemaVersion},
      );
    }
    return null;
  }

  ApplicationFailure _invalidFailure(String code, _ContractViolation error) {
    return ApplicationFailure(
      code: code,
      message: 'The server returned an invalid content manifest.',
      details: <String, Object?>{'field': error.path, 'reason': error.reason},
    );
  }

  ApplicationFailure _argumentFailure(String code, ArgumentError error) {
    return ApplicationFailure(
      code: code,
      message: 'The server returned an invalid content manifest.',
      details: <String, Object?>{
        if (error.name != null) 'field': error.name,
        if (error.message != null) 'reason': error.message.toString(),
      },
    );
  }

  ContentIdentity _contentIdentity(Map<String, Object?> object, String path) {
    final code = _string(object, 'contentCode', '$path.contentCode');
    if (!_contentCodePattern.hasMatch(code)) {
      throw _ContractViolation(
        '$path.contentCode',
        'must be a stable business code',
      );
    }

    final typeName = _string(object, 'contentType', '$path.contentType');
    final type = contentTypeFromWireName(typeName);
    if (type == null) {
      throw _ContractViolation(
        '$path.contentType',
        'contains an unsupported content type',
      );
    }
    return ContentIdentity(code: code, type: type);
  }

  Map<String, Object?> _object(Object? value, String path) {
    if (value is! Map) {
      throw _ContractViolation(path, 'must be a JSON object');
    }

    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw _ContractViolation(path, 'contains a non-string key');
      }
      result[key] = entry.value;
    }
    return result;
  }

  List<Object?> _list(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! List) {
      throw _ContractViolation(path, 'must be a JSON array');
    }
    return List<Object?>.unmodifiable(value);
  }

  String _string(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      throw _ContractViolation(path, 'must be a non-blank string');
    }
    return value.trim();
  }

  int _integer(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! int) {
      throw _ContractViolation(path, 'must be an integer');
    }
    return value;
  }

  int? _optionalInteger(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw _ContractViolation(path, 'must be an integer or null');
    }
    return value;
  }

  bool _boolean(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! bool) {
      throw _ContractViolation(path, 'must be a boolean');
    }
    return value;
  }

  DateTime _utcDateTime(Map<String, Object?> object, String key, String path) {
    return _parseUtc(_string(object, key, path), path);
  }

  DateTime? _optionalUtcDateTime(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final value = object[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw _ContractViolation(path, 'must be a UTC timestamp or null');
    }
    return _parseUtc(value.trim(), path);
  }

  DateTime _parseUtc(String value, String path) {
    final match = _utcTimestampPattern.firstMatch(value);
    if (match == null) {
      throw _ContractViolation(path, 'must use canonical ISO-8601 UTC');
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null ||
        !parsed.isUtc ||
        parsed.year != int.parse(match.group(1)!) ||
        parsed.month != int.parse(match.group(2)!) ||
        parsed.day != int.parse(match.group(3)!) ||
        parsed.hour != int.parse(match.group(4)!) ||
        parsed.minute != int.parse(match.group(5)!) ||
        parsed.second != int.parse(match.group(6)!)) {
      throw _ContractViolation(path, 'must use canonical ISO-8601 UTC');
    }
    return parsed;
  }
}

final _contentCodePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _utcTimestampPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?Z$',
);

final class _ContractViolation implements Exception {
  const _ContractViolation(this.path, this.reason);

  final String path;
  final String reason;
}
