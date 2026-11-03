package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentKind;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentRepository;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

/**
 * API-R2 read model. Never reconstruct published manifests from mutable
 * catalogue rows; the Flutter checksum is NOT the legacy B6 candidate-ref SHA.
 *
 * <p>Existing releases with no immutable wire snapshot fail closed with 503.
 */
@Service
public class LearnerWirePublicationService {

    private static final List<String> REQUIRED_CATALOGUES = List.of(
            "vertical-sections", "verticals", "vertical-presentation",
            "learning-goals", "learning-tracks", "learning-collections");

    private final PublicationCurrentRepository currentRepository;
    private final PublicationWireDocumentRepository documentRepository;
    private final ObjectMapper json;

    public LearnerWirePublicationService(
            PublicationCurrentRepository currentRepository,
            PublicationWireDocumentRepository documentRepository,
            ObjectMapper json) {
        this.currentRepository = Objects.requireNonNull(currentRepository);
        this.documentRepository = Objects.requireNonNull(documentRepository);
        this.json = Objects.requireNonNull(json);
    }

    @Transactional(readOnly = true)
    public WireResponse root() {
        var release = currentRelease();
        return verifiedRoot(release);
    }

    @Transactional(readOnly = true)
    public WireResponse pack(String code, String variant, int revision) {
        if (revision < 1 || !validCode(code)
                || !("canonical".equals(variant) || (variant != null && variant.matches("locale:[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*")))) {
            throw new IllegalArgumentException("invalid pack identity or revision");
        }
        var release = currentRelease();
        var root = verifiedRoot(release);
        String checksum = listedChecksum(root.body(), "packs",
                "code", code, "variant", variant, revision);
        var document = requireDocument(release, PublicationWireDocumentKind.PACK, code, variant, revision);
        var body = decode(document);
        requireIdentity(body, "code", code);
        requireIdentity(body, "variant", variant);
        requireNumber(body, "revision", revision);
        if (!checksum.equals(document.getChecksumSha256())) {
            throw unavailable("pack checksum differs from frozen root");
        }
        verifyDigest(document, body, false);
        return new WireResponse(body, checksum);
    }

    @Transactional(readOnly = true)
    public WireResponse catalogue(String kind, int revision) {
        if (revision < 1 || kind == null || !kind.matches("[a-z]+(?:-[a-z]+)*")) {
            throw new IllegalArgumentException("invalid catalogue kind or revision");
        }
        var release = currentRelease();
        var root = verifiedRoot(release);
        String checksum = listedChecksum(root.body(), "catalogues",
                "kind", kind, null, null, revision);
        var document = requireDocument(release, PublicationWireDocumentKind.CATALOGUE, kind, "-", revision);
        var body = decode(document);
        requireIdentity(body, "kind", kind);
        requireNumber(body, "revision", revision);
        if (!body.keySet().equals(java.util.Set.of("kind", "revision", "checksum", "items"))
                || !(body.get("items") instanceof List<?>)
                || !checksum.equals(document.getChecksumSha256())) {
            throw unavailable("catalogue document does not match frozen root");
        }
        return new WireResponse(body, checksum);
    }

    private PublicationReleaseEntity currentRelease() {
        var current = currentRepository.findById(PublicationCurrentEntity.SINGLETON_ID)
                .orElseThrow(() -> unavailable("publication current pointer is absent"));
        var release = current.getRelease();
        if (release == null || release.getCandidate() == null
                || release.getCandidate().getStatus() != PublicationCandidateStatus.PUBLISHED
                || !release.getRootSha256().equals(release.getCandidate().getRootSha256())) {
            throw unavailable("CURRENT publication is inconsistent");
        }
        return release;
    }

    private WireResponse verifiedRoot(PublicationReleaseEntity release) {
        var document = requireDocument(release, PublicationWireDocumentKind.ROOT,
                "root", "-", release.getContentVersion());
        var body = decode(document);
        requireNumber(body, "contentVersion", release.getContentVersion());
        verifyDigest(document, body, true);
        int schemaVersion = number(body, "schemaVersion");
        if (schemaVersion < 1 || schemaVersion > 2) {
            throw unavailable("unsupported root manifest version");
        }
        if (!(body.get("packs") instanceof List<?> packs) || packs.isEmpty()
                || !(body.get("catalogues") instanceof List<?> catalogues)) {
            throw unavailable("root manifest is missing packs or catalogues");
        }
        if (schemaVersion == 2) {
            for (String required : REQUIRED_CATALOGUES) {
                if (catalogues.stream().noneMatch(item -> item instanceof Map<?, ?> ref
                        && required.equals(ref.get("kind")))) {
                    throw unavailable("required universal catalogue is absent");
                }
            }
        }
        return new WireResponse(body, document.getChecksumSha256());
    }

