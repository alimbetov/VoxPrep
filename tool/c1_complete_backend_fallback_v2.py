from pathlib import Path

source_path = Path('tool/c1_complete_backend_fallback.py')
source = source_path.read_text()

start_marker = "materializer = 'mobile/careerspeak_app/lib/application/content_sync/root_manifest_materializer.dart'"
end_marker = "api = 'contracts/learner-api-v1.yaml'"
start = source.find(start_marker)
end = source.find(end_marker, start)
if start < 0 or end < 0:
    raise SystemExit('unable to isolate obsolete materializer patch block')

source = source[:start] + source[end:]
exec(compile(source, str(source_path), 'exec'))
