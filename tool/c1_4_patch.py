from pathlib import Path


def replace_once(text: str, old: str, new: str) -> str:
    if old not in text:
        raise SystemExit(f"missing patch anchor:\n{old[:400]}")
    return text.replace(old, new, 1)


p = Path('mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart')
s = p.read_text()

s = replace_once(
    s,
    "import '../../application/content_delivery/content_payload.dart';\n",
    "import '../../application/content_delivery/content_payload.dart';\n"
    "import '../../application/content_delivery/localized_content_payload.dart';\n",
)
s = replace_once(
    s,
    "import '../../application/ports/content_payload_gateway.dart';\n",
    "import '../../application/ports/content_payload_gateway.dart';\n"
    "import '../../application/ports/localized_content_payload_gateway.dart';\n",
)
s = replace_once(
    s,
    """    this._payloadGateway, {
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final ContentManifestGateway _manifestGateway;
  final ContentPayloadGateway _payloadGateway;
  final DateTime Function() _now;
""",
    """    this._payloadGateway, {
    LocalizedContentPayloadGateway? localizedPayloadGateway,
    DateTime Function()? now,
  }) : _localizedPayloadGateway = localizedPayloadGateway,
       _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final ContentManifestGateway _manifestGateway;
  final ContentPayloadGateway _payloadGateway;
  final LocalizedContentPayloadGateway? _localizedPayloadGateway;
  final DateTime Function() _now;
""",
)
s = replace_once(
    s,
    """        await _setPackState(runId, target, SyncPackUpdateState.stagingMetadata);
        await _stagePack(
          plan: plan,
          target: target,
          manifest: manifest,
          payloads: (payloadResult as Success<List<ContentPayload>>).value,
        );
""",
    """        final localizedPayloadResult = await _fetchLocalizedPayloads(manifest);
        if (localizedPayloadResult
            case FailureResult<List<LocalizedContentPayload>>(:final failure)) {
          return FailureResult(failure);
        }

        await _setPackState(runId, target, SyncPackUpdateState.stagingMetadata);
        await _stagePack(
          plan: plan,
          target: target,
          manifest: manifest,
          payloads: (payloadResult as Success<List<ContentPayload>>).value,
          localizedPayloads:
              (localizedPayloadResult as Success<List<LocalizedContentPayload>>)
                  .value,
        );
""",
)

stage_anchor = "  Future<void> _stagePack({\n"
localized_fetch_method = """  Future<Result<List<LocalizedContentPayload>>> _fetchLocalizedPayloads(
    PackContentManifest manifest,
  ) async {
    if (manifest.localizations.isEmpty) {
      return const Success<List<LocalizedContentPayload>>(
        <LocalizedContentPayload>[],
      );
    }
    final gateway = _localizedPayloadGateway;
    if (gateway == null) {
      return const FailureResult<List<LocalizedContentPayload>>(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_GATEWAY_MISSING',
          message: 'Localized payload references require a localized payload gateway.',
        ),
      );
    }

    final payloads = <LocalizedContentPayload>[];
    for (final target in manifest.localizations) {
      final fetched = await gateway.fetch(target);
      if (fetched case FailureResult<LocalizedContentPayload>(:final failure)) {
        return FailureResult<List<LocalizedContentPayload>>(failure);
      }
      final payload = (fetched as Success<LocalizedContentPayload>).value;
      if (!_sameLocalizedPayloadTarget(payload.ref, target)) {
        return FailureResult<List<LocalizedContentPayload>>(
          ApplicationFailure(
            code: 'LOCALIZED_CONTENT_PAYLOAD_MISMATCH',
            message: 'The fetched localized payload does not match the pack manifest.',
            details: <String, Object?>{
              'contentCode': target.identity.code,
              'contentType': target.identity.type.name,
              'contentRevision': target.contentRevision,
              'locale': target.locale,
              'localizationRevision': target.localizationRevision,
            },
          ),
        );
      }
      payloads.add(payload);
    }
    return Success<List<LocalizedContentPayload>>(
      List<LocalizedContentPayload>.unmodifiable(payloads),
    );
  }

"""
if stage_anchor not in s:
    raise SystemExit('stage anchor missing')
