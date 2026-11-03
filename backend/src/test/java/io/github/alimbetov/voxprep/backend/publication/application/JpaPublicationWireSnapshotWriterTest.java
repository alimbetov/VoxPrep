package io.github.alimbetov.voxprep.backend.publication.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.*;
import io.github.alimbetov.voxprep.backend.content.domain.*;
import io.github.alimbetov.voxprep.backend.content.application.AssessmentDeliveryConfigurationService;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.*;
import io.github.alimbetov.voxprep.backend.learner.application.FlutterPublicationCanonicalHash;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.*;
import io.github.alimbetov.voxprep.backend.sharedkernel.*;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import tools.jackson.databind.ObjectMapper;

class JpaPublicationWireSnapshotWriterTest {
    private static final UUID RELEASE = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private static final UUID VERTICAL = UUID.fromString("22222222-2222-4222-8222-222222222222");
    private static final UUID GOAL = UUID.fromString("33333333-3333-4333-8333-333333333333");
    private static final UUID TRACK = UUID.fromString("44444444-4444-4444-8444-444444444444");
    private static final UUID COLLECTION = UUID.fromString("55555555-5555-4555-8555-555555555555");
    private static final UUID REVISION = UUID.fromString("66666666-6666-4666-8666-666666666666");
    private static final Instant NOW = Instant.parse("2026-11-03T11:30:00Z");

