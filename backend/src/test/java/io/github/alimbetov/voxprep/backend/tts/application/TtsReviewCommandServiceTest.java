package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicy;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class TtsReviewCommandServiceTest {
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final TtsVoiceModelRepository models = mock(TtsVoiceModelRepository.class);
    private final TtsJobPreparationService preparation = mock(TtsJobPreparationService.class);
    private final ContentAudioPolicy policy = new ContentAudioPolicy();
    private final TtsReviewCommandService review =
            new TtsReviewCommandService(revisions, models, preparation, policy);

    private final UUID revisionId = UUID.randomUUID();
    private final VocabularyContentRevisionEntity revision = mock(VocabularyContentRevisionEntity.class);

    @BeforeEach
    void setup() {
        when(revisions.findById(revisionId)).thenReturn(Optional.of(revision));
    }

    @Test
    void draftCannotEnqueueAudioEvenWhenRoleIsValid() {
        when(revision.getLifecycle()).thenReturn(ContentLifecycleStatus.DRAFT);

        assertThatThrownBy(() -> review.prepare(revisionId, "pronunciation", "en-model"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("READY_FOR_AUDIO");

        verifyNoInteractions(models, preparation);
    }

    @Test
    void unsupportedAudioRoleCannotEnqueueJob() {
        when(revision.getLifecycle()).thenReturn(ContentLifecycleStatus.READY_FOR_AUDIO);
        when(revision.getContentType()).thenReturn(ContentType.VOCABULARY);

        assertThatThrownBy(() -> review.prepare(revisionId, "sampleAnswer", "en-model"))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(models, preparation);
    }

    @Test
    void existingFingerprintIsReusedThroughAuthoritativePreparationService() {
        when(revision.getLifecycle()).thenReturn(ContentLifecycleStatus.READY_FOR_AUDIO);
        when(revision.getContentType()).thenReturn(ContentType.VOCABULARY);
        var model = mock(TtsVoiceModelEntity.class);
        var voice = mock(TtsVoiceEntity.class);
        when(models.findByCode("en-model")).thenReturn(Optional.of(model));
        when(model.selectableForNewJobs()).thenReturn(true);
        when(model.getVoice()).thenReturn(voice);
        when(voice.getLanguage()).thenReturn("en-US");
        when(model.getCode()).thenReturn("en-model");
        var existing = new TtsJobPreparationService.PreparationResult(
                UUID.randomUUID(), UUID.randomUUID(), "a".repeat(64), true);
        when(preparation.prepare(revisionId, ContentAudioRole.PRONUNCIATION, "en-US", "en-model"))
                .thenReturn(existing);

        assertThat(review.prepare(revisionId, "pronunciation", "en-model").reused()).isTrue();
        verify(preparation).prepare(revisionId, ContentAudioRole.PRONUNCIATION, "en-US", "en-model");
    }
}
