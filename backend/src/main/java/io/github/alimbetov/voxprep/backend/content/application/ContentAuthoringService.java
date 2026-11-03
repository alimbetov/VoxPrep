package io.github.alimbetov.voxprep.backend.content.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.InterviewContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import java.time.Instant;
import java.util.UUID;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ContentAuthoringService {

    private final ContentRevisionRepository repository;

    public ContentAuthoringService(ContentRevisionRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public ContentRevisionEntity createNextRevision(UUID sourceRevisionId) {
        var source = requireRevision(sourceRevisionId);
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
    public ContentRevisionEntity markReadyForAudio(UUID revisionId) {
        var revision = requireRevision(revisionId);
        revision.markReadyForAudio();
        return save(revision);
    }

    @Transactional
    public ContentRevisionEntity submitForReview(UUID revisionId) {
        var revision = requireRevision(revisionId);
        revision.markReadyForReview();
        return save(revision);
    }

    @Transactional
    public ContentRevisionEntity approve(UUID revisionId, Instant approvedAt) {
        var revision = requireRevision(revisionId);
        revision.approve(approvedAt);
        return save(revision);
    }

    private ContentRevisionEntity requireRevision(UUID revisionId) {
        return repository.findById(revisionId)
                .orElseThrow(() -> new IllegalArgumentException("Content revision not found: " + revisionId));
    }

    private ContentRevisionEntity save(ContentRevisionEntity revision) {
        try {
            return repository.saveAndFlush(revision);
        } catch (OptimisticLockingFailureException exception) {
            throw new ContentAuthoringConflictException("Content revision was modified by another editor", exception);
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
