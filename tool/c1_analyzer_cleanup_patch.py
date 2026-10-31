from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing analyzer cleanup anchor in {path}: {old}')
    file.write_text(text.replace(old, new, 1))


def remove_once(path: str, value: str) -> None:
    file = Path(path)
    text = file.read_text()
    if value not in text:
        return
    file.write_text(text.replace(value, '', 1))


# Keep Flutter matcher names unambiguous when Drift exports SQL predicates.
replace_once(
    'mobile/careerspeak_app/test/acceptance/c1_localization_recovery_acceptance_test.dart',
    "import 'package:drift/drift.dart';",
    "import 'package:drift/drift.dart' hide isNotNull, isNull;",
)
replace_once(
    'mobile/careerspeak_app/test/data/local/drift_locale_fallback_policy_test.dart',
    "import 'package:drift/drift.dart';",
    "import 'package:drift/drift.dart' hide isNotNull, isNull;",
)
replace_once(
    'mobile/careerspeak_app/test/data/local/drift_localized_content_repository_test.dart',
    "import 'package:drift/drift.dart' hide isNotNull;",
    "import 'package:drift/drift.dart' hide isNotNull, isNull;",
)

# Drift generated row classes intentionally reuse table-singular names. The
# acceptance tests need the domain manifest classes, not generated row classes.
for path in (
    'mobile/careerspeak_app/test/acceptance/c1_locale_offline_restart_acceptance_test.dart',
    'mobile/careerspeak_app/test/acceptance/c1_online_sync_offline_reopen_acceptance_test.dart',
    'mobile/careerspeak_app/test/acceptance/c1_tombstone_retirement_acceptance_test.dart',
):
    replace_once(
        path,
        "import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';",
        "import 'package:careerspeak_app/data/local/database/careerspeak_database.dart' hide PackContentRef, ContentAssetRef, LocaleFallbackRule;",
    )

# Tombstone acceptance uses Drift boolean-expression composition directly.
replace_once(
    'mobile/careerspeak_app/test/acceptance/c1_tombstone_retirement_acceptance_test.dart',
    "import 'package:drift/native.dart';",
    "import 'package:drift/drift.dart' hide isNotNull, isNull;\nimport 'package:drift/native.dart';",
)

# Locale-projection acceptance constructs RootManifestChanged explicitly.
replace_once(
    'mobile/careerspeak_app/test/application/content_sync/content_sync_locale_projection_test.dart',
    "import 'package:careerspeak_app/application/content_sync/sync_models.dart';",
    "import 'package:careerspeak_app/application/content_sync/sync_models.dart';\nimport 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';",
)

# Prefer the initializing formal in the production executor constructor.
replace_once(
    'mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart',
    "    LocalizedContentPayloadGateway? localizedPayloadGateway,\n    DateTime Function()? now,\n  }) : _localizedPayloadGateway = localizedPayloadGateway,\n       _now = now ?? (() => DateTime.now().toUtc());",
    "    this._localizedPayloadGateway,\n    DateTime Function()? now,\n  }) : _now = now ?? (() => DateTime.now().toUtc());",
)

# These imports became obsolete once the repair tests switched to direct
# repository/journal assertions.
for path in (
    'mobile/careerspeak_app/test/application/content_sync/locale_policy_repair_test.dart',
    'mobile/careerspeak_app/test/data/local/drift_locale_policy_repair_marker_test.dart',
    'mobile/careerspeak_app/test/data/local/drift_sync_locale_repair_test.dart',
):
    remove_once(
        path,
        "import 'package:careerspeak_app/application/result/result.dart';\n",
    )
