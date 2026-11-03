package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentKind;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentRepository;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

class LearnerWirePublicationServiceTest {

    private static final UUID RELEASE = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private final ObjectMapper json = new ObjectMapper();
    private final PublicationCurrentRepository current = mock(PublicationCurrentRepository.class);
    private final PublicationWireDocumentRepository documents = mock(PublicationWireDocumentRepository.class);
    private final LearnerWirePublicationService service = new LearnerWirePublicationService(current, documents, json);

    @BeforeEach
    void currentPublication() {
        PublicationCurrentEntity pointer = mock(PublicationCurrentEntity.class);
        PublicationReleaseEntity release = mock(PublicationReleaseEntity.class);
        PublicationCandidateEntity candidate = mock(PublicationCandidateEntity.class);
        when(current.findById(PublicationCurrentEntity.SINGLETON_ID)).thenReturn(Optional.of(pointer));
        when(pointer.getRelease()).thenReturn(release);
        when(release.getId()).thenReturn(RELEASE);
        when(release.getContentVersion()).thenReturn(3L);
        when(release.getCandidate()).thenReturn(candidate);
        when(release.getRootSha256()).thenReturn("a".repeat(64));
        when(candidate.getRootSha256()).thenReturn("a".repeat(64));
        when(candidate.getStatus()).thenReturn(PublicationCandidateStatus.PUBLISHED);
    }

    @Test
    void missingFrozenRootFailsClosedRatherThanReadingMutableCatalogues() {
        assertThatThrownBy(service::root)
                .isInstanceOf(LearnerWireSnapshotUnavailableException.class);
    }

    @Test
    void servesRootWithFlutterCanonicalChecksumAndSixRequiredCatalogues() throws Exception {
        String checksum = publishedRoot();
        var result = service.root();
        assertThat(result.checksum()).isEqualTo(checksum);
        assertThat(result.body()).containsEntry("contentVersion", 3);
        assertThat(result.body()).containsEntry("schemaVersion", 2);
    }

    @Test
    void exactPackMustBelongToFrozenRootAndMatchItsChecksum() throws Exception {
        publishedRoot();
        var pack = packBody();
        String checksum = FlutterPublicationCanonicalHash.pack(json, pack);
        pack.put("checksum", checksum);
        stub(PublicationWireDocumentKind.PACK, "COLLECTION_A", "canonical", 3, pack, checksum);
        var response = service.pack("COLLECTION_A", "canonical", 3);
        assertThat(response.checksum()).isEqualTo(checksum);
        assertThat(response.body()).containsEntry("variant", "canonical");
    }

    @Test
    void packOutsideRootIsNotAccessibleEvenIfDocumentExists() throws Exception {
        publishedRoot();
        assertThatThrownBy(() -> service.pack("NOT_PUBLISHED", "canonical", 3))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void publishedPackWithWrongDocumentDigestIsRejected() throws Exception {
        publishedRoot();
        var pack = packBody();
        pack.put("checksum", "b".repeat(64));
        stub(PublicationWireDocumentKind.PACK, "COLLECTION_A", "canonical", 3, pack, "b".repeat(64));
        assertThatThrownBy(() -> service.pack("COLLECTION_A", "canonical", 3))
                .isInstanceOf(LearnerWireSnapshotUnavailableException.class);
    }

    @Test
    void catalogueMustMatchFrozenRootReference() throws Exception {
        publishedRoot();
        var body = new LinkedHashMap<String, Object>();
        body.put("kind", "learning-collections");
        body.put("revision", 3);
        body.put("checksum", "c".repeat(64));
        body.put("items", List.of());
        stub(PublicationWireDocumentKind.CATALOGUE, "learning-collections", "-", 3, body, "c".repeat(64));
        var result = service.catalogue("learning-collections", 3);
        assertThat(result.body()).containsEntry("kind", "learning-collections");
        assertThatThrownBy(() -> service.catalogue("learning-collections", 99))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void tamperedRootChecksumCannotBecomeCurrent() throws Exception {
        var root = rootBody();
        root.put("checksum", "0".repeat(64));
        stub(PublicationWireDocumentKind.ROOT, "root", "-", 3, root, "0".repeat(64));
        assertThatThrownBy(service::root)
                .isInstanceOf(LearnerWireSnapshotUnavailableException.class);
    }

    @Test
    void rootWithMissingUniversalCatalogueIsRejected() throws Exception {
        var root = rootBody();
        root.put("catalogues", List.of());
        String checksum = FlutterPublicationCanonicalHash.root(json, root);
        root.put("checksum", checksum);
        stub(PublicationWireDocumentKind.ROOT, "root", "-", 3, root, checksum);
        assertThatThrownBy(service::root)
                .isInstanceOf(LearnerWireSnapshotUnavailableException.class);
    }

    private String publishedRoot() throws Exception {
        var root = rootBody();
        String checksum = FlutterPublicationCanonicalHash.root(json, root);
        root.put("checksum", checksum);
        stub(PublicationWireDocumentKind.ROOT, "root", "-", 3, root, checksum);
        return checksum;
    }

    private LinkedHashMap<String, Object> rootBody() {
        var root = new LinkedHashMap<String, Object>();
        root.put("schemaVersion", 2);
        root.put("contentVersion", 3);
        root.put("minimumAppContractVersion", 3);
        root.put("publishedAt", "2026-11-03T12:00:00Z");
        root.put("packs", List.of(Map.of("code", "COLLECTION_A", "variant", "canonical",
                "revision", 3, "checksum", FlutterPublicationCanonicalHash.pack(json, packBody()))));
        root.put("practiceTests", List.of());
        root.put("catalogues", List.of(
                catalogueRef("vertical-sections"),
                catalogueRef("verticals"),
                catalogueRef("vertical-presentation"),
                catalogueRef("learning-goals"),
                catalogueRef("learning-tracks"),
                catalogueRef("learning-collections")));
        root.put("localeFallbacks", List.of());
        root.put("tombstones", List.of());
        return root;
    }

    private static Map<String, Object> catalogueRef(String kind) {
        return Map.of("kind", kind, "revision", 3, "checksum", "c".repeat(64));
    }

    private static LinkedHashMap<String, Object> packBody() {
        var pack = new LinkedHashMap<String, Object>();
        pack.put("schemaVersion", 2);
        pack.put("code", "COLLECTION_A");
        pack.put("variant", "canonical");
        pack.put("revision", 3);
        pack.put("contents", List.of());
        pack.put("localizations", List.of());
        pack.put("assets", List.of());
        pack.put("contentAssets", List.of());
        return pack;
    }

    private void stub(
            PublicationWireDocumentKind kind, String code, String variant,
            long revision, Map<String, Object> body, String checksum) throws Exception {
        var document = mock(PublicationWireDocumentEntity.class);
        when(document.getBodyJson()).thenReturn(json.writeValueAsString(body));
        when(document.getChecksumSha256()).thenReturn(checksum);
        when(documents.findByRelease_IdAndKindAndResourceCodeAndVariantAndRevision(
                RELEASE, kind, code, variant, revision)).thenReturn(Optional.of(document));
    }


}
