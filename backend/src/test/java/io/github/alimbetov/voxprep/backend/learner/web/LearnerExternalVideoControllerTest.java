package io.github.alimbetov.voxprep.backend.learner.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.doThrow;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.asset.application.ExternalLearningVideoService;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentSnapshot;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentNotFoundException;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPremiumAccessDeniedException;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LearnerExternalVideoControllerTest {
    private final LearnerContentAccessPolicy access = mock(LearnerContentAccessPolicy.class);
    private final LearnerContentService content = mock(LearnerContentService.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final ExternalLearningVideoService videos = mock(ExternalLearningVideoService.class);

    @Test
    void premiumVideoHttpDenialUsesLearner403ForBothFeatureFlagStates() throws Exception {
        doThrow(new LearnerPremiumAccessDeniedException())
                .when(access).requireAccessible("phrase", "PREMIUM");
        for (boolean enabled : new boolean[] {false, true}) {
            var mvc = MockMvcBuilders.standaloneSetup(controller(enabled))
                    .setControllerAdvice(new LearnerContentExceptionHandler()).build();
            mvc.perform(get("/api/v2/content/phrase/PREMIUM/external-video"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("PREMIUM_UNLOCK_REQUIRED"));
        }
        verifyNoInteractions(content, revisions, videos);
    }

    @Test
    void unpublishedVideoHttpRequestUsesLearner404WithoutReadingDraftMetadata() throws Exception {
        doThrow(new LearnerContentNotFoundException("phrase", "DRAFT_ONLY"))
                .when(access).requireAccessible("phrase", "DRAFT_ONLY");
        var mvc = MockMvcBuilders.standaloneSetup(controller(true))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get("/api/v2/content/phrase/DRAFT_ONLY/external-video"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("LEARNER_CONTENT_NOT_FOUND"));
        verifyNoInteractions(content, revisions, videos);
    }

    @Test
    void disabledFlagDoesNotReadPublishedMetadata() {
        var controller = controller(false);
        var result = controller.read("phrase", "PHRASE1");

        assertThat(result.getStatusCode().value()).isEqualTo(204);
        assertThat(result.getHeaders().getCacheControl()).contains("no-store");
        verify(access).requireAccessible("phrase", "PHRASE1");
        verifyNoInteractions(content, revisions, videos);
    }

    @Test
    void deniedContentNeverRevealsVideoEvenWhenEnabled() {
        doThrow(new AccessDeniedException("FULL entitlement required"))
                .when(access).requireAccessible("phrase", "PREMIUM");
        assertThatThrownBy(() -> controller(true).read("phrase", "PREMIUM"))
                .isInstanceOf(AccessDeniedException.class);
        verifyNoInteractions(content, revisions, videos);
    }

    @Test
    void noFrozenVideoReturns204WithoutReturningDraftMetadata() {
        UUID revisionId = UUID.randomUUID();
        stubCurrent(revisionId);
        when(videos.findPublished(revisionId)).thenReturn(Optional.empty());

        var response = controller(true).read("phrase", "PHRASE1");

        assertThat(response.getStatusCode().value()).isEqualTo(204);
        verify(videos).findPublished(revisionId);
        verify(videos, never()).find(revisionId);
    }

    @Test
    void returnsOnlyFrozenVideoScopedToExactCurrentPublication() {
        UUID revisionId = UUID.randomUUID();
        stubCurrent(revisionId);
        when(videos.findPublished(revisionId)).thenReturn(Optional.of(
                new ExternalLearningVideoService.Video("YOUTUBE", "AbCdEfGh123", "Interview video")));

        var response = controller(true).read("phrase", "PHRASE1");

        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getHeaders().getCacheControl()).contains("no-store");
        var value = response.getBody();
        assertThat(value).isNotNull();
        assertThat(value.schemaVersion()).isEqualTo(1);
        assertThat(value.contentType()).isEqualTo("phrase");
        assertThat(value.contentCode()).isEqualTo("PHRASE1");
        assertThat(value.revision()).isEqualTo(3);
        assertThat(value.contentVersion()).isEqualTo(14);
        assertThat(value.rootSha256()).isEqualTo("a".repeat(64));
        assertThat(value.url()).isEqualTo("https://www.youtube.com/watch?v=AbCdEfGh123");
        verify(videos, never()).find(revisionId);
    }

    private void stubCurrent(UUID id) {
        var current = mock(LearnerContentSnapshot.class);
        when(current.contentCode()).thenReturn("PHRASE1");
        when(current.contentType()).thenReturn("phrase");
        when(current.revisionNumber()).thenReturn(3);
        when(current.contentVersion()).thenReturn(14L);
        when(current.rootSha256()).thenReturn("a".repeat(64));
        when(content.get("phrase", "PHRASE1")).thenReturn(current);
        when(revisions.findIdByExactIdentity("PHRASE1", "phrase", 3)).thenReturn(Optional.of(id));
    }

    private LearnerExternalVideoController controller(boolean enabled) {
        return new LearnerExternalVideoController(access, content, revisions, videos, enabled);
    }
}
