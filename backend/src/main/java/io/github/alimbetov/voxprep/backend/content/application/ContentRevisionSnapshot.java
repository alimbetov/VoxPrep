package io.github.alimbetov.voxprep.backend.content.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.InterviewContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record ContentRevisionSnapshot(
        UUID id,
        long version,
        String contentCode,
        ContentType contentType,
        int revisionNumber,
        ContentLifecycleStatus lifecycle,
        String checksumSha256,
        String title,
        String subtitle,
        String description,
        String categoryCode,
        String levelCode,
        int minutes,
        List<String> skillCodes,
        AvailabilityStatus availability,
        Instant approvedAt,
        Instant publishedAt,
        Body body) {

    public static ContentRevisionSnapshot from(ContentRevisionEntity entity) {
        return new ContentRevisionSnapshot(
                entity.getId(),
                entity.getVersion(),
                entity.getContentCode().value(),
                entity.getContentType(),
                entity.getRevisionNumber().value(),
                entity.getLifecycle(),
                entity.getChecksum().value(),
                entity.getTitle(),
                entity.getSubtitle(),
                entity.getDescription(),
                entity.getCategoryCode().value(),
                entity.getLevelCode().value(),
                entity.getMinutes(),
                entity.getSkillCodes().stream().map(code -> code.value()).toList(),
                entity.getAvailability(),
                entity.getApprovedAt(),
                entity.getPublishedAt(),
                body(entity));
    }

    private static Body body(ContentRevisionEntity entity) {
        if (entity instanceof VocabularyContentRevisionEntity value) {
            return new VocabularyBody(value.getTerm(), value.getDefinition(), value.getPartOfSpeech(), value.getExamples());
        }
        if (entity instanceof InterviewContentRevisionEntity value) {
            return new InterviewBody(value.getPrompt(), value.getModelAnswer(), value.getKeyPoints());
        }
        if (entity instanceof TopicContentRevisionEntity value) {
            return new TopicBody(value.getSections().stream()
                    .map(section -> new TopicSection(section.getHeading(), section.getText()))
                    .toList());
        }
        if (entity instanceof PhraseContentRevisionEntity value) {
            return new PhraseBody(value.getPhrase(), value.getUsage(), value.getExamples());
        }
        if (entity instanceof ShadowingContentRevisionEntity value) {
            return new ShadowingBody(value.getTranscript(), value.getSegments().stream()
                    .map(segment -> new ShadowingSegment(segment.getText(), segment.getStartMs(), segment.getEndMs()))
                    .toList());
        }
        throw new IllegalArgumentException("Unsupported content revision type: " + entity.getClass().getName());
    }

    public sealed interface Body permits VocabularyBody, InterviewBody, TopicBody, PhraseBody, ShadowingBody {
    }

    public record VocabularyBody(String term, String definition, String partOfSpeech, List<String> examples) implements Body {
    }

    public record InterviewBody(String prompt, String modelAnswer, List<String> keyPoints) implements Body {
    }

    public record TopicBody(List<TopicSection> sections) implements Body {
    }

    public record TopicSection(String heading, String text) {
    }

    public record PhraseBody(String phrase, String usage, List<String> examples) implements Body {
    }

    public record ShadowingBody(String transcript, List<ShadowingSegment> segments) implements Body {
    }

    public record ShadowingSegment(String text, Integer startMs, Integer endMs) {
    }
}
