package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicy;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicyEntry;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

public final class ContentTtsPlanner {

    private final ContentAudioPolicy audioPolicy;
    private final TtsTextNormalizer textNormalizer;

    public ContentTtsPlanner() {
        this(new ContentAudioPolicy(), new TtsTextNormalizer());
    }

    public ContentTtsPlanner(ContentAudioPolicy audioPolicy, TtsTextNormalizer textNormalizer) {
        this.audioPolicy = Objects.requireNonNull(audioPolicy, "audioPolicy");
        this.textNormalizer = Objects.requireNonNull(textNormalizer, "textNormalizer");
    }

    public List<TtsUtterance> plan(ContentRevisionSnapshot revision, String language) {
        Objects.requireNonNull(revision, "revision");
        String canonicalLanguage = canonicalLanguage(language);

        return switch (revision.contentType()) {
            case VOCABULARY -> planVocabulary(revision, canonicalLanguage);
            case PHRASE -> planPhrase(revision, canonicalLanguage);
            case INTERVIEW -> planInterview(revision, canonicalLanguage);
            case TOPIC -> planTopic(revision, canonicalLanguage);
            case SHADOWING -> planShadowing(revision, canonicalLanguage);
            case QUESTION, PRACTICE_TEST -> throw new IllegalArgumentException(
                    "TTS is not supported for content type " + revision.contentType().wireName());
        };
    }

    private List<TtsUtterance> planVocabulary(ContentRevisionSnapshot revision, String language) {
        var body = requireBody(revision, ContentRevisionSnapshot.VocabularyBody.class);
        return List.of(utterance(revision.contentType(), ContentAudioRole.PRONUNCIATION, body.term(), language));
    }

    private List<TtsUtterance> planPhrase(ContentRevisionSnapshot revision, String language) {
        var body = requireBody(revision, ContentRevisionSnapshot.PhraseBody.class);
        return List.of(utterance(revision.contentType(), ContentAudioRole.PRONUNCIATION, body.phrase(), language));
    }

    private List<TtsUtterance> planInterview(ContentRevisionSnapshot revision, String language) {
        var body = requireBody(revision, ContentRevisionSnapshot.InterviewBody.class);
        return List.of(
                utterance(revision.contentType(), ContentAudioRole.QUESTION, body.prompt(), language),
                utterance(revision.contentType(), ContentAudioRole.SAMPLE_ANSWER, body.modelAnswer(), language));
    }

    private List<TtsUtterance> planTopic(ContentRevisionSnapshot revision, String language) {
        var body = requireBody(revision, ContentRevisionSnapshot.TopicBody.class);
        if (body.sections() == null || body.sections().isEmpty()) {
            throw new IllegalArgumentException("TOPIC sections must not be empty for TTS planning");
        }
        String narration = body.sections().stream()
                .map(ContentRevisionSnapshot.TopicSection::text)
                .map(textNormalizer::normalize)
                .reduce((left, right) -> left + "\n\n" + right)
                .orElseThrow();
        return List.of(utterance(revision.contentType(), ContentAudioRole.NARRATION, narration, language));
    }

    private List<TtsUtterance> planShadowing(ContentRevisionSnapshot revision, String language) {
        var body = requireBody(revision, ContentRevisionSnapshot.ShadowingBody.class);
        return List.of(utterance(revision.contentType(), ContentAudioRole.SHADOWING, body.transcript(), language));
    }

    private TtsUtterance utterance(
            ContentType contentType,
            ContentAudioRole role,
            String sourceText,
            String language) {
        ContentAudioPolicyEntry policyEntry = audioPolicy.requireAllowed(contentType, role);
        return new TtsUtterance(
                role,
                policyEntry.requirement(),
                textNormalizer.normalize(sourceText),
                language,
                TtsTextNormalizer.VERSION);
    }

    private static <T extends ContentRevisionSnapshot.Body> T requireBody(
            ContentRevisionSnapshot revision,
            Class<T> expectedType) {
        if (!expectedType.isInstance(revision.body())) {
            throw new IllegalArgumentException(
                    "Content body does not match content type " + revision.contentType().wireName());
        }
        return expectedType.cast(revision.body());
    }

    private static String canonicalLanguage(String value) {
        Objects.requireNonNull(value, "language");
        String candidate = value.strip();
        if (candidate.isEmpty()) {
            throw new IllegalArgumentException("language must not be blank");
        }
        String canonical = Locale.forLanguageTag(candidate).toLanguageTag();
        if (canonical.isBlank() || "und".equalsIgnoreCase(canonical)) {
            throw new IllegalArgumentException("language must be a valid BCP-47 tag");
        }
        return canonical;
    }
}
