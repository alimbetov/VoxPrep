package io.github.alimbetov.voxprep.backend.content.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PracticeTestContentRevisionEntity;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.ObjectMapper;

class AssessmentDeliveryConfigurationServiceTest {
    private static final UUID TEST = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private static final UUID QUESTION = UUID.fromString("22222222-2222-4222-8222-222222222222");
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final AssessmentDeliveryConfigurationService service =
            new AssessmentDeliveryConfigurationService(jdbc, new ObjectMapper(), revisions);

    @Test
    void explicitlyStoresModeAndQuestionPointsForUnpublishedRevision() {
        var draft = mock(PracticeTestContentRevisionEntity.class);
        when(revisions.lockRevisionIdForUpdate(TEST)).thenReturn(Optional.of(TEST));
        when(revisions.findById(TEST)).thenReturn(Optional.of(draft));
        when(draft.getQuestionRevisionIds()).thenReturn(List.of(QUESTION));

        var result = service.configure(TEST, "exam", List.of(3));

        assertThat(result.mode()).isEqualTo("exam");
        assertThat(result.points()).containsExactly(3);
        verify(jdbc).update(anyString(), eq(TEST), eq("exam"), eq("[3]"));
    }

    @Test
    void publishedPracticeTestCannotBeRetrofittedWithNewPoints() {
        var published = mock(PracticeTestContentRevisionEntity.class);
        when(revisions.lockRevisionIdForUpdate(TEST)).thenReturn(Optional.of(TEST));
        when(revisions.findById(TEST)).thenReturn(Optional.of(published));
        when(published.getPublishedAt()).thenReturn(Instant.parse("2026-11-03T10:00:00Z"));

        assertThatThrownBy(() -> service.configure(TEST, "learn", List.of(1)))
                .isInstanceOf(IllegalStateException.class);
        verifyNoInteractions(jdbc);
    }

    @Test
    void cannotInferModeOrPointsFromAuthoringDefaults() {
        var draft = mock(PracticeTestContentRevisionEntity.class);
        when(revisions.lockRevisionIdForUpdate(TEST)).thenReturn(Optional.of(TEST));
        when(revisions.findById(TEST)).thenReturn(Optional.of(draft));
        when(draft.getQuestionRevisionIds()).thenReturn(List.of(QUESTION));

        assertThatThrownBy(() -> service.configure(TEST, "unknown", List.of(1)))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.configure(TEST, "exam", List.of()))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.configure(TEST, "exam", List.of(1, 2)))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(jdbc);
    }
}
