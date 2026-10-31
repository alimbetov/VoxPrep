// ignore_for_file: prefer_initializing_formals

import '../../application/content_delivery/content_manifest.dart';
import '../../application/result/result.dart';
import 'content_manifest_mapper.dart';
import 'dto/content_manifest_dto.dart';

final class ContentManifestDecoder {
  const ContentManifestDecoder({
    ContentManifestMapper mapper = const ContentManifestMapper(),
  }) : _mapper = mapper;

  final ContentManifestMapper _mapper;

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

      final packs = <PackRevisionDto>[];
      final packValues = _list(object, 'packs', r'$.packs');
      for (var index = 0; index < packValues.length; index += 1) {
        final path = '\$.packs[$index]';
        final pack = _object(packValues[index], path);
        packs.add(
          PackRevisionDto(
            code: _string(pack, 'code', '$path.code'),
            variant: _string(pack, 'variant', '$path.variant'),
            revision: _integer(pack, 'revision', '$path.revision'),
            checksum: _string(pack, 'checksum', '$path.checksum'),
          ),
        );
      }

      final practiceTests = <PracticeTestRevisionDto>[];
      final practiceTestValues = _list(
        object,
        'practiceTests',
        r'$.practiceTests',
      );
      for (var index = 0; index < practiceTestValues.length; index += 1) {
        final path = '\$.practiceTests[$index]';
        final test = _object(practiceTestValues[index], path);
        practiceTests.add(
          PracticeTestRevisionDto(
            practiceTestCode: _businessCode(
              test,
              'practiceTestCode',
              '$path.practiceTestCode',
            ),
            revision: _integer(test, 'revision', '$path.revision'),
            checksum: _string(test, 'checksum', '$path.checksum'),
          ),
        );
      }

      final catalogues = <CatalogueRevisionDto>[];
      final catalogueValues = _list(object, 'catalogues', r'$.catalogues');
      for (var index = 0; index < catalogueValues.length; index += 1) {
        final path = '\$.catalogues[$index]';
        final catalogue = _object(catalogueValues[index], path);
        catalogues.add(
          CatalogueRevisionDto(
            kind: _string(catalogue, 'kind', '$path.kind'),
            revision: _integer(catalogue, 'revision', '$path.revision'),
            checksum: _string(catalogue, 'checksum', '$path.checksum'),
          ),
        );
      }

      final localeFallbacks = <LocaleFallbackRuleDto>[];
      final fallbackValues = object.containsKey('localeFallbacks')
          ? _list(object, 'localeFallbacks', r'$.localeFallbacks')
          : const <Object?>[];
      for (var index = 0; index < fallbackValues.length; index += 1) {
        final path = '\$.localeFallbacks[$index]';
        final rule = _object(fallbackValues[index], path);
        final values = _list(rule, 'fallbackLocales', '$path.fallbackLocales');
        final fallbacks = <String>[];
        for (
          var fallbackIndex = 0;
          fallbackIndex < values.length;
          fallbackIndex += 1
        ) {
          final fallbackPath = '$path.fallbackLocales[$fallbackIndex]';
          final value = values[fallbackIndex];
          if (value is! String || !_localePattern.hasMatch(value.trim())) {
            throw _ContractViolation(
              fallbackPath,
              'must be a BCP-47-compatible locale',
            );
          }
          fallbacks.add(value.trim());
        }
        localeFallbacks.add(
          LocaleFallbackRuleDto(
            locale: _locale(rule, 'locale', '$path.locale'),
            fallbackLocales: List<String>.unmodifiable(fallbacks),
          ),
        );
      }

      final tombstones = <ContentTombstoneDto>[];
      final tombstoneValues = _list(object, 'tombstones', r'$.tombstones');
      for (var index = 0; index < tombstoneValues.length; index += 1) {
        final path = '\$.tombstones[$index]';
        final tombstone = _object(tombstoneValues[index], path);
        final contentType = _contentType(tombstone, path);
        tombstones.add(
          ContentTombstoneDto(
            contentCode: _contentCode(tombstone, path),
            contentType: contentType,
            revision: _integer(tombstone, 'revision', '$path.revision'),
            reason: _string(tombstone, 'reason', '$path.reason'),
          ),
        );
      }

