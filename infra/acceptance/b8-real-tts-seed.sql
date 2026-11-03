\set ON_ERROR_STOP on

SET ROLE voxprep_owner;

INSERT INTO app.content_revision (
    id, version, created_at, updated_at, content_code, content_type, revision_number,
    lifecycle, checksum_sha256, title, subtitle, description, category_code, level_code,
    minutes, availability, published_at
) VALUES (
    'b8000000-0000-0000-0000-000000000005', 0, now(), now(), 'B8_REAL_PIPER', 'phrase', 1,
    'DRAFT', :'content_sha', 'B8 real Piper acceptance', 'Backend to Worker',
    'Real end-to-end TTS acceptance fixture', 'TTS', 'B1', 1, 'ACTIVE', NULL
);

INSERT INTO app.file_asset (
    id, version, created_at, updated_at, kind, status, bucket, object_key, media_type, size_bytes, sha256
) VALUES
    ('b8000000-0000-0000-0000-000000000003', 0, now(), now(), 'TTS_MODEL', 'READY',
     'voxprep-assets', 'tts/models/b8/en_US-lessac-medium.onnx', 'application/octet-stream', :'model_size', :'model_sha'),
    ('b8000000-0000-0000-0000-000000000004', 0, now(), now(), 'TTS_CONFIG', 'READY',
     'voxprep-assets', 'tts/models/b8/en_US-lessac-medium.onnx.json', 'application/json', :'config_size', :'config_sha');

INSERT INTO app.tts_voice (
    id, version, created_at, updated_at, code, display_name, language, accent, gender, style, enabled, default_model_id
) VALUES (
    'b8000000-0000-0000-0000-000000000001', 0, now(), now(), 'b8-en-us-lessac',
    'B8 Lessac', 'en-US', 'US', NULL, 'neutral', true, NULL
);

INSERT INTO app.tts_voice_model (
    id, version, created_at, updated_at, code, voice_id, engine, engine_version, model_version,
    model_asset_id, config_asset_id, model_sha256, config_sha256, status,
    license_name, license_reference, commercial_use_reviewed, approved_at
) VALUES (
    'b8000000-0000-0000-0000-000000000002', 0, now(), now(), 'en_US-lessac-medium-b8',
    'b8000000-0000-0000-0000-000000000001', 'PIPER', '1.4.2',
    'rhasspy-piper-voices-a517d785',
    'b8000000-0000-0000-0000-000000000003', 'b8000000-0000-0000-0000-000000000004',
    :'model_sha', :'config_sha', 'ACTIVE', 'acceptance-fixture',
    'rhasspy/piper-voices@a517d785c98755ae1bb6c1bffd48a83e10c2f36f', false, now()
);

UPDATE app.tts_voice
   SET default_model_id = 'b8000000-0000-0000-0000-000000000002'
 WHERE id = 'b8000000-0000-0000-0000-000000000001';

INSERT INTO app.tts_job (
    id, version, created_at, updated_at, voice_model_id, input_text, input_sha256, status,
    output_asset_id, file_id, content_revision_id, audio_role, normalized_tts_text, language, fingerprint
) VALUES (
    'b8000000-0000-0000-0000-000000000006', 0, now(), now(),
    'b8000000-0000-0000-0000-000000000002', :'tts_text', :'text_sha', 'PENDING', NULL,
    'b8000000-0000-0000-0000-000000000007', 'b8000000-0000-0000-0000-000000000005',
    'PRIMARY', :'tts_text', 'en-US', :'fingerprint'
);

RESET ROLE;