    private final VerticalRepository verticals = mock(VerticalRepository.class);
    private final LearningGoalRepository goals = mock(LearningGoalRepository.class);
    private final LearningTrackRepository tracks = mock(LearningTrackRepository.class);
    private final LearningCollectionRepository collections = mock(LearningCollectionRepository.class);
    private final CollectionContentMemberRepository members = mock(CollectionContentMemberRepository.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final AssessmentDeliveryConfigurationService assessment = mock(AssessmentDeliveryConfigurationService.class);
    private final ContentAssetBindingRepository bindings = mock(ContentAssetBindingRepository.class);
    private final ContentLocalizationRevisionRepository localizations = mock(ContentLocalizationRevisionRepository.class);
    private final PublicationWireDocumentRepository docs = mock(PublicationWireDocumentRepository.class);
    private final ObjectMapper json = new ObjectMapper();
    private final JpaPublicationWireSnapshotWriter writer = new JpaPublicationWireSnapshotWriter(
            verticals, goals, tracks, collections, members, revisions,
            assessment, bindings, localizations, docs, json);
    private final PublicationReleaseEntity release = mock(PublicationReleaseEntity.class);
    private final PublicationExactContentRef ref = new PublicationExactContentRef(
            new ContentRevisionIdentity(new BusinessCode("PHRASE_ONE"), ContentType.PHRASE,
                    new RevisionNumber(1)), new Sha256Digest("b".repeat(64)));

    @BeforeEach
    void setup() {
        when(release.getId()).thenReturn(RELEASE);
        when(release.getContentVersion()).thenReturn(5L);
        when(docs.existsByRelease_Id(RELEASE)).thenReturn(false);
    }

    @Test
    void createsAllEightFrozenDocumentsIncludingFreeCollectionBeforeCurrentSwitch() throws Exception {
        graph(true);
        writer.freeze(release, List.of(ref), NOW);

        ArgumentCaptor<PublicationWireDocumentEntity> capture =
                ArgumentCaptor.forClass(PublicationWireDocumentEntity.class);
        verify(docs, times(8)).save(capture.capture());
        verify(docs).flush();
        var stored = capture.getAllValues();
        var roots = stored.stream().filter(doc -> doc.getKind() == PublicationWireDocumentKind.ROOT).toList();
        assertThat(roots).hasSize(1);
        var root = roots.get(0);
        assertThat(root.getResourceCode()).isEqualTo("root");
        assertThat(root.getRevision()).isEqualTo(5);
        @SuppressWarnings("unchecked")
        Map<String, Object> rootBody = json.readValue(root.getBodyJson(), Map.class);
        assertThat(rootBody).containsEntry("schemaVersion", 2);
        assertThat(rootBody).containsEntry("contentVersion", 5);
        assertThat(root.getChecksumSha256())
                .isEqualTo(FlutterPublicationCanonicalHash.root(json, rootBody));
        assertThat((List<?>) rootBody.get("catalogues")).hasSize(6);
        assertThat((List<?>) rootBody.get("packs")).hasSize(1);

        var pack = stored.stream().filter(doc -> doc.getKind() == PublicationWireDocumentKind.PACK)
                .findFirst().orElseThrow();
        @SuppressWarnings("unchecked")
        Map<String, Object> packBody = json.readValue(pack.getBodyJson(), Map.class);
        assertThat(pack.getChecksumSha256())
                .isEqualTo(FlutterPublicationCanonicalHash.pack(json, packBody));
        assertThat((List<?>) packBody.get("contents")).hasSize(1);

        var collectionDoc = stored.stream()
                .filter(doc -> doc.getKind() == PublicationWireDocumentKind.CATALOGUE)
                .filter(doc -> "learning-collections".equals(doc.getResourceCode()))
                .findFirst().orElseThrow();
        @SuppressWarnings("unchecked")
        Map<String, Object> collectionsBody = json.readValue(collectionDoc.getBodyJson(), Map.class);
        @SuppressWarnings("unchecked")
        Map<String, Object> collection = (Map<String, Object>) ((List<?>) collectionsBody.get("items")).get(0);
        assertThat(collection).containsEntry("accessLevel", "FREE");
        assertThat((List<?>) collection.get("members")).hasSize(1);
    }

    @Test
    void refusesToPublishActiveEmptyCollection() {
        graph(false);

        assertThatThrownBy(() -> writer.freeze(release, List.of(ref), NOW))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("no published members");
        verify(docs, never()).save(any());
    }

    @Test
    void rejectsOrphanRevisionNotAssignedToPublishedCollection() {
        graph(true);
        var other = new PublicationExactContentRef(
                new ContentRevisionIdentity(new BusinessCode("OTHER"), ContentType.PHRASE,
                        new RevisionNumber(2)), new Sha256Digest("c".repeat(64)));

        assertThatThrownBy(() -> writer.freeze(release, List.of(ref, other), NOW))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("lacks active collection");
        verify(docs, never()).save(any());
    }

    @Test
    void orphanPublishedQuestionCannotAppearInFrozenRoot() {
        graph(true);
        var question = new PublicationExactContentRef(
                new ContentRevisionIdentity(new BusinessCode("ORPHAN_QUESTION"),
                        ContentType.QUESTION, new RevisionNumber(1)),
                new Sha256Digest("c".repeat(64)));

        assertThatThrownBy(() -> writer.freeze(release, List.of(ref, question), NOW))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("no published practice-test owner");
        verify(docs, never()).save(any());
    }

    private void graph(boolean withMember) {
        var vertical = mock(VerticalEntity.class);
        var goal = mock(LearningGoalEntity.class);
        var track = mock(LearningTrackEntity.class);
        var collection = mock(LearningCollectionEntity.class);

        when(verticals.findAllByOrderBySortOrderAscCodeAsc()).thenReturn(List.of(vertical));
        when(vertical.getAvailability()).thenReturn(AvailabilityStatus.ACTIVE);
        when(vertical.getId()).thenReturn(VERTICAL);
        when(vertical.getCode()).thenReturn(new CatalogueCode("CAREER"));
        when(vertical.getSectionCode()).thenReturn(new CatalogueCode("TECH"));
        when(vertical.getTitle()).thenReturn("Career");
        when(vertical.getDescription()).thenReturn("Career description");
        when(vertical.getIconAssetId()).thenReturn("career-icon");
        when(vertical.getSortOrder()).thenReturn(0);

        when(goals.findAllByVertical_IdOrderBySortOrderAscCodeAsc(VERTICAL)).thenReturn(List.of(goal));
        when(goal.getAvailability()).thenReturn(AvailabilityStatus.ACTIVE);
        when(goal.getId()).thenReturn(GOAL);
        when(goal.getCode()).thenReturn(new CatalogueCode("INTERVIEW"));
        when(goal.getTitle()).thenReturn("Interview");
        when(goal.getDescription()).thenReturn("Goal description");
        when(goal.getSortOrder()).thenReturn(0);

        when(tracks.findAllByGoal_IdOrderBySortOrderAscCodeAsc(GOAL)).thenReturn(List.of(track));
        when(track.getAvailability()).thenReturn(AvailabilityStatus.ACTIVE);
        when(track.getId()).thenReturn(TRACK);
        when(track.getCode()).thenReturn(new CatalogueCode("JAVA"));
        when(track.getTitle()).thenReturn("Java");
        when(track.getDescription()).thenReturn("Track description");
        when(track.getLevelCode()).thenReturn(new CatalogueCode("B2"));
        when(track.getSortOrder()).thenReturn(0);

        when(collections.findAllByTrack_IdOrderBySortOrderAscCodeAsc(TRACK))
                .thenReturn(List.of(collection));
        when(collection.getAvailability()).thenReturn(AvailabilityStatus.ACTIVE);
        when(collection.getId()).thenReturn(COLLECTION);
        when(collection.getCode()).thenReturn(new CatalogueCode("JAVA_FIRST"));
        when(collection.getTitle()).thenReturn("Start");
        when(collection.getDescription()).thenReturn("First block");
        when(collection.getAccessLevel()).thenReturn(CollectionAccessLevel.FREE);
        when(collection.getSortOrder()).thenReturn(0);

        if (withMember) {
            var member = mock(CollectionContentMemberEntity.class);
            var revision = mock(PhraseContentRevisionEntity.class);
            when(members.findAllByCollectionIdOrderByPositionAsc(COLLECTION))
                    .thenReturn(List.of(member));
            when(member.getPosition()).thenReturn(0);
            when(member.getContentRevision()).thenReturn(revision);
            when(revision.getIdentity()).thenReturn(ref.identity());
            when(revision.getChecksum()).thenReturn(ref.checksum());
            when(revision.getContentType()).thenReturn(ContentType.PHRASE);
            when(revision.getContentCode()).thenReturn(new BusinessCode("PHRASE_ONE"));
            when(revision.getId()).thenReturn(REVISION);
        } else {
            when(members.findAllByCollectionIdOrderByPositionAsc(COLLECTION))
                    .thenReturn(List.of());
        }
    }
}
