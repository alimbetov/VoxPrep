package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionOptionEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingSegmentEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicSectionEmbeddable;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

@Component
class ContentMvcMapper {

    ContentMvcForms.DraftForm toForm(ContentRevisionSnapshot snapshot) {
        var form = new ContentMvcForms.DraftForm();
        form.setExpectedVersion(snapshot.version());
        form.setTitle(snapshot.title());
        form.setSubtitle(snapshot.subtitle());
        form.setDescription(snapshot.description());
        form.setCategoryCode(snapshot.categoryCode());
        form.setLevelCode(snapshot.levelCode());
        form.setMinutes(snapshot.minutes());
        form.setSkillCodes(String.join("\n", snapshot.skillCodes()));
        form.setAvailability(snapshot.availability().name());
        form.setBodyType(snapshot.contentType().wireName());
        switch (snapshot.body()) {
            case ContentRevisionSnapshot.VocabularyBody body -> {
                form.setTerm(body.term());
                form.setDefinition(body.definition());
                form.setPartOfSpeech(body.partOfSpeech());
                form.setExamples(lines(body.examples()));
            }
            case ContentRevisionSnapshot.InterviewBody body -> {
                form.setPrompt(body.prompt());
                form.setModelAnswer(body.modelAnswer());
                form.setKeyPoints(lines(body.keyPoints()));
            }
            case ContentRevisionSnapshot.TopicBody body -> form.setSections(body.sections().stream()
                    .map(value -> value.heading() + "|" + value.text())
                    .collect(Collectors.joining("\n")));
            case ContentRevisionSnapshot.PhraseBody body -> {
                form.setPhrase(body.phrase());
                form.setUsage(body.usage());
                form.setExamples(lines(body.examples()));
            }
            case ContentRevisionSnapshot.ShadowingBody body -> {
                form.setTranscript(body.transcript());
                form.setSegments(body.segments().stream()
                        .map(value -> nullable(value.startMs()) + "|" + nullable(value.endMs()) + "|" + value.text())
                        .collect(Collectors.joining("\n")));
            }
            case ContentRevisionSnapshot.QuestionBody body -> {
                form.setQuestionText(body.questionText());
                form.setExplanation(body.explanation());
                form.setOptions(body.options().stream()
                        .map(value -> value.key() + "|" + value.correct() + "|" + value.text())
                        .collect(Collectors.joining("\n")));
            }
            case ContentRevisionSnapshot.PracticeTestBody body -> {
                form.setInstructions(body.instructions());
                form.setPassingScorePercent(body.passingScorePercent());
                form.setQuestionRevisionIds(body.questionRevisionIds().stream()
                        .map(UUID::toString)
                        .collect(Collectors.joining("\n")));
            }
        }
        return form;
    }

    ContentDraftUpdate toCommand(ContentMvcForms.DraftForm form) {
        var body = body(form);
        return new ContentDraftUpdate(
                checksum(form),
                form.getTitle(),
                form.getSubtitle(),
                form.getDescription(),
                new CatalogueCode(form.getCategoryCode()),
                new CatalogueCode(form.getLevelCode()),
                form.getMinutes(),
                nonBlankLines(form.getSkillCodes()).stream().map(CatalogueCode::new).toList(),
                AvailabilityStatus.valueOf(form.getAvailability()),
                body);
    }

    private static ContentDraftUpdate.Body body(ContentMvcForms.DraftForm form) {
        return switch (form.getBodyType()) {
            case "vocabulary" -> new ContentDraftUpdate.VocabularyBody(
                    require(form.getTerm(), "term"),
                    require(form.getDefinition(), "definition"),
                    require(form.getPartOfSpeech(), "partOfSpeech"),
                    nonBlankLines(form.getExamples()));
            case "interview" -> new ContentDraftUpdate.InterviewBody(
                    require(form.getPrompt(), "prompt"),
                    require(form.getModelAnswer(), "modelAnswer"),
                    nonBlankLines(form.getKeyPoints()));
            case "topic" -> new ContentDraftUpdate.TopicBody(nonBlankLines(form.getSections()).stream()
                    .map(ContentMvcMapper::topicSection)
                    .toList());
            case "phrase" -> new ContentDraftUpdate.PhraseBody(
                    require(form.getPhrase(), "phrase"),
                    require(form.getUsage(), "usage"),
                    nonBlankLines(form.getExamples()));
            case "shadowing" -> new ContentDraftUpdate.ShadowingBody(
                    require(form.getTranscript(), "transcript"),
                    nonBlankLines(form.getSegments()).stream().map(ContentMvcMapper::segment).toList());
            case "question" -> new ContentDraftUpdate.QuestionBody(
                    require(form.getQuestionText(), "questionText"),
                    require(form.getExplanation(), "explanation"),
                    nonBlankLines(form.getOptions()).stream().map(ContentMvcMapper::option).toList());
            case "practice_test" -> new ContentDraftUpdate.PracticeTestBody(
                    require(form.getInstructions(), "instructions"),
                    require(form.getPassingScorePercent(), "passingScorePercent"),
                    nonBlankLines(form.getQuestionRevisionIds()).stream().map(UUID::fromString).toList());
            default -> throw new IllegalArgumentException("Unsupported content body type: " + form.getBodyType());
        };
    }

