package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentKind;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

/**
 * Exact Flutter practice-test DTO read from immutable release wire snapshot.
 * No mutable assessment configuration or guessed mode/points at read time.
 */
@Service
public class LearnerExactPracticeTestService {

    private final CurrentPublicationResolver publication;
    private final PublicationCurrentRepository current;
    private final PublicationWireDocumentRepository documents;
    private final ObjectMapper json;

    public LearnerExactPracticeTestService(
            CurrentPublicationResolver publication,
            PublicationCurrentRepository current,
            PublicationWireDocumentRepository documents,
            ObjectMapper json) {
        this.publication = Objects.requireNonNull(publication);
        this.current = Objects.requireNonNull(current);
        this.documents = Objects.requireNonNull(documents);
        this.json = Objects.requireNonNull(json);
    }

    @Transactional(readOnly = true)
    public ExactPracticeTest get(String code, int revision) {
        if (revision < 1) {
            throw new IllegalArgumentException("practice-test revision must be positive");
        }
        var snapshot = publication.resolve();
        var exact = snapshot.refs().stream()
                .filter(ref -> ref.identity().contentType() == ContentType.PRACTICE_TEST)
                .filter(ref -> ref.identity().contentCode().value().equals(code))
                .filter(ref -> ref.identity().revisionNumber().value() == revision)
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException("practice_test", code));

        var pointer = current.findById(PublicationCurrentEntity.SINGLETON_ID)
                .orElseThrow(() -> unavailable("CURRENT publication pointer missing"));
        var release = pointer.getRelease();
        if (release == null || release.getContentVersion() != snapshot.contentVersion()) {
            throw unavailable("CURRENT publication changed during assessment resolution");
        }
        var document = documents.findByRelease_IdAndKindAndResourceCodeAndVariantAndRevision(
                        release.getId(), PublicationWireDocumentKind.ASSESSMENT,
                        code, "-", release.getContentVersion())
                .orElseThrow(() -> unavailable("frozen practice-test document is missing"));

        try {
            var actual = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(document.getBodyJson().getBytes(StandardCharsets.UTF_8)));
            if (!actual.equals(document.getChecksumSha256())) {
                throw unavailable("frozen assessment document checksum mismatch");
            }
            @SuppressWarnings("unchecked")
            Map<String, Object> body = json.readValue(document.getBodyJson(), Map.class);
            if (!body.keySet().equals(Set.of("practiceTestCode", "revision", "checksum",
                    "title", "subtitle", "mode", "passingScoreBasisPoints", "questionRefs"))
                    || !code.equals(body.get("practiceTestCode"))
                    || !exact.checksum().value().equals(body.get("checksum"))
                    || !(body.get("revision") instanceof Integer number) || number != revision) {
                throw unavailable("practice-test payload does not match published identity");
            }
            String mode = readText(body, "mode");
            if (!Set.of("learn", "exam", "quick").contains(mode)) {
                throw unavailable("unsupported published assessment mode");
            }
            int threshold = readNumber(body, "passingScoreBasisPoints");
            if (threshold < 1 || threshold > 10000) {
                throw unavailable("invalid published passing-score threshold");
            }
            if (!(body.get("questionRefs") instanceof List<?> refs) || refs.isEmpty()) {
                throw unavailable("published assessment question refs are empty");
            }
            var questions = new java.util.ArrayList<QuestionRef>();
            Set<String> seen = new HashSet<>();
            for (int i = 0; i < refs.size(); i++) {
                if (!(refs.get(i) instanceof Map<?, ?> entry)
                        || !entry.keySet().equals(Set.of("order", "question", "points"))
                        || !(entry.get("order") instanceof Integer order) || order != i
                        || !(entry.get("points") instanceof Integer points) || points <= 0
                        || !(entry.get("question") instanceof Map<?, ?> question)
                        || !question.keySet().equals(Set.of("questionCode", "revision", "checksum"))) {
                    throw unavailable("invalid ordered practice-test question reference");
                }
                String questionCode = String.valueOf(question.get("questionCode"));
                if (questionCode.isBlank()
                        || !(question.get("revision") instanceof Integer questionRevision)
                        || questionRevision <= 0
                        || !(question.get("checksum") instanceof String checksum)
                        || !checksum.matches("[0-9a-f]{64}")) {
                    throw unavailable("invalid published question identity");
                }
                var match = snapshot.refs().stream().anyMatch(ref ->
                        ref.identity().contentType() == ContentType.QUESTION
                                && ref.identity().contentCode().value().equals(questionCode)
                                && ref.identity().revisionNumber().value() == questionRevision
                                && ref.checksum().value().equals(checksum));
                if (!match || !seen.add(questionCode + "|" + questionRevision)) {
                    throw unavailable("practice test references missing or duplicate published question");
                }
                questions.add(new QuestionRef(i, new QuestionIdentity(
                        questionCode, questionRevision, checksum), points));
            }
            return new ExactPracticeTest(code, revision, exact.checksum().value(),
                    readText(body, "title"), readText(body, "subtitle"),
                    mode, threshold, List.copyOf(questions));
        } catch (LearnerWireSnapshotUnavailableException exception) {
            throw exception;
        } catch (Exception exception) {
            throw unavailable("cannot validate frozen practice-test payload");
        }
    }

    private static String readText(Map<String, Object> value, String key) {
        Object raw = value.get(key);
        if (!(raw instanceof String text) || text.isBlank()) {
            throw unavailable("required assessment text is missing: " + key);
        }
        return text;
    }

    private static int readNumber(Map<String, Object> value, String key) {
        if (!(value.get(key) instanceof Integer n)) {
            throw unavailable("required assessment number is missing: " + key);
        }
        return n;
    }

    private static LearnerWireSnapshotUnavailableException unavailable(String detail) {
        return new LearnerWireSnapshotUnavailableException(detail);
    }

    public record ExactPracticeTest(
            String practiceTestCode,
            int revision,
            String checksum,
            String title,
            String subtitle,
            String mode,
            int passingScoreBasisPoints,
            List<QuestionRef> questionRefs) {
        public ExactPracticeTest {
            questionRefs = List.copyOf(questionRefs);
        }
    }

    public record QuestionRef(int order, QuestionIdentity question, int points) {
    }

    public record QuestionIdentity(String questionCode, int revision, String checksum) {
    }
}
