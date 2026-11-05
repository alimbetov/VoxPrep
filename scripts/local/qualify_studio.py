"""Real A2 MVC scenario. Only read-only SQL; all authoring uses HTTP forms.

DEV credentials and session/installation tokens stay in memory, never evidence.
Each run adds a uniquely named fixture; existing publication/volumes are preserved.
"""
import datetime as dt
import hashlib
import html
from html.parser import HTMLParser
from http.cookiejar import CookieJar
import json
import os
from pathlib import Path
import platform
import re
import struct
import subprocess
import traceback
import urllib.error
import urllib.parse
import urllib.request
import uuid
import xml.etree.ElementTree as ET
import zlib

ROOT = Path(__file__).resolve().parents[2]
BASE = 'http://127.0.0.1:' + os.environ.get('VOXPREP_LOCAL_BACKEND_PORT', '18081')
OUT = ROOT / 'artifacts/local-smoke' / ('a2-' + dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
OUT.mkdir(parents=True, exist_ok=False)
report = {'timestamp': dt.datetime.now(dt.timezone.utc).isoformat(), 'platform': platform.platform(),
          'gates': {f'API-0{i}': 'NOT RUN' for i in range(2, 7)}, 'operations': []}


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args):
        return None


def client():
    jar = CookieJar()
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar), NoRedirect()), jar


http, cookies = client()


class Inputs(HTMLParser):
    def __init__(self, source):
        super().__init__(); self.values = {}; self.feed(source)
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'input' and a.get('name'):
            self.values[a['name']] = a.get('value', '')
        if tag == 'meta' and a.get('name') == '_csrf':
            self.values['_csrf'] = a['content']


def digest(data):
    return hashlib.sha256(data).hexdigest()


