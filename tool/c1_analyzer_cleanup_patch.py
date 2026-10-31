from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing analyzer cleanup anchor in {path}: {old}')
    file.write_text(text.replace(old, new, 1))


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
