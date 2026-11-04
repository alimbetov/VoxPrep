package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.tts.domain.AudioRequirement;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ContentTtsPlannerTest {

    private final ContentTtsPlanner planner = new ContentTtsPlanner();

    @Test
    void plansVocabularyTermOnly() {
        var revision = snapshot(
                ContentType.VOCABULARY,
                new ContentRevisionSnapshot.VocabularyBody(
                        "  encapsulation  ",
                        "Should not be spoken",
                        "noun",
                        List.of("Should not be spoken either")));

        assertThat(planner.plan(revision, "en-us"))
                .containsExactly(new TtsUtterance(
                        ContentAudioRole.PRONUNCIATION,
                        AudioRequirement.OPTIONAL,
                        "encapsulation",
                        "en-US",
                        TtsTextNormalizer.VERSION));
    }

    @Test
    void plansPhraseTextOnly() {
        var revision = snapshot(
                ContentType.PHRASE,
                new ContentRevisionSnapshot.PhraseBody(
                        "Could   you tell me more?",
                        "Should not be spoken",
                        List.of("Should not be spoken")));

        assertThat(planner.plan(revision, "en-US"))
                .containsExactly(new TtsUtterance(
                        ContentAudioRole.PRONUNCIATION,
                        AudioRequirement.RECOMMENDED,
                        "Could you tell me more?",
                        "en-US",
                        TtsTextNormalizer.VERSION));
    }

    @Test
    void plansIndependentInterviewQuestionAndSampleAnswer() {
        var revision = snapshot(
                ContentType.INTERVIEW,
                new ContentRevisionSnapshot.InterviewBody(
                        "What is dependency injection?",
                        "It is a design pattern.",
                        List.of("IoC", "testability")));

        assertThat(planner.plan(revision, "en-US"))
                .containsExactly(
                        new TtsUtterance(
                                ContentAudioRole.QUESTION,
                                AudioRequirement.RECOMMENDED,
                                "What is dependency injection?",
                                "en-US",
                                TtsTextNormalizer.VERSION),
                        new TtsUtterance(
                                ContentAudioRole.SAMPLE_ANSWER,
                                AudioRequirement.RECOMMENDED,
                                "It is a design pattern.",
                                "en-US",
                                TtsTextNormalizer.VERSION));
    }

    @Test
    void plansOneTopicNarrationFromOrderedSectionTextWithoutHeadings() {
        var revision = snapshot(
                ContentType.TOPIC,
                new ContentRevisionSnapshot.TopicBody(List.of(
                        new ContentRevisionSnapshot.TopicSection("Heading one", " First   section. "),
                        new ContentRevisionSnapshot.TopicSection("Heading two", "Second section."))));

        assertThat(planner.plan(revision, "en-US"))
                .containsExactly(new TtsUtterance(
                        ContentAudioRole.NARRATION,
                        AudioRequirement.OPTIONAL,
                        "First section.\n\nSecond section.",
                        "en-US",
                        TtsTextNormalizer.VERSION));
    }

    @Test
    void rejectsTopicWhenAnySectionNormalizesToBlank() {
        var revision = snapshot(
                ContentType.TOPIC,
                new ContentRevisionSnapshot.TopicBody(List.of(
                        new ContentRevisionSnapshot.TopicSection("Heading one", "First section."),
                        new ContentRevisionSnapshot.TopicSection("Heading two", " \t\r\n "))));

        assertThatThrownBy(() -> planner.plan(revision, "en-US"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("must not be blank");
    }

    @Test
    void plansShadowingFromTranscriptOnly() {
        var revision = snapshot(
                ContentType.SHADOWING,
                new ContentRevisionSnapshot.ShadowingBody(
                        "Good morning.\nThank you for inviting me.",
                        List.of(new ContentRevisionSnapshot.ShadowingSegment("segment metadata", 0, 1000))));

        assertThat(planner.plan(revision, "en-US"))
                .containsExactly(new TtsUtterance(
                        ContentAudioRole.SHADOWING,
                        AudioRequirement.REQUIRED,
                        "Good morning.\nThank you for inviting me.",
                        "en-US",
                        TtsTextNormalizer.VERSION));
    }

    @Test
    void rejectsQuestionAndPracticeTest() {
        var question = snapshot(
                ContentType.QUESTION,
                new ContentRevisionSnapshot.QuestionBody(
                        "Question?", "Explanation", List.of(
                                new ContentRevisionSnapshot.QuestionOption("A", "Answer", true))));
        var practiceTest = snapshot(
                ContentType.PRACTICE_TEST,
                new ContentRevisionSnapshot.PracticeTestBody("Instructions", 70, List.of()));

        assertThatThrownBy(() -> planner.plan(question, "en-US"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("not supported");
        assertThatThrownBy(() -> planner.plan(practiceTest, "en-US"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("not supported");
    }

    @Test
    void rejectsMismatchedContentTypeAndBody() {
        var invalid = snapshot(
                ContentType.PHRASE,
                new ContentRevisionSnapshot.VocabularyBody("term", "definition", "noun", List.of("example")));

        assertThatThrownBy(() -> planner.plan(invalid, "en-US"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("does not match content type");
    }

    @Test
    void rejectsNullBodyFailClosed() {
        var invalid = snapshot(ContentType.PHRASE, null);

        assertThatThrownBy(() -> planner.plan(invalid, "en-US"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("does not match content type");
    }

    @Test
    void rejectsInvalidLanguageTag() {
        var revision = snapshot(
                ContentType.PHRASE,
                new ContentRevisionSnapshot.PhraseBody("Hello", "usage", List.of("example")));

        assertThatThrownBy(() -> planner.plan(revision, "___"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("BCP-47");
    }

    private static ContentRevisionSnapshot snapshot(
            ContentType contentType,
            ContentRevisionSnapshot.Body body) {
        return new ContentRevisionSnapshot(
                UUID.fromString("11111111-1111-1111-1111-111111111111"),
                0,
                "CONTENT_001",
                contentType,
                1,
                ContentLifecycleStatus.DRAFT,
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "Title",
                "Subtitle",
                "Description",
                "CATEGORY",
                "B1",
                5,
                List.of("SPEAKING"),
                AvailabilityStatus.ACTIVE,
                null,
                null,
                body);
    }
}