    private static TopicSectionEmbeddable topicSection(String line) {
        var parts = split(line, 2, "section must use heading|text");
        return new TopicSectionEmbeddable(parts[0], parts[1]);
    }

    private static ShadowingSegmentEmbeddable segment(String line) {
        var parts = line.split("\\|", 3);
        if (parts.length != 3 || parts[2].isBlank()) {
            throw new IllegalArgumentException("segment must use startMs|endMs|text");
        }
        return new ShadowingSegmentEmbeddable(parts[2], integerOrNull(parts[0]), integerOrNull(parts[1]));
    }

    private static QuestionOptionEmbeddable option(String line) {
        var parts = split(line, 3, "option must use key|true|text");
        if (!parts[1].equals("true") && !parts[1].equals("false")) {
            throw new IllegalArgumentException("option correct flag must be true or false");
        }
        return new QuestionOptionEmbeddable(parts[0], parts[2], Boolean.parseBoolean(parts[1]));
    }

    private static String[] split(String value, int limit, String message) {
        var parts = value.split("\\|", limit);
        if (parts.length != limit || Arrays.stream(parts).anyMatch(String::isBlank)) {
            throw new IllegalArgumentException(message);
        }
        return parts;
    }

    private static List<String> nonBlankLines(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        return value.lines().map(String::trim).filter(line -> !line.isBlank()).toList();
    }

    private static String lines(List<String> values) {
        return String.join("\n", values);
    }

    private static String nullable(Object value) {
        return value == null ? "" : value.toString();
    }

    private static Integer integerOrNull(String value) {
        return value.isBlank() ? null : Integer.valueOf(value);
    }

    private static <T> T require(T value, String name) {
        if (value == null || value instanceof String text && text.isBlank()) {
            throw new IllegalArgumentException(name + " is required");
        }
        return value;
    }

    private static Sha256Digest checksum(ContentMvcForms.DraftForm form) {
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            var canonical = String.join("\u001f",
                    nullSafe(form.getBodyType()), nullSafe(form.getTitle()), nullSafe(form.getSubtitle()),
                    nullSafe(form.getDescription()), nullSafe(form.getCategoryCode()), nullSafe(form.getLevelCode()),
                    Integer.toString(form.getMinutes()), nullSafe(form.getSkillCodes()), nullSafe(form.getAvailability()),
                    nullSafe(form.getTerm()), nullSafe(form.getDefinition()), nullSafe(form.getPartOfSpeech()),
                    nullSafe(form.getExamples()), nullSafe(form.getPrompt()), nullSafe(form.getModelAnswer()),
                    nullSafe(form.getKeyPoints()), nullSafe(form.getSections()), nullSafe(form.getPhrase()),
                    nullSafe(form.getUsage()), nullSafe(form.getTranscript()), nullSafe(form.getSegments()),
                    nullSafe(form.getQuestionText()), nullSafe(form.getExplanation()), nullSafe(form.getOptions()),
                    nullSafe(form.getInstructions()), String.valueOf(form.getPassingScorePercent()),
                    nullSafe(form.getQuestionRevisionIds()));
            return new Sha256Digest(HexFormat.of().formatHex(digest.digest(canonical.getBytes(StandardCharsets.UTF_8))));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is not available", exception);
        }
    }

    private static String nullSafe(String value) {
        return value == null ? "" : value;
    }
}