      final dto = RootContentManifestDto(
        schemaVersion: schemaVersion,
        contentVersion: _integer(object, 'contentVersion', r'$.contentVersion'),
        minimumAppContractVersion: minimumAppContractVersion,
        publishedAt: _utcDateTime(object, 'publishedAt', r'$.publishedAt'),
        checksum: _string(object, 'checksum', r'$.checksum'),
        packs: packs,
        practiceTests: practiceTests,
        catalogues: catalogues,
        localeFallbacks: localeFallbacks,
        tombstones: tombstones,
      );
      return Success<RootContentManifest>(_mapper.mapRoot(dto));
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

      final contents = <PackContentRefDto>[];
      final contentValues = _list(object, 'contents', r'$.contents');
      for (var index = 0; index < contentValues.length; index += 1) {
        final path = '\$.contents[$index]';
        final content = _object(contentValues[index], path);
        final contentType = _contentType(content, path);
        contents.add(
          PackContentRefDto(
            contentCode: _contentCode(content, path),
            contentType: contentType,
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

      final localizations = <LocalizedContentRefDto>[];
      final localizationValues = _list(
        object,
        'localizations',
        r'$.localizations',
      );
      for (var index = 0; index < localizationValues.length; index += 1) {
        final path = '\$.localizations[$index]';
        final localization = _object(localizationValues[index], path);
        localizations.add(
          LocalizedContentRefDto(
            contentCode: _contentCode(localization, path),
            contentType: _contentType(localization, path),
            contentRevision: _integer(
              localization,
              'contentRevision',
              '$path.contentRevision',
            ),
            locale: _locale(localization, 'locale', '$path.locale'),
            localizationRevision: _integer(
              localization,
              'localizationRevision',
              '$path.localizationRevision',
            ),
            checksum: _string(localization, 'checksum', '$path.checksum'),
          ),
        );
      }

      final assets = <ManifestAssetDescriptorDto>[];
      final assetValues = _list(object, 'assets', r'$.assets');
      for (var index = 0; index < assetValues.length; index += 1) {
        final path = '\$.assets[$index]';
        final asset = _object(assetValues[index], path);
        assets.add(
          ManifestAssetDescriptorDto(
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

      final contentAssets = <ContentAssetRefDto>[];
      final contentAssetValues = _list(
        object,
        'contentAssets',
        r'$.contentAssets',
      );
      for (var index = 0; index < contentAssetValues.length; index += 1) {
        final path = '\$.contentAssets[$index]';
        final ref = _object(contentAssetValues[index], path);
        final contentType = _contentType(ref, path);
        contentAssets.add(
          ContentAssetRefDto(
            contentCode: _contentCode(ref, path),
            contentType: contentType,
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

      final dto = PackContentManifestDto(
        schemaVersion: schemaVersion,
        code: _string(object, 'code', r'$.code'),
        variant: _string(object, 'variant', r'$.variant'),
        revision: _integer(object, 'revision', r'$.revision'),
        checksum: _string(object, 'checksum', r'$.checksum'),
        contents: contents,
        localizations: localizations,
        assets: assets,
        contentAssets: contentAssets,
      );
      return Success<PackContentManifest>(_mapper.mapPack(dto));
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

  String _businessCode(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final code = _string(object, key, path);
    if (!_contentCodePattern.hasMatch(code)) {
      throw _ContractViolation(path, 'must be a stable business code');
    }
    return code;
  }

  String _contentCode(Map<String, Object?> object, String path) {
    return _businessCode(object, 'contentCode', '$path.contentCode');
  }

  String _contentType(Map<String, Object?> object, String path) {
    final typeName = _string(object, 'contentType', '$path.contentType');
    if (contentTypeFromWireName(typeName) == null) {
      throw _ContractViolation(
        '$path.contentType',
        'contains an unsupported content type',
      );
    }
    return typeName;
  }

  String _locale(Map<String, Object?> object, String key, String path) {
    final locale = _string(object, key, path);
    if (!_localePattern.hasMatch(locale)) {
      throw _ContractViolation(path, 'must be a BCP-47-compatible locale');
    }
    return locale;
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
final _localePattern = RegExp(r'^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$');
final _utcTimestampPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?Z$',
);

final class _ContractViolation implements Exception {
  const _ContractViolation(this.path, this.reason);

  final String path;
  final String reason;
}
