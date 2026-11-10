#!/usr/bin/env python3
"""Real EV1 browser acceptance. No SQL authoring; credentials never enter evidence.

Run against a dedicated local database, with the normal Piper worker and an
ACTIVE en_US.ljspeech.medium model provisioned by the existing operator setup.
SQL is used only for identity/evidence reads and rolled-back immutability probes.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import time
import uuid
import zlib

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[2]
BASE = os.environ.get('VOXPREP_EV1_BASE_URL', 'http://127.0.0.1:18082')
OUT = Path(os.environ['VOXPREP_EV1_OUTPUT_DIR'])
DB = os.environ['VOXPREP_EV1_DATABASE']
PG_COMMAND = ['psql', '-X', '-h', '127.0.0.1', '-p',
              os.environ['VOXPREP_EV1_POSTGRES_PORT'], '-U', 'voxprep_backend',
              '-d', DB, '-At', '-v', 'ON_ERROR_STOP=1']
assert re.fullmatch(r'[a-z0-9_]+', DB)
OUT.mkdir(parents=True, exist_ok=True)
report = {'sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT,
                                       text=True).strip(), 'checks': {}, 'http': []}


def sql(query):
    assert query.startswith('SELECT ')
    return subprocess.check_output(PG_COMMAND + ['-c', query],
                                   text=True, timeout=20).strip()


def png(color):
    def chunk(kind, data):
        return struct.pack('!I', len(data)) + kind + data + struct.pack(
            '!I', zlib.crc32(kind + data) & 0xffffffff)
    w, h = 320, 180
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', w, h, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress((b'\x00' + bytes(color) * w) * h))
            + chunk(b'IEND', b''))


def main():
    suffix = uuid.uuid4().hex[:10].upper()
    code = 'EV1_VOCAB_' + suffix
    title = 'Lesson <img src=x onerror=alert(1)> & "quoted"'
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True,
            executable_path=os.environ.get('VOXPREP_BROWSER_EXECUTABLE') or None)
        context = browser.new_context(viewport={'width': 1280, 'height': 1000})
        page = context.new_page()
        page.set_default_timeout(30000)

        def goto(path):
            response = page.goto(BASE + path, wait_until='domcontentloaded')
            assert response.status == 200, (path, response.status)

        def csrf():
            return page.locator('meta[name="_csrf"]').get_attribute('content')

        def post(path, data, expected=302):
            response = context.request.post(BASE + path,
                form=dict(data, _csrf=csrf()), max_redirects=0)
            report['http'].append({'method': 'POST', 'path': path,
                                   'status': response.status, 'expected': expected})
            assert response.status == expected, (path, response.status, response.text()[:250])
            return response

        goto('/login')
        page.locator('[name=username]').fill(os.environ['VOXPREP_EV1_ADMIN_USERNAME'])
        page.locator('[name=password]').fill(os.environ['VOXPREP_EV1_ADMIN_PASSWORD'])
        page.locator('[name=password]').press('Enter')
        page.wait_for_url('**/admin')

        goto('/admin/content/revisions/new')
        page.locator('[name=bodyType]').select_option('vocabulary')
        fields = dict(contentCode=code, title='EV1 real vocabulary acceptance',
            subtitle='External video beside images and Piper MP3',
            description='Dedicated local P0 fixture', categoryCode='GENERAL',
            levelCode='B1', minutes='2', skillCodes='SPEAKING', term='Reliability',
            partOfSpeech='noun', definition='The ability to work consistently.',
            examples='We verify reliability with real integration checks.')
        for name, value in fields.items():
            if name == 'examples':
                page.locator('[name=examples]').locator('..').get_by_role(
                    'button', name='+ Add row', exact=True).click()
                page.get_by_label('Example', exact=True).fill(value)
            else:
                page.locator('[name="' + name + '"]').fill(value)
        page.get_by_role('button', name='Создать черновик DRAFT 1').click()
        page.wait_for_url('**/revisions/*/edit')
        revision = page.url.split('/')[-2]
        edit = '/admin/content/revisions/' + revision + '/edit'
        report.update(content_code=code, revision_id=revision)

        assets = {}
        for role, color in [('COVER_IMAGE', (33, 101, 172)),
                            ('CONTENT_IMAGE', (40, 155, 106))]:
            goto('/admin/media?revisionId=' + revision + '&role=' + role)
            data = png(color)
            page.locator('input[type=file]').set_input_files({
                'name': role + '.png', 'mimeType': 'image/png', 'buffer': data})
            page.get_by_role('button', name='Upload / reuse identical image').click()
            page.wait_for_load_state('domcontentloaded')
            asset = sql("SELECT id FROM app.file_asset WHERE sha256='" +
                        hashlib.sha256(data).hexdigest() + "' AND kind='" + role + "';")
            assert re.fullmatch('[0-9a-f-]{36}', asset), asset
            page.locator('form').filter(has=page.locator('[name=assetId][value="' + asset + '"]')).get_by_role('button').click()
            page.wait_for_url('**/edit')
            assets[role] = asset

        video = '/admin/content/revisions/' + revision + '/external-video'
        page.locator('#externalVideoUrl').fill('https://youtu.be/aqz-KE-bpKQ')
        page.locator('#externalVideoTitle').fill(title)
        page.get_by_role('button', name='Сохранить видео', exact=True).click()
        page.wait_for_load_state('domcontentloaded')
        page.reload(wait_until='domcontentloaded')
        assert page.locator('#externalVideoTitle').input_value() == title
        assert page.locator('[data-external-video-section] img').count() == 0
        assert page.locator('[data-external-video-section] a').inner_text() == title
        report['checks']['title_html_escaped'] = 'PASS'
        report['checks']['save_reload'] = 'PASS'
        page.screenshot(path=str(OUT / '01-draft-video-images.png'), full_page=True)

        no_csrf = context.request.post(BASE + video, form={'url': 'https://youtu.be/aqz-KE-bpKQ', 'title': 'CSRF'}, max_redirects=0)
        assert no_csrf.status == 403
        report['checks']['csrf_denied'] = 403
        post(video, {'url': 'https://youtube.com.evil.example/watch?v=aqz-KE-bpKQ', 'title': 'Invalid provider'})
        assert sql("SELECT title FROM app.content_external_video WHERE content_revision_id='" + revision + "';") == title
        report['checks']['invalid_url_no_mutation'] = 'PASS'

        goto(edit)
        page.get_by_role('button', name='Передать на озвучивание', exact=True).click()
        page.wait_for_load_state('domcontentloaded')
        page.locator('[name=audioRole]').select_option('pronunciation')
        page.locator('[name=voiceModelCode]').select_option('en_US.ljspeech.medium')
        page.get_by_role('button', name='Создать или использовать TTS-задание').click()
        page.wait_for_load_state('domcontentloaded')
        deadline = time.monotonic() + 240
        while time.monotonic() < deadline:
            state = sql("SELECT status FROM app.tts_job WHERE content_revision_id='" + revision + "';")
            assert state != 'FAILED', 'Actual Piper job failed'
            if state == 'READY':
                break
            time.sleep(2)
        assert state == 'READY', state
        goto(edit)
        audio = page.locator('audio').first
        audio_url = audio.get_attribute('src')
        mp3 = context.request.get(BASE + audio_url)
        assert mp3.status == 200 and mp3.headers['content-type'].startswith('audio/mpeg')
        (OUT / 'piper.mp3').write_bytes(mp3.body())
        report['mp3_sha256'] = hashlib.sha256(mp3.body()).hexdigest()
        audio.evaluate('(a) => a.play()')
        page.wait_for_function('document.querySelector("audio").ended', timeout=60000)
        assert audio.evaluate('(a) => a.error') is None
        report['checks']['real_piper_preview_playback'] = 'PASS'
        page.screenshot(path=str(OUT / '02-ready-mp3-video-images.png'), full_page=True)
        bindings = sql("SELECT role||':'||file_asset_id FROM app.content_asset_binding WHERE content_revision_id='" + revision + "' ORDER BY role;")
        report['bindings_before_publication'] = bindings
        assert len(bindings.splitlines()) == 3, bindings

        for action in ['review', 'approve']:
            goto(edit)
            form = page.locator('form[action$="/' + action + '"]')
            form.locator('[name=reason]').fill('EV1_P0_ACCEPTANCE')
            form.locator('[name=comment]').fill('Actual browser review, images and audio verified')
            form.get_by_role('button').click()
            page.wait_for_load_state('domcontentloaded')

        # A distinct premium lesson is required: placing the FREE lesson in a
        # FULL collection would still make it accessible through its FREE owner.
        premium_code = 'EV1_PREMIUM_' + suffix
        created = post('/admin/content/revisions', fields | dict(
            contentCode=premium_code, expectedVersion='0', bodyType='vocabulary',
            availability='ACTIVE', title='EV1 premium vocabulary'))
        premium_edit = created.headers['location']
        if premium_edit.startswith(BASE):
            premium_edit = premium_edit[len(BASE):]
        premium = premium_edit.split('/')[-2]
        goto(premium_edit)
        post('/admin/content/revisions/' + premium + '/external-video',
             {'url': 'https://youtu.be/aqz-KE-bpKQ', 'title': 'Premium video'})
        for action in ['ready-for-audio', 'review', 'approve']:
            goto(premium_edit)
            form = page.locator('form[action$="/' + action + '"]')
            version = form.locator('[name=expectedVersion]').input_value()
            post('/admin/content/revisions/' + premium + '/' + action,
                 dict(expectedVersion=version, reason='EV1_P0', comment='Premium boundary fixture'))
        report['premium_content_code'] = premium_code

        # Existing catalogue MVC endpoints, same authenticated browser session.
        common = dict(expectedVersion='0', sortOrder='0', availability='ACTIVE', description='EV1 acceptance')
        post('/admin/catalogue/verticals', common | dict(code='EV1_V_' + suffix,
            sectionCode='EV1_TEST', title='EV1 Engineering', iconAssetId=assets['COVER_IMAGE']))
        vertical = sql("SELECT id FROM app.catalogue_vertical WHERE code='EV1_V_" + suffix + "';")
        post('/admin/catalogue/goals', common | dict(code='EV1_G_' + suffix, verticalId=vertical, title='EV1 learning'))
        goal = sql("SELECT id FROM app.catalogue_learning_goal WHERE code='EV1_G_" + suffix + "';")
        post('/admin/catalogue/tracks', common | dict(code='EV1_T_' + suffix, goalId=goal, title='EV1 track', levelCode='B1'))
        track = sql("SELECT id FROM app.catalogue_learning_track WHERE code='EV1_T_" + suffix + "';")
        for access in ['FREE', 'FULL']:
            pack = 'EV1_' + access + '_' + suffix
            post('/admin/catalogue/collections', common | dict(code=pack, trackId=track, title='EV1 ' + access, accessLevel=access))
            collection = sql("SELECT id FROM app.catalogue_learning_collection WHERE code='" + pack + "';")
            if access == 'FREE':
                post('/admin/catalogue/collections/' + collection + '/members', {'revisionId': revision})
            else:
                report['full_collection_id'] = collection
                post('/admin/catalogue/collections/' + collection + '/members', {'revisionId': premium})

        # Preserve earlier interrupted test fixtures and complete their empty
        # FULL collections through MVC; do not delete or bypass publication rules.
        empty = sql("SELECT c.id FROM app.catalogue_learning_collection c WHERE c.access_level='FULL' AND NOT EXISTS (SELECT 1 FROM app.catalogue_collection_content_member m WHERE m.collection_id=c.id);")
        for collection in empty.splitlines():
            post('/admin/catalogue/collections/' + collection + '/members', {'revisionId': premium})

        goto('/admin/publication')
        page.locator('form[action="/admin/publication/candidates"]').get_by_role('button').click()
        page.wait_for_url('**/candidates/*')
        refs = sql("SELECT DISTINCT ON (content_code,content_type) content_code||'|'||content_type||'|'||revision_number||'|'||checksum_sha256 FROM app.content_revision WHERE lifecycle IN ('APPROVED','PUBLISHED') ORDER BY content_code,content_type,revision_number DESC;")
        page.locator('#exactRefs').fill(refs)
        page.get_by_role('button', name='Validate and freeze manifest').click()
        page.wait_for_load_state('domcontentloaded')
        page.get_by_role('button', name='Publish and activate CURRENT').click()
        page.wait_for_url('**/admin/publication')
        page.screenshot(path=str(OUT / '03-published-current.png'), full_page=True)
        report['checks']['real_browser_publication'] = 'PASS'
        goto(edit)
        post(video, {'url': 'https://youtu.be/dQw4w9WgXcQ', 'title': 'Overwrite'}, 409)
        post(video + '/remove', {}, 409)
        report['checks']['published_save_remove_409'] = 'PASS'
        frozen = sql("SELECT row_to_json(v)::text FROM app.content_external_video_snapshot v WHERE content_revision_id='" + revision + "';")
        report['frozen_snapshot'] = json.loads(frozen)
        for mutation in ["UPDATE app.content_external_video_snapshot SET title='tampered' WHERE content_revision_id='" + revision + "'", "DELETE FROM app.content_external_video_snapshot WHERE content_revision_id='" + revision + "'"]:
            # Always rolls back, including in the unexpected case of an absent guard.
            probe = subprocess.run(PG_COMMAND,
                input='BEGIN; ' + mutation + '; ROLLBACK;', text=True,
                capture_output=True, timeout=20)
            assert probe.returncode != 0 and 'immutable' in probe.stderr, probe.stderr
        report['checks']['sql_update_delete_denied'] = 'PASS'

        registered = context.request.post(BASE + '/api/v1/installations', data={'installationId': str(uuid.uuid4())})
        assert registered.status == 200, registered.status
        token = registered.json()['installationToken']
        headers = {'Authorization': 'Bearer ' + token}
        path = '/api/v2/content/vocabulary/' + code + '/external-video'
        response = context.request.get(BASE + path, headers=headers)
        assert response.status == 200, (response.status, response.text())
        projection = response.json()
        assert projection['revision'] == 1 and projection['providerVideoId'] == 'aqz-KE-bpKQ'
        assert response.headers['cache-control'] == 'no-store'
        report['learner_projection'] = projection
        denied = context.request.get(BASE + '/api/v2/content/vocabulary/' + premium_code + '/external-video', headers=headers)
        assert denied.status == 403, (denied.status, denied.text())
        report['checks']['free_cannot_read_full_video'] = 403

        disabled_base = os.environ.get('VOXPREP_EV1_DISABLED_BASE_URL')
        report['checks']['live_feature_flag_disabled'] = 'NOT RUN'
        if disabled_base:
            off = context.request.get(disabled_base.rstrip('/') + path, headers=headers)
            assert off.status == 204 and off.body() == b''
            assert off.headers['cache-control'] == 'no-store'
            off_full = context.request.get(disabled_base.rstrip('/') +
                '/api/v2/content/vocabulary/' + premium_code + '/external-video', headers=headers)
            assert off_full.status == 403
            report['checks']['live_feature_flag_disabled'] = 'PASS (FREE 204; locked FULL 403)'

        # Real published media bytes, not only authoring bindings or DOM controls.
        media_path = '/api/v1/content/vocabulary/' + code
        media = context.request.get(BASE + media_path + '/media', headers=headers)
        assert media.status == 200
        images = [item for item in media.json() if item['kind'] in ('COVER_IMAGE', 'CONTENT_IMAGE')]
        assert len(images) == 2
        report['learner_media'] = []
        for item in images:
            url = BASE + media_path + '/media/' + item['assetId'] + '/content'
            data = context.request.get(url, headers=headers)
            assert data.status == 200 and data.headers['content-type'].startswith('image/')
            assert hashlib.sha256(data.body()).hexdigest() == item['sha256']
            assert len(data.body()) == item['sizeBytes']
            assert context.request.get(url, headers=headers | {'If-None-Match': data.headers['etag']}).status == 304
            report['learner_media'].append(item)
        report['checks']['published_images_http_hash_etag'] = 'PASS'
        audio_response = context.request.get(BASE + media_path + '/audio', headers=headers)
        assert audio_response.status == 200 and len(audio_response.json()) == 1
        audio_item = audio_response.json()[0]
        audio_bytes = context.request.get(BASE + media_path + '/audio/' + audio_item['assetId'] + '/content', headers=headers)
        assert audio_bytes.status == 200
        assert hashlib.sha256(audio_bytes.body()).hexdigest() == audio_item['sha256'] == report['mp3_sha256']
        learner_mp3 = OUT / 'learner-pronunciation.mp3'
        learner_mp3.write_bytes(audio_bytes.body())
        probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error',
            '-show_streams', '-show_format', '-of', 'json', str(learner_mp3)], timeout=15))
        assert probe['streams'][0]['codec_name'] == 'mp3' and probe['streams'][0]['channels'] == 1
        probe['format']['filename'] = learner_mp3.name
        (OUT / 'learner-ffprobe.json').write_text(json.dumps(probe, indent=2) + '\n')
        report['checks']['published_mp3_http_hash_ffprobe'] = 'PASS'

        # Use the repository's explicitly DEV-only simulated store boundary;
        # this is not a real purchase or a mocked content-authorization policy.
        purchase = context.request.post(BASE + '/api/v1/purchases/verify', headers=headers,
            data={'provider': 'GOOGLE_PLAY', 'productId': 'voxprep_full_unlock',
                  'purchaseEventId': str(uuid.uuid4()),
                  'verificationData': 'sim:v1:GOOGLE_PLAY:GRANTED:ev1_' + uuid.uuid4().hex})
        assert purchase.status == 200
        unlocked = context.request.get(BASE + '/api/v2/content/vocabulary/' + premium_code + '/external-video', headers=headers)
        assert unlocked.status == 200 and unlocked.json()['title'] == 'Premium video'
        report['checks']['verified_dev_full_can_read_video'] = 'PASS (DEV simulated-store entitlement)'
        for role, asset in assets.items():
            assert asset in bindings
        assert bindings == sql("SELECT role||':'||file_asset_id FROM app.content_asset_binding WHERE content_revision_id='" + revision + "' ORDER BY role;")
        report['checks']['image_audio_bindings_preserved'] = 'PASS'
        root = context.request.get(BASE + '/api/v1/content/manifest', headers=headers).json()
        assert projection['rootSha256'] == root['checksum']
        report['checks']['learner_exact_current'] = 'PASS'
        anon = browser.new_context()
        assert anon.request.get(BASE + path, max_redirects=0).status == 401
        assert anon.request.post(BASE + video, form={'url': 'https://youtu.be/aqz-KE-bpKQ', 'title': 'Anon'}, max_redirects=0).status in (302, 403)
        report['checks']['anonymous_denied'] = 'PASS'
        anon.close()

        goto(edit)
        page.get_by_role('button', name='Создать новую черновую ревизию').click()
        page.wait_for_url(lambda url: '/edit' in url and revision not in url)
        next_revision = page.url.split('/')[-2]
        page.locator('#externalVideoUrl').fill('https://youtu.be/dQw4w9WgXcQ')
        page.locator('#externalVideoTitle').fill('Next draft only')
        page.get_by_role('button', name='Сохранить видео', exact=True).click()
        page.wait_for_load_state('domcontentloaded')
        assert context.request.get(BASE + path, headers=headers).json() == projection
        assert sql("SELECT row_to_json(v)::text FROM app.content_external_video_snapshot v WHERE content_revision_id='" + revision + "';") == frozen
        report['next_revision_id'] = next_revision
        report['checks']['next_draft_no_leak'] = 'PASS'
        page.screenshot(path=str(OUT / '04-next-draft-isolated.png'), full_page=True)

        # An actually authored DRAFT-only identity must stay absent from learner HTTP.
        draft_code = 'EV1_DRAFT_ONLY_' + suffix
        draft_created = post('/admin/content/revisions', fields | dict(
            contentCode=draft_code, expectedVersion='0', bodyType='vocabulary', availability='ACTIVE'))
        draft_id = draft_created.headers['location'].split('/')[-2]
        post('/admin/content/revisions/' + draft_id + '/external-video',
             {'url': 'https://youtu.be/dQw4w9WgXcQ', 'title': 'Unpublished video metadata'})
        draft_response = context.request.get(BASE + '/api/v2/content/vocabulary/' + draft_code + '/external-video', headers=headers)
        assert draft_response.status == 404
        assert 'Unpublished video metadata' not in draft_response.text()
        report['checks']['draft_only_identity_not_found'] = 404
        browser.close()


try:
    main()
    report['result'] = 'PASS'
except Exception as error:
    report['result'] = 'FAIL'
    report['error'] = str(error)
    raise
finally:
    (OUT / 'browser-report.json').write_text(json.dumps(report, indent=2) + '\n')