    private String listedChecksum(
            Map<String, Object> root, String listKey,
            String codeKey, String code, String variantKey, String variant, long revision) {
        Object entries = root.get(listKey);
        if (!(entries instanceof List<?> refs)) {
            throw unavailable("root manifest lacks " + listKey);
        }
        for (Object entry : refs) {
            if (entry instanceof Map<?, ?> ref
                    && code.equals(ref.get(codeKey))
                    && (variantKey == null || variant.equals(ref.get(variantKey)))
                    && ref.get("revision") instanceof Number number
                    && number.longValue() == revision
                    && ref.get("checksum") instanceof String checksum
                    && checksum.matches("[0-9a-f]{64}")) {
                return checksum;
            }
        }
        throw new LearnerContentNotFoundException(listKey, code);
    }

    private PublicationWireDocumentEntity requireDocument(
            PublicationReleaseEntity release, PublicationWireDocumentKind kind,
            String code, String variant, long revision) {
        return documentRepository.findByRelease_IdAndKindAndResourceCodeAndVariantAndRevision(
                        release.getId(), kind, code, variant, revision)
                .orElseThrow(() -> unavailable("immutable " + kind + " document is missing"));
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> decode(PublicationWireDocumentEntity document) {
        try {
            Object parsed = json.readValue(document.getBodyJson(), Map.class);
            if (!(parsed instanceof Map<?, ?> raw)
                    || raw.keySet().stream().anyMatch(key -> !(key instanceof String))) {
                throw unavailable("wire document is not a JSON object");
            }
            Map<String, Object> body = (Map<String, Object>) raw;
            if (!document.getChecksumSha256().equals(body.get("checksum"))) {
                throw unavailable("wire document checksum differs from metadata");
            }
            return java.util.Collections.unmodifiableMap(new LinkedHashMap<>(body));
        } catch (LearnerWireSnapshotUnavailableException exception) {
            throw exception;
        } catch (Exception exception) {
            throw unavailable("cannot parse immutable wire document");
        }
    }

    private void verifyDigest(
            PublicationWireDocumentEntity document, Map<String, Object> body, boolean root) {
        try {
            String actual = root
                    ? FlutterPublicationCanonicalHash.root(json, body)
                    : FlutterPublicationCanonicalHash.pack(json, body);
            if (!actual.equals(document.getChecksumSha256())) {
                throw unavailable("wire document Flutter checksum mismatch");
            }
        } catch (LearnerWireSnapshotUnavailableException exception) {
            throw exception;
        } catch (RuntimeException exception) {
            throw unavailable("wire document cannot be canonically verified");
        }
    }

    private static boolean validCode(String code) {
        return code != null && code.matches("[A-Za-z0-9][A-Za-z0-9._-]*");
    }

    private static void requireIdentity(Map<String, Object> value, String field, String expected) {
        if (!expected.equals(value.get(field))) {
            throw unavailable("wire identity mismatch for " + field);
        }
    }

    private static void requireNumber(Map<String, Object> value, String field, long expected) {
        if (!(value.get(field) instanceof Number n) || n.longValue() != expected) {
            throw unavailable("wire revision mismatch for " + field);
        }
    }

    private static int number(Map<String, Object> value, String field) {
        if (!(value.get(field) instanceof Number n)) {
            throw unavailable("wire numeric field is missing");
        }
        return n.intValue();
    }

    private static LearnerWireSnapshotUnavailableException unavailable(String reason) {
        return new LearnerWireSnapshotUnavailableException(reason);
    }

    public record WireResponse(Map<String, Object> body, String checksum) {
        public WireResponse {
            body = java.util.Collections.unmodifiableMap(new LinkedHashMap<>(body));
            if (checksum == null || !checksum.matches("[0-9a-f]{64}")) {
                throw new IllegalArgumentException("checksum must be lowercase SHA-256");
            }
        }
    }
}
