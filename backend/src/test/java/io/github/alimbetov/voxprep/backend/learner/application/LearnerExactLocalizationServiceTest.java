package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class LearnerExactLocalizationServiceTest {
    private final UUID id = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private final LearnerContentService content = mock(LearnerContentService.class);
    private final CurrentPublicationResolver publication = mock(CurrentPublicationResolver.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final ContentLocalizationRevisionRepository localizations = mock(ContentLocalizationRevisionRepository.class);
    private final LearnerExactLocalizationService service =
            new LearnerExactLocalizationService(content, publication, revisions, localizations);

    @Test
    void returnsOnlyApprovedExactLocalizationRevision() {
        givenCurrent();
        var approved = localization(2, ContentLocalizationLifecycleStatus.APPROVED,
                Instant.parse("2026-11-02T10:00:00Z"));
        when(localizations.findAllByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberAsc(id, "ru"))
                .thenReturn(List.of(approved));

        var result = service.get("phrase", "HELLO", 1, "ru", 2);

        assertThat(result.locale()).isEqualTo("ru");
        assertThat(result.localizationRevision()).isEqualTo(2);
        assertThat(result.checksum()).isEqualTo("c".repeat(64));
        assertThat(result.translation()).isEqualTo("Привет");
    }

    @Test
    void refusesPostPublicationLocalizationApproval() {
        givenCurrent();
        var later = localization(2, ContentLocalizationLifecycleStatus.APPROVED,
                Instant.parse("2026-11-04T10:00:00Z"));
        when(localizations.findAllByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberAsc(id, "ru"))
                .thenReturn(List.of(later));

        assertThatThrownBy(() -> service.get("phrase", "HELLO", 1, "ru", 2))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void refusesDraftAndWrongExactRevision() {
        givenCurrent();
        var draft = localization(2, ContentLocalizationLifecycleStatus.DRAFT, null);
        when(localizations.findAllByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberAsc(id, "ru"))
                .thenReturn(List.of(draft));
        assertThatThrownBy(() -> service.get("phrase", "HELLO", 1, "ru", 2))
                .isInstanceOf(LearnerContentNotFoundException.class);
        assertThatThrownBy(() -> service.get("phrase", "HELLO", 2, "ru", 2))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    private void givenCurrent() {
        when(content.get("phrase", "HELLO")).thenReturn(new LearnerContentSnapshot(
                1, "a".repeat(64), "HELLO", "phrase", 1, "b".repeat(64),
                "Hello", "Subtitle", "Description", "CATEGORY", "LEVEL", 5,
                List.of("LISTENING"),
                new ContentRevisionSnapshot.PhraseBody("Hello", "Greeting", List.of("Hi"))));
        when(revisions.findIdByExactIdentity("HELLO", "phrase", 1))
                .thenReturn(java.util.Optional.of(id));
        when(publication.resolve()).thenReturn(new CurrentPublicationSnapshot(
                1, "a".repeat(64), Instant.parse("2026-11-03T12:00:00Z"), List.of(
                new io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef(
                    new io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity(
                        new io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode("HELLO"),
                        io.github.alimbetov.voxprep.backend.content.domain.ContentType.PHRASE,
                        new io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber(1)),
                    new io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest("b".repeat(64))))));
    }

    private ContentLocalizationRevisionEntity localization(
            int number, ContentLocalizationLifecycleStatus lifecycle, Instant approvedAt) {
        var value = mock(ContentLocalizationRevisionEntity.class);
        when(value.getLocalizationRevisionNumber()).thenReturn(number);
        when(value.getLifecycle()).thenReturn(lifecycle);
        when(value.getApprovedAt()).thenReturn(approvedAt);
        when(value.getChecksumSha256()).thenReturn("c".repeat(64));
        when(value.getTranslation()).thenReturn("Привет");
        return value;
    }
}
