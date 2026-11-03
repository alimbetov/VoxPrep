package io.github.alimbetov.voxprep.backend.content.localization;

import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionNotFoundException;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.sql.Timestamp;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ContentLocalizationAuthoringService {

    private final ContentLocalizationRevisionRepository repository;
    private final ContentRevisionRepository contentRepository;
    private final JdbcTemplate jdbcTemplate;
    private final Clock clock = Clock.systemUTC();

    public ContentLocalizationAuthoringService(
            ContentLocalizationRevisionRepository repository,
            ContentRevisionRepository contentRepository,
            JdbcTemplate jdbcTemplate) {
        this.repository = repository;
        this.contentRepository = contentRepository;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public Snapshot create(
            UUID contentRevisionId,
            String locale,
            Sha256Digest checksum,
            Fields fields) {
        requireContent(contentRevisionId);
        String canonicalLocale = canonicalLocale(locale);
        int nextRevision = repository
                .findTopByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberDesc(contentRevisionId, canonicalLocale)
                .map(value -> value.getLocalizationRevisionNumber() + 1)
                .orElse(1);
        return snapshot(save(new ContentLocalizationRevisionEntity(
                contentRevisionId,
                canonicalLocale,
                nextRevision,
                checksum,
                fields.title(),
                fields.subtitle(),
                fields.description(),
                fields.translation(),
                fields.hint(),
                fields.explanation())));
    }

    @Transactional
    public Snapshot updateDraft(UUID id, long expectedVersion, Sha256Digest checksum, Fields fields) {
        var entity = require(id);
        requireVersion(entity, expectedVersion);
        entity.replaceDraft(
                checksum,
                fields.title(),
                fields.subtitle(),
                fields.description(),
                fields.translation(),
                fields.hint(),
                fields.explanation());
        return snapshot(save(entity));
    }

    @Transactional
    public Snapshot submitForReview(UUID id, long expectedVersion, String actor, String reason, String comment) {
        var entity = require(id);
        requireVersion(entity, expectedVersion);
        entity.submitForReview();
        var saved = save(entity);
        appendAudit(saved.getId(), "SUBMITTED_FOR_REVIEW", actor, reason, comment, clock.instant());
        return snapshot(saved);
    }

    @Transactional
    public Snapshot approve(UUID id, long expectedVersion, String actor, String reason, String comment) {
        var entity = require(id);
        requireVersion(entity, expectedVersion);
        Instant approvedAt = clock.instant();
        entity.approve(approvedAt);
        var saved = save(entity);
        appendAudit(saved.getId(), "APPROVED", actor, reason, comment, approvedAt);
        return snapshot(saved);
    }

    @Transactional
    public Snapshot createNext(UUID id, long expectedVersion) {
        var source = require(id);
        requireVersion(source, expectedVersion);
        if (source.getLifecycle() != ContentLocalizationLifecycleStatus.APPROVED) {
            throw new ContentAuthoringConflictException("Only APPROVED localization revision may create the next revision");
        }
        var latest = repository
                .findTopByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberDesc(
                        source.getContentRevisionId(), source.getLocale())
                .orElseThrow();
        if (!latest.getId().equals(source.getId())) {
            throw new ContentAuthoringConflictException("New localization revision can only be created from the latest revision");
        }
        return snapshot(save(new ContentLocalizationRevisionEntity(
                source.getContentRevisionId(),
                source.getLocale(),
                source.getLocalizationRevisionNumber() + 1,
                new Sha256Digest(source.getChecksumSha256()),
                source.getTitle(),
                source.getSubtitle(),
                source.getDescription(),
                source.getTranslation(),
                source.getHint(),
                source.getExplanation())));
    }

    @Transactional(readOnly = true)
    public List<Snapshot> listByContent(UUID contentRevisionId) {
        requireContent(contentRevisionId);
        return repository.findAllByContentRevisionIdOrderByLocaleAscLocalizationRevisionNumberDesc(contentRevisionId)
                .stream().map(ContentLocalizationAuthoringService::snapshot).toList();
    }

    @Transactional(readOnly = true)
    public Snapshot get(UUID id) {
        return snapshot(require(id));
    }

    private void requireContent(UUID contentRevisionId) {
        if (!contentRepository.existsById(contentRevisionId)) {
            throw new ContentRevisionNotFoundException(contentRevisionId);
        }
    }

    private ContentLocalizationRevisionEntity require(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ContentLocalizationNotFoundException(id));
    }

    private static void requireVersion(ContentLocalizationRevisionEntity entity, long expectedVersion) {
        if (entity.getVersion() != expectedVersion) {
            throw new ContentAuthoringConflictException(
                    "Stale localization revision version: expected " + expectedVersion + " but was " + entity.getVersion());
        }
    }

    private ContentLocalizationRevisionEntity save(ContentLocalizationRevisionEntity entity) {
        try {
            return repository.saveAndFlush(entity);
        } catch (OptimisticLockingFailureException exception) {
            throw new ContentAuthoringConflictException("Localization revision was modified by another editor", exception);
        }
    }

    private void appendAudit(
            UUID localizationRevisionId,
            String action,
            String actor,
            String reason,
            String comment,
            Instant occurredAt) {
        if (actor == null || actor.isBlank()) {
            throw new IllegalArgumentException("actor must not be blank");
        }
        jdbcTemplate.update(
                "insert into app.content_localization_review_audit "
                        + "(id, localization_revision_id, action, actor, reason, comment, occurred_at) values (?, ?, ?, ?, ?, ?, ?)",
                UUID.randomUUID(),
                localizationRevisionId,
                action,
                actor.trim(),
                nullable(reason),
                nullable(comment),
                Timestamp.from(occurredAt));
    }

    private static String nullable(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static String canonicalLocale(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("locale must not be blank");
        }
        var canonical = Locale.forLanguageTag(value.trim()).toLanguageTag();
        if (canonical.equals("und")) {
            throw new IllegalArgumentException("locale must be a valid BCP-47 language tag");
        }
        return canonical;
    }

    private static Snapshot snapshot(ContentLocalizationRevisionEntity value) {
        return new Snapshot(
                value.getId(), value.getVersion(), value.getContentRevisionId(), value.getLocale(),
                value.getLocalizationRevisionNumber(), value.getLifecycle(), value.getChecksumSha256(),
                value.getTitle(), value.getSubtitle(), value.getDescription(), value.getTranslation(),
                value.getHint(), value.getExplanation(), value.getApprovedAt());
    }

    public record Fields(
            String title,
            String subtitle,
            String description,
            String translation,
            String hint,
            String explanation) {
    }

    public record Snapshot(
            UUID id,
            long version,
            UUID contentRevisionId,
            String locale,
            int localizationRevisionNumber,
            ContentLocalizationLifecycleStatus lifecycle,
            String checksumSha256,
            String title,
            String subtitle,
            String description,
            String translation,
            String hint,
            String explanation,
            Instant approvedAt) {
    }
}
