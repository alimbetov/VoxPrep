package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.IntStream;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * API adapter for the strict Flutter ContentPayloadDecoder wire contract.
 *
 * Only an exact revision belonging to CURRENT can be returned. The controller
 * calls LearnerContentAccessPolicy before this adapter (including ETag/304).
 * Historical release retrieval needs a separate publication-scoped policy.
 */
@Service
public class LearnerExactContentPayloadService {

    private final LearnerContentService contentService;
    private final ContentRevisionRepository revisions;
    private final ContentAssetBindingRepository bindings;

    public LearnerExactContentPayloadService(
            LearnerContentService contentService,
            ContentRevisionRepository revisions,
            ContentAssetBindingRepository bindings) {
        this.contentService = Objects.requireNonNull(contentService);
        this.revisions = Objects.requireNonNull(revisions);
        this.bindings = Objects.requireNonNull(bindings);
    }

    @Transactional(readOnly = true)
    public ExactPayload get(String contentType, String contentCode, int revision) {
        if (revision < 1) {
            throw new IllegalArgumentException("revision must be positive");
        }
        ContentType type = ContentType.fromWireName(contentType);
        if (type == ContentType.QUESTION || type == ContentType.PRACTICE_TEST) {
            throw new IllegalArgumentException("assessment content uses the assessment API");
        }

        // LearnerContentService verifies this identity/checksum against exact CURRENT.
        LearnerContentSnapshot snapshot = contentService.get(contentType, contentCode);
        if (snapshot.revisionNumber() != revision) {
            throw new LearnerContentNotFoundException(contentType, contentCode);
        }
        UUID id = revisions.findIdByExactIdentity(contentCode, contentType, revision)
                .orElseThrow(() -> new IllegalStateException("CURRENT content revision is missing"));
        boolean hasAudio = bindings.findAllByContentRevision_IdOrderByRoleAsc(id).stream()
                .anyMatch(binding -> binding.getRole().audio()
                        && binding.getFileAsset().getStatus() == FileAssetStatus.READY
                        && binding.getFileAsset().getKind() == FileAssetKind.TTS_AUDIO);

        return new ExactPayload(
                snapshot.contentCode(),
                snapshot.contentType(),
                snapshot.revisionNumber(),
                snapshot.checksumSha256(),
                snapshot.title(),
                snapshot.subtitle(),
                snapshot.description(),
                snapshot.categoryCode(),
                snapshot.categoryCode(), // Stable code is the label fallback until taxonomy labels are published.
                snapshot.levelCode(),
                snapshot.levelCode(),
                snapshot.minutes(),
                hasAudio,
                snapshot.skillCodes(),
                body(snapshot.body()));
    }

    private static Map<String, Object> body(ContentRevisionSnapshot.Body source) {
        if (source instanceof ContentRevisionSnapshot.VocabularyBody value) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("kind", "vocabulary");
            body.put("term", value.term());
            body.put("definition", value.definition());
            if (value.partOfSpeech() != null) {
                body.put("partOfSpeech", value.partOfSpeech());
            }
            body.put("examples", value.examples());
            return body;
        }
        if (source instanceof ContentRevisionSnapshot.InterviewBody value) {
            return Map.of("kind", "interview", "prompt", value.prompt(),
                    "modelAnswer", value.modelAnswer(), "keyPoints", value.keyPoints());
        }
        if (source instanceof ContentRevisionSnapshot.TopicBody value) {
            return Map.of("kind", "topic", "sections", value.sections().stream()
                    .map(section -> Map.of("heading", section.heading(), "text", section.text()))
                    .toList());
        }
        if (source instanceof ContentRevisionSnapshot.PhraseBody value) {
            return Map.of("kind", "phrase", "phrase", value.phrase(),
                    "usage", value.usage(), "examples", value.examples());
        }
        if (source instanceof ContentRevisionSnapshot.ShadowingBody value) {
            List<Map<String, Object>> segments = IntStream.range(0, value.segments().size())
                    .mapToObj(index -> segment(index, value.segments().get(index)))
                    .toList();
            return Map.of("kind", "shadowing", "transcript", value.transcript(), "segments", segments);
        }
        throw new IllegalArgumentException("unsupported Flutter content body type");
    }

    private static Map<String, Object> segment(int order, ContentRevisionSnapshot.ShadowingSegment segment) {
        Map<String, Object> fields = new LinkedHashMap<>();
        fields.put("order", order);
        fields.put("text", segment.text());
        if (segment.startMs() != null) {
            fields.put("startMs", segment.startMs());
        }
        if (segment.endMs() != null) {
            fields.put("endMs", segment.endMs());
        }
        return fields;
    }

    public record ExactPayload(
            String contentCode,
            String contentType,
            int revision,
            String checksum,
            String title,
            String subtitle,
            String description,
            String categoryCode,
            String categoryLabel,
            String levelCode,
            String levelLabel,
            int minutes,
            boolean hasAudio,
            List<String> skillCodes,
            Map<String, Object> body) {

        public ExactPayload {
            skillCodes = List.copyOf(skillCodes);
            body = java.util.Collections.unmodifiableMap(new LinkedHashMap<>(body));
        }
    }
}
