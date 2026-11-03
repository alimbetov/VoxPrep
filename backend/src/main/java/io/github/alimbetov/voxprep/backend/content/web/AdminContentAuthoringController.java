package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentAdminQueryService;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionOptionEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingSegmentEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicSectionEmbeddable;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/api/v1/content/revisions")
public class AdminContentAuthoringController {

    private final ContentAdminQueryService queryService;
    private final ContentAuthoringService authoringService;

    public AdminContentAuthoringController(
            ContentAdminQueryService queryService,
            ContentAuthoringService authoringService) {
        this.queryService = queryService;
        this.authoringService = authoringService;
    }

    @GetMapping
    public Page<ContentRevisionSnapshot> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "25") int size) {
        return queryService.list(page, size);
    }

    @GetMapping("/{revisionId}")
    public ContentRevisionSnapshot get(@PathVariable UUID revisionId) {
        return queryService.get(revisionId);
    }

    @PostMapping("/{revisionId}/next")
    public ContentRevisionSnapshot createNextRevision(
            @PathVariable UUID revisionId,
            @Valid @RequestBody VersionCommand command) {
        var created = authoringService.createNextRevision(revisionId, command.expectedVersion());
        return queryService.get(created.getId());
    }

    @PutMapping("/{revisionId}/draft")
    public ContentRevisionSnapshot updateDraft(
            @PathVariable UUID revisionId,
            @Valid @RequestBody DraftUpdateRequest request) {
        var updated = authoringService.updateDraft(revisionId, request.expectedVersion(), request.toCommand());
        return queryService.get(updated.getId());
    }

    @PostMapping("/{revisionId}/ready-for-audio")
    public ContentRevisionSnapshot markReadyForAudio(
            @PathVariable UUID revisionId,
            @Valid @RequestBody VersionCommand command) {
        var updated = authoringService.markReadyForAudio(revisionId, command.expectedVersion());
        return queryService.get(updated.getId());
    }

    @PostMapping("/{revisionId}/review")
    public ContentRevisionSnapshot submitForReview(
            @PathVariable UUID revisionId,
            @Valid @RequestBody ReviewCommand command,
            Authentication authentication) {
        var updated = authoringService.submitForReview(
                revisionId,
                command.expectedVersion(),
                authentication.getName(),
                command.reason(),
                command.comment());
        return queryService.get(updated.getId());
    }

    @PostMapping("/{revisionId}/approve")
    public ContentRevisionSnapshot approve(
            @PathVariable UUID revisionId,
            @Valid @RequestBody ReviewCommand command,
            Authentication authentication) {
        var updated = authoringService.approve(
                revisionId,
                command.expectedVersion(),
                authentication.getName(),
                command.reason(),
                command.comment());
        return queryService.get(updated.getId());
    }

    public record VersionCommand(@Min(0) long expectedVersion) {
    }

    public record ReviewCommand(
            @Min(0) long expectedVersion,
            String reason,
            String comment) {
    }

    public record DraftUpdateRequest(
            @Min(0) long expectedVersion,
            @NotBlank String checksumSha256,
            @NotBlank String title,
            @NotBlank String subtitle,
            @NotBlank String description,
            @NotBlank String categoryCode,
            @NotBlank String levelCode,
            @Min(1) int minutes,
            @NotNull List<@NotBlank String> skillCodes,
            @NotBlank String availability,
            @Valid @NotNull BodyRequest body) {

        ContentDraftUpdate toCommand() {
            return new ContentDraftUpdate(
                    new Sha256Digest(checksumSha256),
                    title,
                    subtitle,
                    description,
                    new CatalogueCode(categoryCode),
                    new CatalogueCode(levelCode),
                    minutes,
                    skillCodes.stream().map(CatalogueCode::new).toList(),
                    AvailabilityStatus.valueOf(availability.toUpperCase(Locale.ROOT)),
                    body.toCommand());
        }
    }

    public record BodyRequest(
            @NotBlank String type,
            String term,
            String definition,
            String partOfSpeech,
            List<String> examples,
            String prompt,
            String modelAnswer,
            List<String> keyPoints,
            List<TopicSectionRequest> sections,
            String phrase,
            String usage,
            String transcript,
            List<ShadowingSegmentRequest> segments,
            String questionText,
            String explanation,
            List<QuestionOptionRequest> options,
            String instructions,
            Integer passingScorePercent,
            List<UUID> questionRevisionIds) {

        ContentDraftUpdate.Body toCommand() {
            return switch (type.toLowerCase(Locale.ROOT)) {
                case "vocabulary" -> new ContentDraftUpdate.VocabularyBody(
                        term, definition, partOfSpeech, requireList(examples, "examples"));
                case "interview" -> new ContentDraftUpdate.InterviewBody(
                        prompt, modelAnswer, requireList(keyPoints, "keyPoints"));
                case "topic" -> new ContentDraftUpdate.TopicBody(
                        requireList(sections, "sections").stream()
                                .map(value -> new TopicSectionEmbeddable(value.heading(), value.text()))
                                .toList());
                case "phrase" -> new ContentDraftUpdate.PhraseBody(
                        phrase, usage, requireList(examples, "examples"));
                case "shadowing" -> new ContentDraftUpdate.ShadowingBody(
                        transcript,
                        requireList(segments, "segments").stream()
                                .map(value -> new ShadowingSegmentEmbeddable(
                                        value.text(), value.startMs(), value.endMs()))
                                .toList());
                case "question" -> new ContentDraftUpdate.QuestionBody(
                        questionText,
                        explanation,
                        requireList(options, "options").stream()
                                .map(value -> new QuestionOptionEmbeddable(value.key(), value.text(), value.correct()))
                                .toList());
                case "practice_test", "practice-test" -> new ContentDraftUpdate.PracticeTestBody(
                        instructions,
                        requireInteger(passingScorePercent, "passingScorePercent"),
                        requireList(questionRevisionIds, "questionRevisionIds"));
                default -> throw new IllegalArgumentException("Unsupported content body type: " + type);
            };
        }

        private static <T> List<T> requireList(List<T> values, String name) {
            if (values == null) {
                throw new IllegalArgumentException(name + " is required");
            }
            return values;
        }

        private static int requireInteger(Integer value, String name) {
            if (value == null) {
                throw new IllegalArgumentException(name + " is required");
            }
            return value;
        }
    }

    public record TopicSectionRequest(@NotBlank String heading, @NotBlank String text) {
    }

    public record ShadowingSegmentRequest(
            @NotBlank String text,
            Integer startMs,
            Integer endMs) {
    }

    public record QuestionOptionRequest(
            @NotBlank String key,
            @NotBlank String text,
            boolean correct) {
    }
}