s = s.replace(stage_anchor, localized_fetch_method + stage_anchor, 1)

s = replace_once(
    s,
    """    required PackContentManifest manifest,
    required List<ContentPayload> payloads,
  }) async {
""",
    """    required PackContentManifest manifest,
    required List<ContentPayload> payloads,
    required List<LocalizedContentPayload> localizedPayloads,
  }) async {
""",
)
s = replace_once(
    s,
    """    if (target.identity.variant == 'canonical' &&
        payloadByKey.length != manifest.contents.length) {
""",
    """    final localizedPayloadByKey = <String, LocalizedContentPayload>{
      for (final payload in localizedPayloads)
        _localizationKey(payload.ref): payload,
    };
    if (localizedPayloadByKey.length != manifest.localizations.length) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_PAYLOAD_SET_MISMATCH',
          message: 'The staged localized payload set is incomplete or duplicated.',
        ),
      );
    }

    if (target.identity.variant == 'canonical' &&
        payloadByKey.length != manifest.contents.length) {
""",
)
s = replace_once(
    s,
    """      await (_database.delete(_database.packAssetRefs)..where(
""",
    """      await (_database.delete(_database.packLocalizationRefs)..where(
            (row) =>
                row.packCode.equals(target.identity.code) &
                row.variantKey.equals(target.identity.variant) &
                row.packRevision.equals(target.revision),
          ))
          .go();
      await (_database.delete(_database.packAssetRefs)..where(
""",
)
s = replace_once(
    s,
    """      for (final asset in manifest.assets) {
""",
    """      for (final localization in manifest.localizations) {
        final payload = localizedPayloadByKey[_localizationKey(localization)];
        if (payload == null || payload.ref.checksum != localization.checksum) {
          throw const _SyncExecutorInvariant(
            ApplicationFailure(
              code: 'LOCALIZED_CONTENT_PAYLOAD_SET_MISMATCH',
              message: 'A locale pack reference has no exact staged localized payload.',
            ),
          );
        }
        await _ensureLocalizedContentRead(payload, now);
        await _database.into(_database.packLocalizationRefs).insert(
              PackLocalizationRefsCompanion.insert(
                packCode: target.identity.code,
                variantKey: target.identity.variant,
                packRevision: target.revision,
                contentCode: localization.identity.code,
                contentType: _contentTypeToStorage(localization.identity.type),
                contentRevision: localization.contentRevision,
                locale: localization.locale,
                localizationRevision: localization.localizationRevision,
                checksum: localization.checksum,
              ),
            );
      }

      for (final asset in manifest.assets) {
""",
)

asset_anchor = "  Future<void> _ensureAsset(ManifestAssetDescriptor asset, DateTime now) async {\n"
localized_ensure_method = """  Future<void> _ensureLocalizedContentRead(
    LocalizedContentPayload payload,
    DateTime now,
  ) async {
    final ref = payload.ref;
    final type = _contentTypeToStorage(ref.identity.type);
    final existing =
        await (_database.select(_database.localizedContentReads)..where(
              (row) =>
                  row.contentCode.equals(ref.identity.code) &
                  row.contentType.equals(type) &
                  row.contentRevision.equals(ref.contentRevision) &
                  row.locale.equals(ref.locale) &
                  row.localizationRevision.equals(ref.localizationRevision),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await _database.into(_database.localizedContentReads).insert(
            LocalizedContentReadsCompanion.insert(
              contentCode: ref.identity.code,
              contentType: type,
              contentRevision: ref.contentRevision,
              locale: ref.locale,
              localizationRevision: ref.localizationRevision,
              checksum: ref.checksum,
              title: Value(payload.title),
              subtitle: Value(payload.subtitle),
              description: Value(payload.description),
              translation: Value(payload.translation),
              hint: Value(payload.hint),
              explanation: Value(payload.explanation),
              createdAt: now,
            ),
          );
      return;
    }
    if (existing.checksum != ref.checksum ||
        existing.title != payload.title ||
        existing.subtitle != payload.subtitle ||
        existing.description != payload.description ||
        existing.translation != payload.translation ||
        existing.hint != payload.hint ||
        existing.explanation != payload.explanation) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_PAYLOAD_IMMUTABLE_CONFLICT',
          message: 'A persisted localized payload conflicts with its immutable revision.',
        ),
      );
    }
  }

"""
if asset_anchor not in s:
    raise SystemExit('asset anchor missing')
