"""Collect bounded, secret-free A0 evidence without changing services or SDKs."""
import datetime
import json
import pathlib
import subprocess

root = pathlib.Path(__file__).resolve().parents[2]
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
destination = root / 'artifacts/local-smoke' / stamp
destination.mkdir(parents=True, exist_ok=False)
commands = [
    ['git', 'rev-parse', 'HEAD'], ['git', 'status', '--short'],
    ['uname', '-m'], ['sw_vers'], ['sysctl', '-n', 'hw.memsize'],
    ['df', '-h', '.'], ['git', '--version'], ['docker', 'version'],
    ['docker', 'compose', 'version'],
    ['docker', 'ps', '--format', '{{.Names}}\t{{.Image}}\t{{.Ports}}'],
    ['docker', 'volume', 'ls'], ['java', '-version'], ['mvn', '-version'],
    ['python3', '--version'], ['flutter', 'doctor', '-v'],
    ['xcodebuild', '-version'], ['xcrun', 'simctl', 'list', 'devices', 'available'],
    ['pod', '--version'],
    ['lsof', '-nP', '-iTCP:5432', '-iTCP:9000', '-iTCP:9001', '-iTCP:8080', '-sTCP:LISTEN'],
]
results = []
for index, command in enumerate(commands):
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    try:
        result = subprocess.run(command, cwd=root, capture_output=True, text=True, timeout=45)
        code, output = result.returncode, result.stdout + result.stderr
    except FileNotFoundError as error:
        code, output = 127, str(error)
    except subprocess.TimeoutExpired as error:
        code = 124
        output = (error.stdout or b'') + (error.stderr or b'')
        if isinstance(output, bytes):
            output = output.decode(errors='replace')
        output += '\nProbe timed out after 45 seconds.'
    filename = f'{index:02d}-{command[0]}.log'
    (destination / filename).write_text(output)
    results.append(dict(command=command, timestamp=started, exit_code=code, evidence=filename))
    print(f'{code:3} {" ".join(command)}', flush=True)
(destination / 'index.json').write_text(json.dumps(results, indent=2) + '\n')
print(f'Evidence: {destination}')
