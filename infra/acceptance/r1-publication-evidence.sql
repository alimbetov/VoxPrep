-- R1 read-only PostgreSQL evidence. Executed after real A1 HTTP authoring
-- and N -> N+1 publication, before docker-compose removes test database.
-- No credentials, customer data or raw body_json are exported.
\pset pager off
\pset format csv
\echo evidence_publication_current
SELECT pc.singleton_id, pc.release_id::text AS current_release_id,
       pr.content_version, pr.root_sha256, pr.candidate_id::text AS candidate_id,
       pr.published_at
FROM app.publication_current pc
JOIN app.publication_release pr ON pr.id = pc.release_id
WHERE pc.singleton_id = 1;
\echo evidence_release_history
SELECT pr.id::text AS release_id, pr.content_version, pr.root_sha256,
       pr.candidate_id::text AS candidate_id, pr.published_at
FROM app.publication_release pr
ORDER BY pr.content_version;
\echo evidence_approved_exact_content_refs
SELECT pr.content_version, mr.position, mr.content_code, mr.content_type,
       mr.revision_number, mr.checksum_sha256,
       cr.lifecycle, cr.checksum_sha256 AS persisted_revision_sha256,
       (mr.checksum_sha256 = cr.checksum_sha256) AS checksum_matches
FROM app.publication_release pr
JOIN app.publication_candidate_manifest_ref mr ON mr.candidate_id = pr.candidate_id
JOIN app.content_revision cr ON cr.content_code = mr.content_code
  AND cr.content_type = mr.content_type
  AND cr.revision_number = mr.revision_number
ORDER BY pr.content_version, mr.position;
\echo evidence_immutable_wire_snapshots
SELECT pr.content_version, wd.document_kind, wd.resource_code, wd.variant,
       wd.revision, wd.checksum_sha256, length(wd.body_json) AS body_length
FROM app.publication_release pr
JOIN app.publication_wire_document wd ON wd.release_id = pr.id
ORDER BY pr.content_version, wd.document_kind, wd.resource_code, wd.variant, wd.revision;