def request(path, method='GET', fields=None, file=None, token=None, expected=200, opener=None, secret=False, json_body=None):
    headers = {}; data = None
    if token: headers['X-CSRF-TOKEN'] = token
    if fields is not None:
        data = urllib.parse.urlencode(fields).encode(); headers['Content-Type'] = 'application/x-www-form-urlencoded'
    if json_body is not None:
        data = json.dumps(json_body).encode(); headers['Content-Type'] = 'application/json'
    if file:
        boundary = 'VoxPrep' + uuid.uuid4().hex
        parts = []
        for k, v in (fields or {}).items():
            parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
        name, mime, content = file
        parts.extend([f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{name}"\r\nContent-Type: {mime}\r\n\r\n'.encode(), content, f'\r\n--{boundary}--\r\n'.encode()])
        data = b''.join(parts); headers['Content-Type'] = 'multipart/form-data; boundary=' + boundary
    if opener is learner:
        headers['Authorization'] = 'Bearer ' + installation_token
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        response = (opener or http).open(req, timeout=30)
    except urllib.error.HTTPError as error:
        response = error
    body = response.read(); status = response.code
    record = {'timestamp': dt.datetime.now(dt.timezone.utc).isoformat(), 'method': method, 'path': path,
              'status': status, 'expected': expected, 'sha': report['sha']}
    for key in ('Location', 'ETag', 'Content-Type', 'Content-Disposition'):
        if response.headers.get(key): record[key] = response.headers[key]
    if fields is not None and not secret: record['fields'] = fields
    if file: record['upload'] = {'name': file[0], 'sha256': digest(file[2])}
    if not secret:
        safe = body
        if 'text/html' in response.headers.get('Content-Type', ''):
            text = body.decode()
            text = re.sub(r'(<(?:input|meta)\b[^>]*\bname="_csrf"[^>]*\b(?:value|content)=")[^"]*', r'\1[REDACTED]', text)
            safe = text.encode()
        suffix = '.html' if 'text/html' in response.headers.get('Content-Type', '') else '.body'
        filename = f'{len(report["operations"]):03d}-{method}{suffix}'
        (OUT / filename).write_bytes(safe)
        record.update(evidence=filename, sha256=digest(safe))
    report['operations'].append(record)
    assert status == expected, f'{method} {path}: HTTP {status}, expected {expected}; see {OUT}'
    return body, response.headers


learner, _ = client()
installation_token = None


def page(path):
    return request(path)[0].decode()


def csrf(source):
    return Inputs(source).values['_csrf']


def post(path, fields=None, source=None, file=None, expected=302):
    return request(path, 'POST', fields if fields is not None else {}, file, csrf(source or page('/admin')), expected)


def sql(query):
    assert query.lstrip().upper().startswith('SELECT'), 'Read-only SQL only'
    command = ['docker', 'compose', '--env-file', str(ROOT / 'infra/env/dev.env.example'), '-f', str(ROOT / 'infra/compose/compose.dev.yml'),
               'exec', '-T', 'postgres', 'sh', '-eu', '-c',
               'export PGPASSWORD="$(cat /run/secrets/postgres_backend_password)"; exec psql -h 127.0.0.1 -U voxprep_backend -d voxprep_dev -At -v ON_ERROR_STOP=1']
    result = subprocess.run(command, input=query, text=True, capture_output=True, timeout=20)
    report['operations'].append({'timestamp':dt.datetime.now(dt.timezone.utc).isoformat(), 'command':command,
                                 'stdin':query, 'exit_code':result.returncode, 'stdout':result.stdout, 'stderr':result.stderr})
    assert result.returncode == 0, 'SQL assertion query failed'
    return result.stdout.strip()


def state():
    return sql("SELECT json_build_object('revisions',(SELECT count(*) FROM app.content_revision),'releases',(SELECT count(*) FROM app.publication_release),'current',(SELECT release_id FROM app.publication_current))::text;")


def png():
    def chunk(kind, data):
        return struct.pack('!I',len(data)) + kind + data + struct.pack('!I',zlib.crc32(kind+data)&0xffffffff)
    rows = b''.join(b'\x00' + bytes([25, 95+y, 180])*64 for y in range(64))
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR',struct.pack('!2I5B',64,64,8,2,0,0,0)) + chunk(b'IDAT',zlib.compress(rows)) + chunk(b'IEND',b'')


def canonical(body, kind):
    keys = {'ROOT':['schemaVersion','contentVersion','minimumAppContractVersion','publishedAt','packs','practiceTests','catalogues','localeFallbacks','tombstones'],
            'PACK':['schemaVersion','code','variant','revision','contents','localizations','assets','contentAssets'],
            'CATALOGUE':['kind','revision','items']}[kind]
    projected = {k:body[k] for k in keys}
    nested = {'ROOT':{'packs':['code','variant','revision','checksum'],'practiceTests':['practiceTestCode','revision','checksum'],
                      'catalogues':['kind','revision','checksum'],'localeFallbacks':['locale','fallbackLocales'],
                      'tombstones':['contentCode','contentType','revision','reason']},
              'PACK':{'contents':['contentCode','contentType','revision','checksum','sortOrder','publishedAt'],
                      'localizations':['contentCode','contentType','contentRevision','locale','localizationRevision','checksum'],
                      'assets':['assetId','checksumSha256','deliveryKey','sizeBytes','mediaType','requiredOffline'],
                      'contentAssets':['contentCode','contentType','contentRevision','assetId','role']}, 'CATALOGUE':{}}[kind]
    for key, order in nested.items(): projected[key] = [{k:item[k] for k in order} for item in body[key]]
    return digest(json.dumps(projected,ensure_ascii=False,separators=(',',':')).encode())


try:
    report['sha'] = subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip(), 'Commit changes before qualification'
    suffix = uuid.uuid4().hex[:10].upper()
    code = 'A2_PHRASE_' + suffix
    report['content_code'] = code
    anon, _ = client()
    request('/admin/content', expected=302, opener=anon)
    login = page('/login'); old_session = next((c.value for c in cookies if c.name == 'JSESSIONID'), None)
    _, headers = request('/login','POST',{'username':os.environ.get('VOXPREP_ADMIN_USERNAME','admin'),
                       'password':os.environ.get('VOXPREP_ADMIN_PASSWORD','777')},token=csrf(login),expected=302,secret=True)
    assert urllib.parse.urlparse(headers['Location']).path == '/admin', 'Direct login must land on /admin'
    assert next(c.value for c in cookies if c.name == 'JSESSIONID') != old_session, 'Session ID must rotate after login'
    for path in ['/admin','/admin/content/revisions/new','/admin/imports','/admin/catalogue/verticals/new','/admin/publication']:
        page(path)
    baseline = state()
    request('/admin/publication/candidates','POST',{},expected=403)
    assert state() == baseline, 'CSRF failure mutated database'
    picker = page('/admin/catalogue/verticals/new')
    assert 'data-media-target="iconAssetId"' in picker and 'type="hidden" id="iconAssetId"' in picker
    report['gates']['API-02'] = 'PASS (screenshots pending)'

    template, _ = request('/admin/imports/template.xml')
    request('/admin/imports/schema.xsd')
    document = ET.fromstring(template)
    for content in list(document)[1:]: document.remove(content)
    document[0].set('code',code)
    valid = ET.tostring(document,encoding='utf-8',xml_declaration=True)
    bad = valid.replace(b'<minutes>2</minutes>',b'<minutes>0</minutes>')
    assert bad != valid
    (OUT/'valid.xml').write_bytes(valid); (OUT/'invalid.xml').write_bytes(bad)
    source = page('/admin/imports')
    before = state()
    rejected, _ = post('/admin/imports/validate',source=source,file=('invalid.xml','application/xml',bad),expected=200)
    assert b'XML validation failed' in rejected
    refused, _ = post('/admin/imports/import-drafts',source=rejected.decode(),file=('invalid.xml','application/xml',bad),expected=200)
    assert b'Validation expired' in refused
    assert state() == before
    checked, _ = post('/admin/imports/validate',source=refused.decode(),file=('valid.xml','application/xml',valid),expected=200)
    assert b'Database preflight:' in checked and b'Import as DRAFT' in checked
    changed, _ = post('/admin/imports/import-drafts',source=checked.decode(),file=('invalid.xml','application/xml',bad),expected=200)
    assert b'XML changed since validation' in changed and state() == before
    imported, _ = post('/admin/imports/import-drafts',source=changed.decode(),file=('valid.xml','application/xml',valid),expected=200)
    assert b'Import committed.' in imported
    revision = sql(f"SELECT id FROM app.content_revision WHERE content_code='{code}' AND revision_number=1;")
    assert re.fullmatch('[0-9a-f-]{36}',revision)
    report['revision_id'] = revision
    assert sql(f"SELECT lifecycle FROM app.content_revision WHERE id='{revision}';") == 'DRAFT'
    report['gates']['API-03'] = 'PASS'
    edit_path = '/admin/content/revisions/' + revision + '/edit'
    edit = page(edit_path)
    fields = dict(expectedVersion=Inputs(edit).values['expectedVersion'],bodyType='phrase',title='A2 live editorial phrase',
                  subtitle='Local macOS acceptance',description='Imported XML edited through MVC',categoryCode='INTERVIEW',levelCode='B2',
                  minutes='2',skillCodes='SPEAKING',availability='ACTIVE',phrase='I build reliable backend services.',
                  usage='Describe professional experience.',examples='I build reliable services with Java.')
    post('/admin/content/revisions/'+revision,fields,source=edit)
    edited = page(edit_path); assert 'A2 live editorial phrase' in edited
    image = png(); (OUT/'cover.png').write_bytes(image)
    cover, _ = post('/admin/media/images',{'role':'COVER_IMAGE'},source=edited,file=('cover.png','image/png',image),expected=200)
    asset = json.loads(cover); report['image_asset_id'] = asset['id']
    listed, _ = request('/admin/media/images?role=COVER_IMAGE&page=0')
    assert any(a['id'] == asset['id'] for a in json.loads(listed))
    preview, _ = request(asset['previewUrl']); assert digest(preview) == digest(image)
    post('/admin/media/bind',dict(revisionId=revision,role='COVER_IMAGE',assetId=asset['id']),source=edited)
    for step, lifecycle in [('ready-for-audio','READY_FOR_AUDIO'),('review','READY_FOR_REVIEW'),('approve','APPROVED')]:
        edit = page(edit_path)
        post('/admin/content/revisions/'+revision+'/'+step,dict(expectedVersion=Inputs(edit).values['expectedVersion'],reason='A2_ACCEPTANCE',comment='Real MVC editorial review'),source=edit)
        page(edit_path)
        actual = sql(f"SELECT lifecycle FROM app.content_revision WHERE id='{revision}';")
        assert actual == lifecycle, (step,actual)

    common = dict(expectedVersion='0',sortOrder='0',availability='ACTIVE',description='A2 local acceptance')
    vertical_code, goal_code, track_code, pack_code = [x+'_'+suffix for x in ['A2_V','A2_G','A2_T','A2_PACK']]
    post('/admin/catalogue/verticals',common | dict(code=vertical_code,sectionCode='A2_TECH',title='A2 Engineering',iconAssetId=asset['id']))
    vertical = sql(f"SELECT id FROM app.catalogue_vertical WHERE code='{vertical_code}';")
    post('/admin/catalogue/goals',common | dict(code=goal_code,verticalId=vertical,title='Interview skills'))
    goal = sql(f"SELECT id FROM app.catalogue_learning_goal WHERE code='{goal_code}';")
    post('/admin/catalogue/tracks',common | dict(code=track_code,goalId=goal,title='Backend developer',levelCode='B2'))
    track = sql(f"SELECT id FROM app.catalogue_learning_track WHERE code='{track_code}';")
    post('/admin/catalogue/collections',common | dict(code=pack_code,trackId=track,title='A2 starter collection',accessLevel='FREE'))
    collection = sql(f"SELECT id FROM app.catalogue_learning_collection WHERE code='{pack_code}';")
    report.update(vertical_id=vertical, collection_id=collection, pack_code=pack_code)
    member_path='/admin/catalogue/collections/'+collection+'/members'
    post(member_path,{'revisionId':revision},source=page(member_path))
    _, headers = post('/admin/publication/candidates',source=page('/admin/publication'))
    route=urllib.parse.urlparse(headers['Location']).path
    candidate=route.rsplit('/',1)[1]; report['candidate_id']=candidate
    refs = sql("SELECT content_code || '|' || content_type || '|' || revision_number || '|' || checksum_sha256 FROM app.content_revision WHERE lifecycle='PUBLISHED' OR id='"+revision+"' ORDER BY content_code;")
    post(route+'/validate',{'exactRefs':refs},source=page(route))
    assert sql(f"SELECT status FROM app.publication_candidate WHERE id='{candidate}';") == 'VALIDATED'
    post(route+'/publish',source=page(route))
    publication_page=page('/admin/publication')
    assert sql(f"SELECT lifecycle FROM app.content_revision WHERE id='{revision}';") == 'PUBLISHED'
    release = json.loads(sql(f"SELECT row_to_json(r)::text FROM app.publication_release r JOIN app.publication_current c ON c.release_id=r.id WHERE r.candidate_id='{candidate}';"))
    report['release']={k:release[k] for k in ['id','content_version','root_sha256']}
    report['gates']['API-04']='PASS'

    registered,_=request('/api/v1/installations','POST',json_body={'installationId':str(uuid.uuid4())},secret=True)
    installation_token=json.loads(registered)['installationToken']
    request('/api/v1/content/manifest',expected=401,opener=anon)
    root_bytes, root_headers = request('/api/v1/content/manifest',opener=learner)
    root=json.loads(root_bytes)
    assert root['contentVersion']==release['content_version']
    assert canonical(root,'ROOT')==root['checksum']==root_headers['ETag'].strip('"')
    wire_rows=json.loads(sql(f"SELECT json_agg(row_to_json(d))::text FROM app.publication_wire_document d WHERE release_id='{release['id']}';"))
    stored_root=next(d for d in wire_rows if d['document_kind']=='ROOT')
    assert json.loads(stored_root['body_json'])==root
    assert stored_root['checksum_sha256']==root['checksum']
    report['immutable_root_sha256']=root['checksum']
    report['legacy_candidate_ref_sha256']=release['root_sha256']
    assert report['immutable_root_sha256']!=report['legacy_candidate_ref_sha256']
    for ref in root['packs']:
        path='/api/v1/content/packs/'+ref['code']+'/manifest?'+urllib.parse.urlencode({'variant':ref['variant'],'revision':ref['revision']})
        packed,_=request(path,opener=learner); pack=json.loads(packed)
        assert canonical(pack,'PACK')==pack['checksum']==ref['checksum']
        stored=next(d for d in wire_rows if d['document_kind']=='PACK' and d['resource_code']==ref['code'] and d['variant']==ref['variant'])
        assert json.loads(stored['body_json'])==pack and stored['checksum_sha256']==ref['checksum']
        if ref['code']==pack_code:
            content_ref=next(c for c in pack['contents'] if c['contentCode']==code)
            payload_bytes,_=request(f'/api/v1/content/phrase/{code}/revisions/1',opener=learner)
            payload=json.loads(payload_bytes)
            report['payload']=payload
            db_checksum=sql(f"SELECT checksum_sha256 FROM app.content_revision WHERE id='{revision}';")
            assert content_ref['revision']==1 and content_ref['checksum']==db_checksum
            assert payload.get('revision',payload.get('revisionNumber'))==1
            assert payload.get('checksum',payload.get('checksumSha256'))==db_checksum
            assert 'I build reliable backend services.' in payload_bytes.decode()
    for ref in root['catalogues']:
        data,_=request(f"/api/v1/catalogues/{ref['kind']}/revisions/{ref['revision']}",opener=learner)
        catalogue=json.loads(data); assert canonical(catalogue,'CATALOGUE')==ref['checksum']==catalogue['checksum']
        stored=next(d for d in wire_rows if d['document_kind']=='CATALOGUE' and d['resource_code']==ref['kind'])
        assert json.loads(stored['body_json'])==catalogue and stored['checksum_sha256']==ref['checksum']
    report['gates']['API-05']='PASS';report['gates']['API-06']='PASS'
    report['status']='PASS (screenshots pending)'
except Exception as error:
    report['status']='FAIL';report['error']=str(error); report['traceback']=traceback.format_exc()
finally:
    (OUT/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(report['status']+': '+str(OUT/'report.json'),flush=True)
    if report.get('error'): print(report['error'],flush=True)
raise SystemExit(1 if report['status']=='FAIL' else 0)
