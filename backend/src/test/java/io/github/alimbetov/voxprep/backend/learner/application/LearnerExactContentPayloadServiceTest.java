package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class LearnerExactContentPayloadServiceTest {
    private final LearnerContentService content = mock(LearnerContentService.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final ContentAssetBindingRepository bindings = mock(ContentAssetBindingRepository.class);
    private final LearnerExactContentPayloadService service =
            new LearnerExactContentPayloadService(content, revisions, bindings);
    private final UUID revisionId = UUID.fromString("11111111-1111-4111-8111-111111111111");

    @Test
    void vocabularyMatchesFlutterDecoderFieldNames() {
        given(new ContentRevisionSnapshot.VocabularyBody("term", "definition", null, List.of("example")));
        var payload = service.get("vocabulary", "INTRO", 2);
        assertThat(payload.revision()).isEqualTo(2);
        assertThat(payload.checksum()).isEqualTo("b".repeat(64));
        assertThat(payload.categoryLabel()).isEqualTo("CATEGORY");
        assertThat(payload.hasAudio()).isFalse();
        assertThat(payload.body()).containsEntry("kind", "vocabulary").containsEntry("term", "term");
        assertThat(payload.body()).doesNotContainKey("partOfSpeech");
    }

    @Test
    void interviewAndTopicProduceTypedFlutterBodies() {
        given(new ContentRevisionSnapshot.InterviewBody("prompt", "model answer", List.of("point")));
        assertThat(service.get("vocabulary", "INTRO", 2).body()).containsEntry("kind", "interview");

        given(new ContentRevisionSnapshot.TopicBody(List.of(new ContentRevisionSnapshot.TopicSection("heading", "text"))));
        assertThat(service.get("vocabulary", "INTRO", 2).body()).containsEntry("kind", "topic");
    }

    @Test
    void phraseAndShadowingProduceTypedFlutterBodies() {
        given(new ContentRevisionSnapshot.PhraseBody("phrase", "usage", List.of("example")));
        assertThat(service.get("vocabulary", "INTRO", 2).body()).containsEntry("kind", "phrase");

        given(new ContentRevisionSnapshot.ShadowingBody("transcript", List.of(
                new ContentRevisionSnapshot.ShadowingSegment("first", null, null),
                new ContentRevisionSnapshot.ShadowingSegment("second", 100, 200))));
        var payload = service.get("vocabulary", "INTRO", 2);
        assertThat(payload.body()).containsEntry("kind", "shadowing");
        @SuppressWarnings("unchecked")
        var segments = (List<java.util.Map<String, Object>>) payload.body().get("segments");
        assertThat(segments.get(0)).containsEntry("order", 0).doesNotContainKey("startMs");
        assertThat(segments.get(1)).containsEntry("order", 1).containsEntry("startMs", 100);
    }

    @Test
    void hasAudioOnlyWhenReadyAudioBindingExists() {
        given(new ContentRevisionSnapshot.PhraseBody("phrase", "usage", List.of("example")));
        ContentAssetBindingEntity binding = mock(ContentAssetBindingEntity.class);
        FileAssetEntity asset = mock(FileAssetEntity.class);
        when(binding.getRole()).thenReturn(ContentAssetRole.PRONUNCIATION);
        when(binding.getFileAsset()).thenReturn(asset);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        when(asset.getKind()).thenReturn(FileAssetKind.TTS_AUDIO);
        when(bindings.findAllByContentRevision_IdOrderByRoleAsc(revisionId)).thenReturn(List.of(binding));
        assertThat(service.get("vocabulary", "INTRO", 2).hasAudio()).isTrue();
    }

    @Test
    void exactRevisionMismatchCannotReturnCurrentAsHistorical() {
        given(new ContentRevisionSnapshot.PhraseBody("phrase", "usage", List.of("example")));
        assertThatThrownBy(() -> service.get("vocabulary", "INTRO", 1))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    private void given(ContentRevisionSnapshot.Body body) {
        when(content.get("vocabulary", "INTRO")).thenReturn(new LearnerContentSnapshot(
                2, "a".repeat(64), "INTRO", "vocabulary", 2, "b".repeat(64),
                "Title", "Subtitle", "Description", "CATEGORY", "LEVEL", 5,
                List.of("LISTENING"), body));
        when(revisions.findIdByExactIdentity("INTRO", "vocabulary", 2))
                .thenReturn(java.util.Optional.of(revisionId));
        when(bindings.findAllByContentRevision_IdOrderByRoleAsc(revisionId)).thenReturn(List.of());
    }
}
