import '../../application/result/result.dart';

final class PublicationManifestWireGuard {
  const PublicationManifestWireGuard();

  Result<void> validateRoot(Object? value) {
    try {
      final root = _object(value, r'$');
      _only(root, _rootKeys, r'$');
      _objects(root, 'packs', r'$.packs', _packRefKeys);
      _objects(root, 'practiceTests', r'$.practiceTests', _practiceTestRefKeys);
      _objects(root, 'catalogues', r'$.catalogues', _catalogueRefKeys);
      _objects(
        root,
        'localeFallbacks',
        r'$.localeFallbacks',
        _localeFallbackKeys,
      );
      _objects(root, 'tombstones', r'$.tombstones', _tombstoneKeys);
      return const Success<void>(null);
    } on _WireShapeViolation catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'MANIFEST_NON_PUBLICATION_FIELD',
          message:
              'The root manifest contains fields outside the immutable publication contract.',
          details: <String, Object?>{
            'field': error.path,
            'reason': error.reason,
          },
        ),
      );
    }
  }

  Result<void> validatePack(Object? value) {
    try {
      final pack = _object(value, r'$');
      _only(pack, _packKeys, r'$');
      _objects(pack, 'contents', r'$.contents', _contentRefKeys);
      _objects(pack, 'localizations', r'$.localizations', _localizationRefKeys);
      _objects(pack, 'assets', r'$.assets', _assetKeys);
      _objects(pack, 'contentAssets', r'$.contentAssets', _contentAssetKeys);
      return const Success<void>(null);
    } on _WireShapeViolation catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'PACK_MANIFEST_NON_PUBLICATION_FIELD',
          message:
              'The pack manifest contains fields outside the immutable publication contract.',
          details: <String, Object?>{
            'field': error.path,
            'reason': error.reason,
          },
        ),
      );
    }
  }

  Map<String, Object?> _object(Object? value, String path) {
    if (value is! Map) {
      throw _WireShapeViolation(path, 'must be a JSON object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw _WireShapeViolation(path, 'contains a non-string key');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  void _only(Map<String, Object?> object, Set<String> allowed, String path) {
    for (final key in object.keys) {
      if (!allowed.contains(key)) {
        throw _WireShapeViolation(
          '$path.$key',
          'is not part of publication identity',
        );
      }
    }
  }

  void _objects(
    Map<String, Object?> object,
    String key,
    String path,
    Set<String> allowed,
  ) {
    final value = object[key];
    if (value == null) return;
    if (value is! List) {
      throw _WireShapeViolation(path, 'must be a JSON array');
    }
    for (var index = 0; index < value.length; index += 1) {
      final itemPath = '$path[$index]';
      _only(_object(value[index], itemPath), allowed, itemPath);
    }
  }
}

final class _WireShapeViolation implements Exception {
  const _WireShapeViolation(this.path, this.reason);

  final String path;
  final String reason;
}

const _rootKeys = <String>{
  'schemaVersion',
  'contentVersion',
  'minimumAppContractVersion',
  'publishedAt',
  'checksum',
  'packs',
  'practiceTests',
  'catalogues',
  'localeFallbacks',
  'tombstones',
};
const _packRefKeys = <String>{'code', 'variant', 'revision', 'checksum'};
const _practiceTestRefKeys = <String>{
  'practiceTestCode',
  'revision',
  'checksum',
};
const _catalogueRefKeys = <String>{'kind', 'revision', 'checksum'};
const _localeFallbackKeys = <String>{'locale', 'fallbackLocales'};
const _tombstoneKeys = <String>{
  'contentCode',
  'contentType',
  'revision',
  'reason',
};
const _packKeys = <String>{
  'schemaVersion',
  'code',
  'variant',
  'revision',
  'checksum',
  'contents',
  'localizations',
  'assets',
  'contentAssets',
};
const _contentRefKeys = <String>{
  'contentCode',
  'contentType',
  'revision',
  'checksum',
  'sortOrder',
  'publishedAt',
};
const _localizationRefKeys = <String>{
  'contentCode',
  'contentType',
  'contentRevision',
  'locale',
  'localizationRevision',
  'checksum',
};
const _assetKeys = <String>{
  'assetId',
  'checksumSha256',
  'deliveryKey',
  'sizeBytes',
  'mediaType',
  'requiredOffline',
};
const _contentAssetKeys = <String>{
  'contentCode',
  'contentType',
  'contentRevision',
  'assetId',
  'role',
};
