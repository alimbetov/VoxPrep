"""Real DEV A3 smoke. Authoring through MVC; SQL is read-only evidence."""
import datetime as dt
import hashlib
from html.parser import HTMLParser
from http.cookiejar import CookieJar
import json
import os
from pathlib import Path
import subprocess
import time
import uuid
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
BASE = 'http://127.0.0.1:' + os.environ.get('VOXPREP_LOCAL_BACKEND_PORT', '18081')
OUT = ROOT / 'artifacts/local-smoke' / ('a3-' + dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
OUT.mkdir(parents=True)
report = {'sha': subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip(),
          'gates': {f'TTS-0{i}':'NOT RUN' for i in range(1,7)}, 'operations': [], 'states': []}
class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args): return None
http = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(CookieJar()), NoRedirect())
class Inputs(HTMLParser):
    def __init__(self, source):
        super().__init__(); self.values = {}; self.feed(source)
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'input' and a.get('name'): self.values[a['name']] = a.get('value','')
        if tag == 'meta' and a.get('name') == '_csrf': self.values['_csrf'] = a['content']
def request(path, fields=None, bearer=None, expected=200):
    headers = {}; data = None
    if bearer: headers['Authorization'] = 'Bearer ' + bearer
    if fields is not None:
        if bearer: data=json.dumps(fields).encode(); headers['Content-Type']='application/json'
        else: data=urllib.parse.urlencode(fields).encode(); headers['Content-Type']='application/x-www-form-urlencoded'
    req=urllib.request.Request(BASE+path,data=data,headers=headers)
    try: response=http.open(req,timeout=120)
    except urllib.error.HTTPError as error: response=error
    body=response.read()
    report['operations'].append({'path':path,'method':req.get_method(),'status':response.code,'expected':expected})
    assert response.code==expected, (path,response.code,body[:300])
    return body,response.headers
def page(path): return request(path)[0].decode()
def post(path, fields, source):
    return request(path,dict(fields,_csrf=Inputs(source).values['_csrf']),expected=302)
def sql(query):
    assert query.startswith('SELECT ')
    command=['docker','compose','--env-file',str(ROOT/'infra/env/dev.env.example'),'-f',str(ROOT/'infra/compose/compose.dev.yml'),
             'exec','-T','postgres','sh','-eu','-c','export PGPASSWORD="$(cat /run/secrets/postgres_backend_password)"; exec psql -h 127.0.0.1 -U voxprep_backend -d voxprep_dev -At -v ON_ERROR_STOP=1']
    result=subprocess.run(command,input=query,text=True,capture_output=True,timeout=20)
    assert result.returncode==0,result.stderr
    return result.stdout.strip()
