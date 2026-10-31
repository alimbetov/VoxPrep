from pathlib import Path

path = Path('mobile/careerspeak_app/lib/application/content_delivery/content_manifest.dart')
text = path.read_text()
text = text.replace(
    "locale: _requireLocale(locale, 'locale'),",
    "locale: _canonicalizeLocale(locale, 'locale'),",
    1,
)
old = """  final locale = normalized.substring('locale:'.length);
  _requireLocale(locale, 'variant');
  return normalized;
"""
new = """  final locale = normalized.substring('locale:'.length);
  return 'locale:${_canonicalizeLocale(locale, 'variant')}';
"""
if new not in text:
    if old not in text:
        raise SystemExit('missing pack variant locale canonicalization anchor')
    text = text.replace(old, new, 1)
path.write_text(text)
