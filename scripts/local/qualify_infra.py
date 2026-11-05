"""Real DEV SQL/S3 and nondestructive restart qualification; standard library only."""
import datetime as dt
import hashlib
import hmac
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import urllib.request
import urllib.error
import uuid

ROOT = Path(__file__).resolve().parents[2]
COMPOSE = ['docker', 'compose', '--env-file', str(ROOT / 'infra/env/dev.env.example'),
           '-f', str(ROOT / 'infra/compose/compose.dev.yml')]
stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
OUT = ROOT / 'artifacts/local-smoke' / ('a1-' + stamp)
OUT.mkdir(parents=True, exist_ok=False)
report = {'timestamp': stamp, 'platform': platform.platform(), 'checks': []}


def run(command, data=None, expected=0):
    result = subprocess.run(command, input=data, text=True, capture_output=True, timeout=180, cwd=ROOT)
    record = {'command': command, 'timestamp': dt.datetime.now(dt.timezone.utc).isoformat(),
              'exit_code': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}
    if data is not None:
        record['stdin'] = data
    report['checks'].append(record)
    if result.returncode != expected:
        raise RuntimeError(f'Unexpected exit {result.returncode}: {command[0]} (see evidence)')
    return result.stdout.strip()


def sql(role, query, denied=False):
    # Secrets are read inside the container; never put credential values in argv/evidence.
    script = f'export PGPASSWORD="$(cat /run/secrets/postgres_{role}_password)"; exec psql -h 127.0.0.1 -U voxprep_{role} -d voxprep_dev -At -v ON_ERROR_STOP=1 -v VERBOSITY=verbose'
    output = run(COMPOSE + ['exec', '-T', 'postgres', 'sh', '-eu', '-c', script], query, 3 if denied else 0)
    if denied and '42501' not in report['checks'][-1]['stderr']:
        raise RuntimeError('Expected SQLSTATE 42501 permission denied')
    return output


def sign(key, message):
    return hmac.new(key, message.encode(), hashlib.sha256).digest()


def s3(method, path, body=b''):
    secrets = ROOT / 'infra/secrets/dev'
    access = (secrets / 'rustfs_backend_access_key').read_text().strip()
    secret = (secrets / 'rustfs_backend_secret_key').read_text().strip()
    now = dt.datetime.now(dt.timezone.utc)
    date, timestamp = now.strftime('%Y%m%d'), now.strftime('%Y%m%dT%H%M%SZ')
    host = '127.0.0.1:19000'
    digest = hashlib.sha256(body).hexdigest()
    headers = {'host': host, 'x-amz-content-sha256': digest, 'x-amz-date': timestamp}
    names = ';'.join(sorted(headers))
    canonical = method + '\n' + path + '\n\n' + ''.join(k + ':' + headers[k] + '\n' for k in sorted(headers)) + '\n' + names + '\n' + digest
    scope = date + '/us-east-1/s3/aws4_request'
    to_sign = 'AWS4-HMAC-SHA256\n' + timestamp + '\n' + scope + '\n' + hashlib.sha256(canonical.encode()).hexdigest()
    key = sign(sign(sign(sign(('AWS4' + secret).encode(), date), 'us-east-1'), 's3'), 'aws4_request')
    signature = hmac.new(key, to_sign.encode(), hashlib.sha256).hexdigest()
    headers['Authorization'] = f'AWS4-HMAC-SHA256 Credential={access}/{scope}, SignedHeaders={names}, Signature={signature}'
    request = urllib.request.Request('http://' + host + path, data=body if method == 'PUT' else None, headers=headers, method=method)
    with urllib.request.urlopen(request, timeout=20) as response:
        data = response.read()
        report['checks'].append({'command': ['S3', method, path, '(backend IAM, SigV4)'],
                                 'timestamp': timestamp, 'exit_code': 0, 'http_status': response.status,
                                 'sha256': hashlib.sha256(data).hexdigest()})
        return data


