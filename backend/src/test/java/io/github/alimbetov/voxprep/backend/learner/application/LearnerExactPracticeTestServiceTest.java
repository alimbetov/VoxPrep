package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.*;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

class LearnerExactPracticeTestServiceTest {
    private static final UUID RELEASE = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private final ObjectMapper json = new ObjectMapper();
    private final CurrentPublicationResolver resolver = mock(CurrentPublicationResolver.class);
    private final PublicationCurrentRepository current = mock(PublicationCurrentRepository.class);
    private final PublicationWireDocumentRepository documents = mock(PublicationWireDocumentRepository.class);
    private final LearnerExactPracticeTestService service =
            new LearnerExactPracticeTestService(resolver, current, documents, json);

    @BeforeEach
    void publication() {
        var test = exact(ContentType.PRACTICE_TEST, "TEST_01", 2, "b".repeat(64));
        var question = exact(ContentType.QUESTION, "Q_01", 1, "c".repeat(64));
        when(resolver.resolve()).thenReturn(new CurrentPublicationSnapshot(
                7, "a".repeat(64), Instant.parse("2026-11-03T12:00:00Z"),
                List.of(test, question)));
        var pointer = mock(PublicationCurrentEntity.class);
        var release = mock(PublicationReleaseEntity.class);
        when(current.findById(PublicationCurrentEntity.SINGLETON_ID)).thenReturn(Optional.of(pointer));
        when(pointer.getRelease()).thenReturn(release);
        when(release.getId()).thenReturn(RELEASE);
        when(release.getContentVersion()).thenReturn(7L);
    }

    @Test
    void returnsStrictDtoWithExactPublishedQuestionPoints() throws Exception {
        stubDocument(validBody(), null);
        var value = service.get("TEST_01", 2);

        assertThat(value.practiceTestCode()).isEqualTo("TEST_01");
        assertThat(value.mode()).isEqualTo("exam");
        assertThat(value.passingScoreBasisPoints()).isEqualTo(8500);
        assertThat(value.questionRefs()).hasSize(1);
        assertThat(value.questionRefs().get(0).points()).isEqualTo(3);
        assertThat(value.questionRefs().get(0).question().checksum()).isEqualTo("c".repeat(64));
    }

    @Test
    void cannotFetchDifferentExactRevision() {
        assertThatThrownBy(() -> service.get("TEST_01", 1))
                .isInstanceOf(LearnerContentNotFoundException.class);
        verifyNoInteractions(documents);
    }

    @Test
    void tamperingFrozenPointsFailsClosed() throws Exception {
        stubDocument(validBody(), "0".repeat(64));
        assertThatThrownBy(() -> service.get("TEST_01", 2))
                .isInstanceOf(LearnerWireSnapshotUnavailableException.class);
    }

    @Test
    void unknownPublishedQuestionFailsClosed() throws Exception {
        var body = validBody();
        var ref = new LinkedHashMap<String, Object>();
        ref.put("order", 0);
        ref.put("question", Map.of("questionCode", "UNPUBLISHED", "revision", 1,
                "checksum", "d".repeat(64)));
        ref.put("points", 3);
        body.put("questionRefs", List.of(ref));
        stubDocument(body, null);
        assertThatThrownBy(() -> service.get("TEST_01", 2))
                .isInstanceOf(LearnerWireSnapshotUnavailableException.class);
    }

    private LinkedHashMap<String, Object> validBody() {
        var body = new LinkedHashMap<String, Object>();
        body.put("practiceTestCode", "TEST_01");
        body.put("revision", 2);
        body.put("checksum", "b".repeat(64));
        body.put("title", "Interview");
        body.put("subtitle", "Java");
        body.put("mode", "exam");
        body.put("passingScoreBasisPoints", 8500);
        body.put("questionRefs", List.of(Map.of("order", 0,
                "question", Map.of("questionCode", "Q_01",
                        "revision", 1, "checksum", "c".repeat(64)), "points", 3)));
        return body;
    }

    private void stubDocument(Map<String, Object> body, String tamperedDigest) throws Exception {
        String encoded = json.writeValueAsString(body);
        String sha = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                .digest(encoded.getBytes(StandardCharsets.UTF_8)));
        var doc = mock(PublicationWireDocumentEntity.class);
        when(doc.getBodyJson()).thenReturn(encoded);
        when(doc.getChecksumSha256()).thenReturn(tamperedDigest == null ? sha : tamperedDigest);
        when(documents.findByRelease_IdAndKindAndResourceCodeAndVariantAndRevision(
                RELEASE, PublicationWireDocumentKind.ASSESSMENT, "TEST_01", "-", 7L))
                .thenReturn(Optional.of(doc));
    }

    private static PublicationExactContentRef exact(
            ContentType type, String code, int rev, String checksum) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(new BusinessCode(code), type, new RevisionNumber(rev)),
                new Sha256Digest(checksum));
    }
}
