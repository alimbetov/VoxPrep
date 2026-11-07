"""Operator action: import one real XML draft, bind image and generate Piper audio.
No direct SQL mutations, approval, publication or changes to existing materials.
"""
from pathlib import Path
from http.cookiejar import CookieJar
from html.parser import HTMLParser
import datetime as dt
import hashlib,json,os,re,subprocess,time,urllib.request,urllib.parse,urllib.error,uuid
ROOT=Path(__file__).resolve().parents[2]
BASE='http://127.0.0.1:'+os.environ.get('VOXPREP_LOCAL_BACKEND_PORT','18081')
OUT=ROOT/'artifacts/local-smoke'/('xml-media-'+dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ'));OUT.mkdir(parents=True)
report={'sha':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'operations':[],'status':'IN PROGRESS'}
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args): return None
http=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(CookieJar()),NoRedirect())
class Inputs(HTMLParser):
 def __init__(self,source): super().__init__();self.values={};self.feed(source)
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='input' and a.get('name'):self.values[a['name']]=a.get('value','')
  if tag=='meta' and a.get('name')=='_csrf':self.values['_csrf']=a['content']
def request(path,fields=None,file=None,expected=200):
 headers={};data=None
 if fields is not None:data=urllib.parse.urlencode(fields).encode();headers['Content-Type']='application/x-www-form-urlencoded'
 if file:
  boundary='VoxPrep'+uuid.uuid4().hex
  parts=[f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode() for k,v in fields.items()]
  name,mime,content=file
  parts += [f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{name}"\r\nContent-Type: {mime}\r\n\r\n'.encode(),content,f'\r\n--{boundary}--\r\n'.encode()]
  data=b''.join(parts);headers['Content-Type']='multipart/form-data; boundary='+boundary
 req=urllib.request.Request(BASE+path,data=data,headers=headers)
 try:response=http.open(req,timeout=60)
 except urllib.error.HTTPError as e:response=e
 body=response.read();report['operations'].append({'path':path,'method':req.get_method(),'status':response.code,'expected':expected})
 assert response.code==expected,(path,response.code)
 return body,response.headers
def page(path):return request(path)[0].decode()
def post(path,fields,source,file=None,expected=302):return request(path,dict(fields,_csrf=Inputs(source).values['_csrf']),file,expected)
def sql(query):
 assert query.startswith('SELECT ')
 command=['docker','compose','--env-file',str(ROOT/'infra/env/dev.env.example'),'-f',str(ROOT/'infra/compose/compose.dev.yml'),'exec','-T','postgres','sh','-eu','-c','export PGPASSWORD="$(cat /run/secrets/postgres_backend_password)"; exec psql -h 127.0.0.1 -U voxprep_backend -d voxprep_dev -At -v ON_ERROR_STOP=1']
 result=subprocess.run(command,input=query,text=True,capture_output=True,timeout=20);assert result.returncode==0,result.stderr
 return result.stdout.strip()
try:
 post('/login',{'username':os.environ.get('VOXPREP_ADMIN_USERNAME','admin'),'password':os.environ.get('VOXPREP_ADMIN_PASSWORD','777')},page('/login'))
 assert sql("SELECT count(*) FROM app.content_revision WHERE content_code='JAVA_RELIABLE_SERVICES_01';")=='0','Code already exists; no existing content modified'
 xml=(ROOT/'docs/local-macos/fixtures/reliable-backend-services.xml').read_bytes();(OUT/'import.xml').write_bytes(xml)
 checked,_=post('/admin/imports/validate',{},page('/admin/imports'),file=('reliable-backend-services.xml','application/xml',xml),expected=200)
 assert b'Import as DRAFT' in checked and b'preflightError' not in checked
 imported,_=post('/admin/imports/import-drafts',{},checked.decode(),file=('reliable-backend-services.xml','application/xml',xml),expected=200)
 assert b'Import committed.' in imported
 revision=sql("SELECT id FROM app.content_revision WHERE content_code='JAVA_RELIABLE_SERVICES_01' AND revision_number=1;");assert re.fullmatch('[a-f0-9-]{36}',revision)
 report['revision_id']=revision;edit_path='/admin/content/revisions/'+revision+'/edit';report['url']=BASE+edit_path
 image=(ROOT/'mobile/careerspeak_app/assets/demo/java-cover.png').read_bytes()
 uploaded,_=post('/admin/media/images',{'role':'COVER_IMAGE'},page(edit_path),file=('java-services-cover.png','image/png',image),expected=200)
 asset=json.loads(uploaded);report['image_asset_id']=asset['id'];report['image_sha256']=hashlib.sha256(image).hexdigest()
 preview,_=request(asset['previewUrl']);assert preview==image
 post('/admin/media/bind',dict(revisionId=revision,role='COVER_IMAGE',assetId=asset['id']),page(edit_path))
 edit=page(edit_path)
 post('/admin/content/revisions/'+revision+'/ready-for-audio',{'expectedVersion':Inputs(edit).values['expectedVersion']},edit)
 post('/admin/content/revisions/'+revision+'/tts/prepare',{'audioRole':'pronunciation','voiceModelCode':'en_US.ljspeech.medium'},page(edit_path))
 query="SELECT row_to_json(j)::text FROM (SELECT id,status,attempt_count,output_asset_id,failure_code FROM app.tts_job WHERE content_revision_id='"+revision+"') j;"
 deadline=time.monotonic()+180;report['states']=[]
 while time.monotonic()<deadline:
  raw=sql(query);assert raw,'TTS job not created'
  job=json.loads(raw)
  if not report['states'] or report['states'][-1]!=job: report['states'].append(job)
  if job['status'] in ('READY','FAILED'):break
  time.sleep(2)
 assert job['status']=='READY',job
 report['job_id']=job['id'];report['audio_asset_id']=job['output_asset_id']
 audio,headers=request('/admin/content/revisions/'+revision+'/tts/jobs/'+job['id']+'/preview')
 assert headers['Content-Type'].startswith('audio/mpeg');(OUT/'audio.mp3').write_bytes(audio)
 report['audio_sha256']=hashlib.sha256(audio).hexdigest();report['audio_bytes']=len(audio)
 subprocess.run(['docker','cp',str(OUT/'audio.mp3'),'voxprep-local-tts-worker:/tmp/xml-media.mp3'],check=True,capture_output=True)
 probe=json.loads(subprocess.check_output(['docker','exec','voxprep-local-tts-worker','ffprobe','-v','error','-show_streams','-show_format','-of','json','/tmp/xml-media.mp3']))
 (OUT/'ffprobe.json').write_text(json.dumps(probe,indent=2))
 assert probe['streams'][0]['codec_name']=='mp3' and probe['streams'][0]['sample_rate']=='24000'
 report['duration_seconds']=probe['format']['duration'];report['lifecycle']=sql("SELECT lifecycle FROM app.content_revision WHERE id='"+revision+"';")
 report['status']='PASS'
except Exception as e:
 report['status']='FAIL';report['error']=str(e);raise
finally:
 (OUT/'report.json').write_text(json.dumps(report,indent=2));print(OUT,flush=True)