token = uuid.uuid4().hex
table = 'local_smoke_' + token
path = '/voxprep-assets/staging/local-smoke/' + token
payload = ('voxprep-persistence-' + token).encode()
created_table = created_object = False
try:
    report['sha'] = run(['git', 'rev-parse', 'HEAD'])
    dirty = run(['git', 'status', '--porcelain'])
    if dirty:
        raise RuntimeError('Qualification requires a clean committed checkout')
    report['images'] = run(['docker', 'image', 'inspect', 'postgres:18.6-bookworm', 'rustfs/rustfs:1.0.4',
                            '--format', '{{.RepoDigests}} {{.Os}}/{{.Architecture}}'])
    run([str(ROOT / 'scripts/local/smoke-infra.sh')])
    report['compose_status'] = run(COMPOSE + ['ps', '-a'])
    s3('PUT', path, payload)
    created_object = True
    assert s3('GET', path) == payload, 'S3 bytes differ before restart'
    report['payload_sha256'] = hashlib.sha256(payload).hexdigest()
    sql('migrator', f'CREATE TABLE app.{table}(value text NOT NULL); INSERT INTO app.{table} VALUES (\'{token}\');')
    created_table = True
    assert sql('backend', f'SELECT value FROM app.{table};') == token
    sql('backend', f'BEGIN; ALTER TABLE app.{table} ADD COLUMN forbidden int; ROLLBACK;', denied=True)
    sql('backend', f'BEGIN; CREATE TABLE app.{table}_denied(id int); ROLLBACK;', denied=True)
    run(COMPOSE + ['restart', '--timeout', '30', 'postgres', 'rustfs'])
    run(COMPOSE + ['up', '-d', '--wait', '--wait-timeout', '120', 'postgres', 'rustfs'])
    assert sql('backend', f'SELECT value FROM app.{table};') == token
    assert s3('GET', path) == payload, 'S3 bytes differ after restart'
    report['infrastructure'] = 'PASS'
    # The post-Liquibase gate is explicit; infrastructure can run independently.
    if '--migrations' in sys.argv:
        count = sql('migrator', 'SELECT count(*) FROM liquibase.databasechangelog;')
        assert int(count) > 0, 'No Liquibase changesets found'
        report['liquibase_changesets'] = int(count)
        owners = sql('migrator', "SELECT DISTINCT tableowner FROM pg_tables WHERE schemaname IN ('app','liquibase');")
        assert 'voxprep_backend' not in owners
        report['table_owners'] = owners
        sql('backend', 'BEGIN; ALTER TABLE app.content_revision ADD COLUMN local_smoke_forbidden int; ROLLBACK;', denied=True)
        report['backend_sessions'] = sql('migrator', "SELECT usename || ':' || count(*) FROM pg_stat_activity WHERE datname = current_database() GROUP BY usename ORDER BY usename;")
        sql('backend', 'BEGIN; SELECT count(*) FROM liquibase.databasechangelog; ROLLBACK;', denied=True)
        sql('backend', 'BEGIN; ALTER TABLE liquibase.databasechangelog ADD COLUMN forbidden int; ROLLBACK;', denied=True)
        report['migration_boundary'] = 'PASS'
    else:
        report['migration_boundary'] = 'NOT RUN'
    report['status'] = 'PASS'
except Exception as error:
    report['status'] = 'FAIL'
    # Exception text deliberately excludes HTTP headers and credential values.
    report['error'] = str(error)
finally:
    try:
        if created_object:
            s3('DELETE', path)
            try:
                s3('GET', path)
                raise RuntimeError('Deleted S3 object still exists')
            except urllib.error.HTTPError as error:
                if error.code != 404:
                    raise
                report['checks'].append({'command': ['S3', 'GET', path, '(verify deletion)'],
                                         'timestamp': dt.datetime.now(dt.timezone.utc).isoformat(),
                                         'exit_code': 0, 'http_status': 404})
        if created_table:
            sql('migrator', f'DROP TABLE app.{table};')
    except Exception as error:
        report['status'] = 'FAIL'
        report['cleanup_error'] = str(error)
    (OUT / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'{report["status"]}: {OUT / "report.json"}')
sys.exit(0 if report['status'] == 'PASS' else 1)