def main():
    token=(ROOT/'infra/secrets/dev/backend/worker_api_key').read_text().strip()
    request('/internal/v1/tts/jobs/claim',{'workerId':'a3-wrong-token'},bearer='invalid-token',expected=401)
    report['gates']['TTS-01']='PASS'
    model=json.loads(sql("SELECT row_to_json(m)::text FROM (SELECT id,code,model_sha256,config_sha256,source_revision FROM app.tts_voice_model WHERE code='en_US.ljspeech.medium' AND status='ACTIVE') m;"))
    report['model']=model
    for kind in ('model','config'):
        data,_=request('/internal/v1/tts/models/'+model['id']+'/'+kind,bearer=token)
        digest=hashlib.sha256(data).hexdigest()
        assert digest==model[kind+'_sha256']
        report[kind+'_download']={'sha256':digest,'size':len(data)}
    report['gates']['TTS-02']='PASS'
    subprocess.run(['docker','stop','voxprep-local-tts-worker'],check=True,timeout=30)
    login=page('/login')
    post('/login',{'username':os.environ.get('VOXPREP_ADMIN_USERNAME','admin'),'password':os.environ.get('VOXPREP_ADMIN_PASSWORD','777')},login)
    code='A3_REAL_'+dt.datetime.now(dt.timezone.utc).strftime('%Y%m%d_%H%M%S')
    fields=dict(contentCode=code,expectedVersion=0,bodyType='phrase',title='A3 real Piper acceptance',subtitle='Pinned LJSpeech',description='Real synthesis through MVC',categoryCode='GENERAL',levelCode='B1',minutes=1,skillCodes='SPEAKING',availability='INACTIVE',phrase='I build reliable services and verify recovery paths.',usage='Technical interview',examples='I test the complete audio pipeline.')
    _,headers=post('/admin/content/revisions',fields,page('/admin/content/revisions/new'))
    edit_path=urllib.parse.urlparse(headers['Location']).path
    revision=edit_path.split('/')[-2]; report['revision_id']=revision; report['edit_path']=edit_path
    edit=page(edit_path)
    post('/admin/content/revisions/'+revision+'/ready-for-audio',{'expectedVersion':Inputs(edit).values['expectedVersion']},edit)
    post('/admin/content/revisions/'+revision+'/tts/prepare',{'audioRole':'pronunciation','voiceModelCode':model['code']},page(edit_path))
    query="SELECT row_to_json(j)::text FROM (SELECT id,status,attempt_count,lease_owner,output_asset_id FROM app.tts_job WHERE content_revision_id='"+revision+"') j;"
    job=json.loads(sql(query)); report['job_id']=job['id']; assert job['status']=='PENDING',job
    report['states'].append(job)
    claim,_=request('/internal/v1/tts/jobs/claim',{'workerId':'a3-expiry-probe'},bearer=token)
    claim=json.loads(claim)
    assert claim['jobId']==job['id'], 'Unexpected pending job: do not continue'
    report['lease_expiry_probe']={'job_id':claim['jobId'],'lease_until':claim['leaseUntil']}
    subprocess.run([str(ROOT/'scripts/local/worker-start.sh')],check=True,timeout=30)
    deadline=time.monotonic()+240
    while time.monotonic()<deadline:
        job=json.loads(sql(query))
        if job!=report['states'][-1]: report['states'].append(job)
        if job['status']=='READY': break
        assert job['status']!='FAILED',job
        time.sleep(2)
    assert job['status']=='READY',job
    report['gates']['TTS-03']='PASS'
    audio,headers=request('/admin/content/revisions/'+revision+'/tts/jobs/'+job['id']+'/preview')
    assert headers['Content-Type'].startswith('audio/mpeg')
    (OUT/'output.mp3').write_bytes(audio)
    subprocess.run(['docker','cp',str(OUT/'output.mp3'),'voxprep-local-tts-worker:/tmp/a3-output.mp3'],check=True)
    probe=json.loads(subprocess.check_output(['docker','exec','voxprep-local-tts-worker','ffprobe','-v','error','-show_streams','-show_format','-of','json','/tmp/a3-output.mp3']))
    (OUT/'ffprobe.json').write_text(json.dumps(probe,indent=2))
    stream=probe['streams'][0]
    assert stream['codec_name']=='mp3' and stream['channels']==1 and stream['sample_rate']=='24000'
    assert 60000<=int(stream['bit_rate'])<=68000 and float(probe['format']['duration'])>0
    report['audio']={'sha256':hashlib.sha256(audio).hexdigest(),'size':len(audio),'duration':probe['format']['duration']}
    report['gates']['TTS-04']='PASS'
    asset=json.loads(sql("SELECT row_to_json(a)::text FROM (SELECT id,sha256,size_bytes FROM app.file_asset WHERE id='"+job['output_asset_id']+"') a;"))
    assert asset['sha256']==report['audio']['sha256'] and asset['size_bytes']==len(audio)
    report['asset']=asset; report['gates']['TTS-05']='PASS'
    request('/internal/v1/tts/jobs/'+job['id']+'/heartbeat',
            {'workerId':'a3-expiry-probe','leaseToken':claim['leaseToken']},bearer=token,expected=409)
    finalized=json.loads(sql("SELECT row_to_json(j)::text FROM (SELECT file_id,fingerprint,voice_model_id,finalized_by_worker,finalized_lease_token FROM app.tts_job WHERE id='"+job['id']+"') j;"))
    fields=dict(workerId=finalized['finalized_by_worker'],fileId=finalized['file_id'],leaseToken=finalized['finalized_lease_token'],
                fingerprint=finalized['fingerprint'],voiceModelId=finalized['voice_model_id'],audioProfile='mp3-mono-24k-64k-v1',
                sha256=report['audio']['sha256'],sizeBytes=len(audio),durationMs=round(float(probe['format']['duration'])*1000))
    def replay(expected):
        boundary='VoxPrep'+uuid.uuid4().hex
        parts=[f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode() for k,v in fields.items()]
        parts += [f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="output.mp3"\r\nContent-Type: audio/mpeg\r\n\r\n'.encode(),audio,f'\r\n--{boundary}--\r\n'.encode()]
        req=urllib.request.Request(BASE+'/internal/v1/tts/jobs/'+job['id']+'/output',data=b''.join(parts),headers={'Authorization':'Bearer '+token,'Content-Type':'multipart/form-data; boundary='+boundary})
        try: response=http.open(req,timeout=30)
        except urllib.error.HTTPError as error: response=error
        response.read()
        report['operations'].append({'path':req.full_url,'method':'POST','status':response.code,'expected':expected,'scenario':'output replay'})
        assert response.code==expected
    before=sql("SELECT count(*) FROM app.file_asset;")
    replay(200)
    fields['fingerprint']='0'*64
    replay(409)
    subprocess.run(['docker','restart','voxprep-local-tts-worker'],check=True,timeout=30)
    time.sleep(3)
    assert sql("SELECT count(*) FROM app.file_asset;")==before
    assert json.loads(sql(query))==job
    report['recovery']={'expired_lease_reclaimed':job['attempt_count']>=2,'identical_replay':200,'mismatched_replay':409,'worker_restart_no_duplicate':True}
    assert report['recovery']['expired_lease_reclaimed']
    report['gates']['TTS-06']='PASS (lease/replay/restart); checksum/disconnection pending'
try:
    main()
except Exception as error:
    report['error']=str(error)
    raise
finally:
    (OUT/'report.json').write_text(json.dumps(report,indent=2))
    print(OUT)
