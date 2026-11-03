package io.github.alimbetov.voxprep.backend.content.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.InterviewContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.review.ContentReviewAction;
import io.github.alimbetov.voxprep.backend.content.review.ContentReviewAuditEntity;
import io.github.alimbetov.voxprep.backend.content.review.ContentReviewAuditRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ContentAuthoringService {

    private final ContentRevisionRepository repository;
    private final ContentReviewAuditRepository reviewAuditRepository;
    private final Clock clock;

    @Autowired
    public ContentAuthoringService(
            ContentRevisionRepository repository,
            ContentReviewAuditRepository reviewAuditRepository) {
        this(repository, reviewAuditRepository, Clock.systemUTC());
    }

    ContentAuthoringService(
            ContentRevisionRepository repository,
            ContentReviewAuditRepository reviewAuditRepository,
            Clock clock) {
        this.repository = repository;
        this.reviewAuditRepository = reviewAuditRepository;
        this.clock = clock;
    }

    @Transactional
    public ContentRevisionEntity createNextRevision(UUID sourceRevisionId) {
        var source = requireRevision(sourceRevisionId);
        return createNextRevision(source, source.getVersion());
    }

    @Transactional
    public ContentRevisionEntity createNextRevision(UUID sourceRevisionId, long expectedVersion) {
        return createNextRevision(requireRevision(sourceRevisionId), expectedVersion);
    }

    private ContentRevisionEntity createNextRevision(ContentRevisionEntity source, long expectedVersion) {
        requireVersion(source, expectedVersion);
        if (source.getLifecycle() == ContentLifecycleStatus.DRAFT) {
            throw new ContentAuthoringConflictException("DRAFT revision must be edited in place");
        }

        var latest = repository.findLatest(source)
                .orElseThrow(() -> new ContentAuthoringConflictException("Latest revision not found"));
        if (!latest.getId().equals(source.getId())) {
            throw new ContentAuthoringConflictException("New revision can only be created from the latest revision");
        }

        var nextNumber = new RevisionNumber(source.getRevisionNumber().value() + 1);
        return save(cloneAsDraft(source, nextNumber));
    }

    @Transactional
    public ContentRevisionEntity updateDraft(UUID revisionId, long expectedVersion, ContentDraftUpdate update) {
        var revision = requireRevision(revisionId);
        requireVersion(revision, expectedVersion);
        revision.replaceDraftMetadata(
                update.checksum(), update.title(), update.subtitle(), update.description(),
                update.categoryCode(), update.levelCode(), update.minutes(), update.skillCodes());
        revision.changeAvailability(update.availability());
        replaceTypedBody(revision, update);
        return save(revision);
    }

    @Transactional
    public ContentRevisionEntity markReadyForAudio(UUID revisionId) {
        var revision = requireRevision(revisionId);
        return markReadyForAudio(revision, revision.getVersion());
    }

    @Transactional
    public ContentRevisionEntity markReadyForAudio(UUID revisionId, long expectedVersion) {
        return markReadyForAudio(requireRevision(revisionId), expectedVersion);
    }

    private ContentRevisionEntity markReadyForAudio(ContentRevisionEntity revision, long expectedVersion) {
        requireVersion(revision, expectedVersion);
        revision.markReadyForAudio();
        return save(revision);
    }

    @Transactional
    public ContentRevisionEntity submitForReview(UUID revisionId) {
        var revision = requireRevision(revisionId);
        return submitForReview(revision, revision.getVersion(), "system", null, null);
    }

    @Transactional
    public ContentRevisionEntity submitForReview(
            UUID revisionId,
            String actor,
            String reason,
            String comment) {
        var revision = requireRevision(revisionId);
        return submitForReview(revision, revision.getVersion(), actor, reason, comment);
    }

    @Transactional
    public ContentRevisionEntity submitForReview(
            UUID revisionId,
            long expectedVersion,
            String actor,
            String reason,
            String comment) {
        return submitForReview(requireRevision(revisionId), expectedVersion, actor, reason, comment);
    }

    private ContentRevisionEntity submitForReview(
            ContentRevisionEntity revision,
            long expectedVersion,
            String actor,
            String reason,
            String comment) {
        requireVersion(revision, expectedVersion);
        revision.markReadyForReview();
        var saved = save(revision);
        appendAudit(saved.getId(), ContentReviewAction.SUBMITTED_FOR_REVIEW, actor, reason, comment, clock.instant());
        return saved;
    }

    @Transactional
    public ContentRevisionEntity approve(UUID revisionId, Instant approvedAt) {
        var revision = requireRevision(revisionId);
        return approve(revision, revision.getVersion(), approvedAt, "system", null, null);
    }

    @Transactional
    public ContentRevisionEntity approve(
            UUID revisionId,
            Instant approvedAt,
            String actor,
            String reason,
            String comment) {
        var revision = requireRevision(revisionId);
        return approve(revision, revision.getVersion(), approvedAt, actor, reason, comment);
    }

    @Transactional
    public ContentRevisionEntity approve(
            UUID revisionId,
            long expectedVersion,
            String actor,
            String reason,
            String comment) {
        return approve(requireRevision(revisionId), expectedVersion, clock.instant(), actor, reason, comment);
    }

    private ContentRevisionEntity approve(
            ContentRevisionEntity revision,
            long expectedVersion,
            Instant approvedAt,
            String actor,
            String reason,
            String comment) {
        requireVersion(revision, expectedVersion);
        revision.approve(approvedAt);
        var saved = save(revision);
        appendAudit(saved.getId(), ContentReviewAction.APPROVED, actor, reason, comment, approvedAt);
        return saved;
    }

    private ContentRevisionEntity requireRevision(UUID revisionId) {
        return repository.findById(revisionId)
                .orElseThrow(() -> new ContentRevisionNotFoundException(revisionId));
    }

    private static void requireVersion(ContentRevisionEntity revision, long expectedVersion) {
        if (revision.getVersion() != expectedVersion) {
            throw new ContentAuthoringConflictException(
                    "Stale content revision version: expected " + expectedVersion + " but was " + revision.getVersion());
        }
    }

    private ContentRevisionEntity save(ContentRevisionEntity revision) {
        try {
            return repository.saveAndFlush(revision);
        } catch (OptimisticLockingFailureException exception) {
            throw new ContentAuthoringConflictException("Content revision was modified by another editor", exception);
        } catch (IllegalStateException exception) {
            throw new ContentAuthoringConflictException(exception.getMessage(), exception);
        }
    }

    private void appendAudit(
            UUID revisionId,
            ContentReviewAction action,
            String actor,
            String reason,
            String comment,
            Instant occurredAt) {
        reviewAuditRepository.saveAndFlush(new ContentReviewAuditEntity(
                revisionId, action, actor, reason, comment, occurredAt));
    }

    private static void replaceTypedBody(ContentRevisionEntity revision, ContentDraftUpdate update) {
        switch (revision) {
            case VocabularyContentRevisionEntity value -> {
                if (!(update.body() instanceof ContentDraftUpdate.VocabularyBody body)) {
                    throw new IllegalArgumentException("Vocabulary revision requires vocabulary body");
                }
                value.replaceDraftBody(body.term(), body.definition(), body.partOfSpeech(), body.examples(), update.checksum());
            }
            case InterviewContentRevisionEntity value -> {
                if (!(update.body() instanceof ContentDraftUpdate.InterviewBody body)) {
                    throw new IllegalArgumentException("Interview revision requires interview body");
                }
                value.replaceDraftBody(body.prompt(), body.modelAnswer(), body.keyPoints(), update.checksum());
            }
            case TopicContentRevisionEntity value -> {
                if (!(update.body() instanceof ContentDraftUpdate.TopicBody body)) {
                    throw new IllegalArgumentException("Topic revision requires topic body");
                }
                value.replaceDraftBody(body.sections(), update.checksum());
            }
            case PhraseContentRevisionEntity value -> {
                if (!(update.body() instanceof ContentDraftUpdate.PhraseBody body)) {
                    throw new IllegalArgumentException("Phrase revision requires phrase body");
                }
                value.replaceDraftBody(body.phrase(), body.usage(), body.examples(), update.checksum());
            }
            case ShadowingContentRevisionEntity value -> {
                if (!(update.body() instanceof ContentDraftUpdate.ShadowingBody body)) {
                    throw new IllegalArgumentException("Shadowing revision requires shadowing body");
                }
                value.replaceDraftBody(body.transcript(), body.segments(), update.checksum());
            }
            default -> throw new IllegalArgumentException("Unsupported content revision type: " + revision.getClass().getName());
        }
    }

    private static ContentRevisionEntity cloneAsDraft(ContentRevisionEntity source, RevisionNumber nextNumber) {
        if (source instanceof VocabularyContentRevisionEntity value) {
            return new VocabularyContentRevisionEntity(
                    value.getContentCode(), nextNumber, value.getChecksum(),
                    value.getTitle(), value.getSubtitle(), value.getDescription(),
                    value.getCategoryCode(), value.getLevelCode(), value.getMinutes(), value.getSkillCodes(),
                    value.getAvailability(), value.getTerm(), value.getDefinition(), value.getPartOfSpeech(), value.getExamples());
        }
        if (source instanceof InterviewContentRevisionEntity value) {
            return new InterviewContentRevisionEntity(
                    value.getContentCode(), nextNumber, value.getChecksum(),
                    value.getTitle(), value.getSubtitle(), value.getDescription(),
                    value.getCategoryCode(), value.getLevelCode(), value.getMinutes(), value.getSkillCodes(),
                    value.getAvailability(), value.getPrompt(), value.getModelAnswer(), value.getKeyPoints());
        }
        if (source instanceof TopicContentRevisionEntity value) {
            return new TopicContentRevisionEntity(
                    value.getContentCode(), nextNumber, value.getChecksum(),
                    value.getTitle(), value.getSubtitle(), value.getDescription(),
                    value.getCategoryCode(), value.getLevelCode(), value.getMinutes(), value.getSkillCodes(),
                    value.getAvailability(), value.getSections());
        }
        if (source instanceof PhraseContentRevisionEntity value) {
            return new PhraseContentRevisionEntity(
                    value.getContentCode(), nextNumber, value.getChecksum(),
                    value.getTitle(), value.getSubtitle(), value.getDescription(),
                    value.getCategoryCode(), value.getLevelCode(), value.getMinutes(), value.getSkillCodes(),
                    value.getAvailability(), value.getPhrase(), value.getUsage(), value.getExamples());
        }
        if (source instanceof ShadowingContentRevisionEntity value) {
            return new ShadowingContentRevisionEntity(
                    value.getContentCode(), nextNumber, value.getChecksum(),
                    value.getTitle(), value.getSubtitle(), value.getDescription(),
                    value.getCategoryCode(), value.getLevelCode(), value.getMinutes(), value.getSkillCodes(),
                    value.getAvailability(), value.getTranscript(), value.getSegments());
        }
        throw new IllegalArgumentException("Unsupported content revision type: " + source.getClass().getName());
    }
}
