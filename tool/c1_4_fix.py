from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    if old not in text:
        raise SystemExit(f'missing analyzer-fix anchor in {path}: {old[:200]}')
    p.write_text(text.replace(old, new, 1))


replace_once(
    'mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart',
    """    LocalizedContentPayloadGateway? localizedPayloadGateway,
    DateTime Function()? now,
  }) : _localizedPayloadGateway = localizedPayloadGateway,
       _now = now ?? (() => DateTime.now().toUtc());
""",
    """    this._localizedPayloadGateway,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());
""",
)

replace_once(
    'mobile/careerspeak_app/test/data/local/drift_sync_plan_executor_test.dart',
    """  Future<Result<RootManifestFetch>> fetchRootManifest({
    required String translationLocale,
    String? etag,
  }) async {
""",
    """  Future<Result<RootManifestFetch>> fetchRootManifest({
    String? etag,
  }) async {
""",
)

p = Path('mobile/careerspeak_app/lib/domain/application_preferences.dart')
text = p.read_text()
if not text.startswith('// ignore_for_file: use_super_parameters'):
    text = '// ignore_for_file: use_super_parameters\n\n' + text
p.write_text(text)

p = Path('mobile/careerspeak_app/test/architecture/motion_boundary_test.dart')
text = p.read_text().replace('source.contains("../motion/")', "source.contains('../motion/')")
text = text.replace('source.contains("../../motion/")', "source.contains('../../motion/')")
p.write_text(text)
