package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import org.junit.jupiter.api.Test;

class ContentMvcMapperTest {

    private final ContentMvcMapper mapper = new ContentMvcMapper();

    @Test
    void mapsAllSupportedBodyTypes() {
        assertThat(mapper.toCommand(base("vocabulary", form -> {
            form.setTerm("term"); form.setDefinition("definition"); form.setPartOfSpeech("noun"); form.setExamples("one\ntwo");
        })).body()).isInstanceOf(ContentDraftUpdate.VocabularyBody.class);

        assertThat(mapper.toCommand(base("interview", form -> {
            form.setPrompt("prompt"); form.setModelAnswer("answer"); form.setKeyPoints("one\ntwo");
        })).body()).isInstanceOf(ContentDraftUpdate.InterviewBody.class);

        assertThat(mapper.toCommand(base("topic", form -> form.setSections("Heading|Text"))).body())
                .isInstanceOf(ContentDraftUpdate.TopicBody.class);

        assertThat(mapper.toCommand(base("phrase", form -> {
            form.setPhrase("phrase"); form.setUsage("usage"); form.setExamples("example");
        })).body()).isInstanceOf(ContentDraftUpdate.PhraseBody.class);

        assertThat(mapper.toCommand(base("shadowing", form -> {
            form.setTranscript("transcript"); form.setSegments("10|20|segment");
        })).body()).isInstanceOf(ContentDraftUpdate.ShadowingBody.class);

        assertThat(mapper.toCommand(base("question", form -> {
            form.setQuestionText("question"); form.setExplanation("explanation"); form.setOptions("A|true|answer");
        })).body()).isInstanceOf(ContentDraftUpdate.QuestionBody.class);

        assertThat(mapper.toCommand(base("practice_test", form -> {
            form.setInstructions("instructions"); form.setPassingScorePercent(80);
            form.setQuestionRevisionIds("00000000-0000-0000-0000-000000000001");
        })).body()).isInstanceOf(ContentDraftUpdate.PracticeTestBody.class);
    }

    private static ContentMvcForms.DraftForm base(
            String bodyType,
            java.util.function.Consumer<ContentMvcForms.DraftForm> body) {
        var form = new ContentMvcForms.DraftForm();
        form.setExpectedVersion(0L);
        form.setTitle("Title");
        form.setSubtitle("Subtitle");
        form.setDescription("Description");
        form.setCategoryCode("CATEGORY");
        form.setLevelCode("B2");
        form.setMinutes(5);
        form.setSkillCodes("SPEAKING");
        form.setAvailability("ACTIVE");
        form.setBodyType(bodyType);
        body.accept(form);
        return form;
    }
}
