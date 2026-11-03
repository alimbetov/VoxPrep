package io.github.alimbetov.voxprep.backend.content.application;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionOptionEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingSegmentEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicSectionEmbeddable;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

public record ContentDraftUpdate(
        Sha256Digest checksum,
        String title,
        String subtitle,
        String description,
        CatalogueCode categoryCode,
        CatalogueCode levelCode,
        int minutes,
        List<CatalogueCode> skillCodes,
        AvailabilityStatus availability,
        Body body) {

    public ContentDraftUpdate {
        Objects.requireNonNull(checksum, "checksum");
        Objects.requireNonNull(categoryCode, "categoryCode");
        Objects.requireNonNull(levelCode, "levelCode");
        skillCodes = List.copyOf(Objects.requireNonNull(skillCodes, "skillCodes"));
        Objects.requireNonNull(availability, "availability");
        Objects.requireNonNull(body, "body");
    }

    public sealed interface Body permits VocabularyBody, InterviewBody, TopicBody, PhraseBody, ShadowingBody,
            QuestionBody, PracticeTestBody {
    }

    public record VocabularyBody(
            String term,
            String definition,
            String partOfSpeech,
            List<String> examples) implements Body {
        public VocabularyBody {
            examples = List.copyOf(Objects.requireNonNull(examples, "examples"));
        }
    }

    public record InterviewBody(
            String prompt,
            String modelAnswer,
            List<String> keyPoints) implements Body {
        public InterviewBody {
            keyPoints = List.copyOf(Objects.requireNonNull(keyPoints, "keyPoints"));
        }
    }

    public record TopicBody(List<TopicSectionEmbeddable> sections) implements Body {
        public TopicBody {
            sections = List.copyOf(Objects.requireNonNull(sections, "sections"));
        }
    }

    public record PhraseBody(
            String phrase,
            String usage,
            List<String> examples) implements Body {
        public PhraseBody {
            examples = List.copyOf(Objects.requireNonNull(examples, "examples"));
        }
    }

    public record ShadowingBody(
            String transcript,
            List<ShadowingSegmentEmbeddable> segments) implements Body {
        public ShadowingBody {
            segments = List.copyOf(Objects.requireNonNull(segments, "segments"));
        }
    }

    public record QuestionBody(
            String questionText,
            String explanation,
            List<QuestionOptionEmbeddable> options) implements Body {
        public QuestionBody {
            options = List.copyOf(Objects.requireNonNull(options, "options"));
        }
    }

    public record PracticeTestBody(
            String instructions,
            int passingScorePercent,
            List<UUID> questionRevisionIds) implements Body {
        public PracticeTestBody {
            questionRevisionIds = List.copyOf(Objects.requireNonNull(questionRevisionIds, "questionRevisionIds"));
        }
    }
}