s = s.replace(asset_anchor, localized_ensure_method + asset_anchor, 1)

marker = "      for (final tombstone in plan.tombstones) {\n"
validation = """      for (final target in plan.target.packs) {
        final localizationRefs =
            await (_database.select(_database.packLocalizationRefs)..where(
                  (row) =>
                      row.packCode.equals(target.identity.code) &
                      row.variantKey.equals(target.identity.variant) &
                      row.packRevision.equals(target.revision),
                ))
                .get();
        for (final ref in localizationRefs) {
          final payload =
              await (_database.select(_database.localizedContentReads)..where(
                    (row) =>
                        row.contentCode.equals(ref.contentCode) &
                        row.contentType.equals(ref.contentType) &
                        row.contentRevision.equals(ref.contentRevision) &
                        row.locale.equals(ref.locale) &
                        row.localizationRevision.equals(ref.localizationRevision),
                  ))
                  .getSingleOrNull();
          if (payload == null) {
            throw const _SyncExecutorInvariant(
              ApplicationFailure(
                code: 'SYNC_TARGET_LOCALIZATION_MISSING',
                message: 'A target locale pack is missing an exact localized payload.',
              ),
            );
          }
          if (payload.checksum != ref.checksum) {
            throw const _SyncExecutorInvariant(
              ApplicationFailure(
                code: 'SYNC_TARGET_LOCALIZATION_MISMATCH',
                message: 'A target localized payload does not match pack metadata.',
              ),
            );
          }
        }
      }

"""
if marker not in s:
    raise SystemExit('tombstone marker missing')
s = s.replace(marker, validation + marker, 1)

s = replace_once(
    s,
    "bool _sameOptionalInstant(DateTime? left, DateTime? right) {\n",
    """bool _sameLocalizedPayloadTarget(
  LocalizedContentRef left,
  LocalizedContentRef right,
) {
  return left.identity == right.identity &&
      left.contentRevision == right.contentRevision &&
      left.locale == right.locale &&
      left.localizationRevision == right.localizationRevision &&
      left.checksum == right.checksum;
}

String _localizationKey(LocalizedContentRef ref) =>
    '${ref.identity.code}|${ref.identity.type.name}|${ref.contentRevision}|${ref.locale}|${ref.localizationRevision}';

bool _sameOptionalInstant(DateTime? left, DateTime? right) {
""",
)
p.write_text(s)

# Database acceptance follows schema v5 and must see both localization tables.
p = Path('mobile/careerspeak_app/test/data/local/database/careerspeak_database_test.dart')
s = p.read_text()
s = s.replace('schema version 4 creates', 'schema version 5 creates')
s = s.replace('expect(database.schemaVersion, 4);', 'expect(database.schemaVersion, 5);')
s = s.replace("expect(userVersion.read<int>('user_version'), 4);", "expect(userVersion.read<int>('user_version'), 5);")
s = s.replace("        'pack_content_refs',\n", "        'pack_content_refs',\n        'pack_localization_refs',\n")
s = s.replace("        'content_catalog_reads',\n", "        'content_catalog_reads',\n        'localized_content_reads',\n")
p.write_text(s)

# Update generated-baseline gate from v4 dump to v5, while retaining historical v4.
p = Path('.github/workflows/flutter-production-adapters.yml')
s = p.read_text()
s = s.replace(
    '            lib/data/local/database/careerspeak_database.dart \\\n            drift_schemas/drift_schema_v4.json',
    '            lib/data/local/database/careerspeak_database.dart \\\n            drift_schemas/drift_schema_v5.json',
)
s = s.replace(
    '            drift_schemas/drift_schema_v4.json \\\n            test/generated_migrations',
    '            drift_schemas/drift_schema_v4.json \\\n            drift_schemas/drift_schema_v5.json \\\n            test/generated_migrations',
)
p.write_text(s)
