package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import java.util.Locale;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Returns an exact, approved localized revision for CURRENT published content.
 * Unlike the convenience /localization endpoint, never substitutes a fallback
 * locale: the Flutter manifest already owns deterministic fallback decisions.
 */
@Service
public class LearnerExactLocalizationService {

    private final LearnerContentService content;
    private final CurrentPublicationResolver publication;
    private final ContentRevisionRepository revisions;
    private final ContentLocalizationRevisionRepository localizations;

    public LearnerExactLocalizationService(
            LearnerContentService content,
            CurrentPublicationResolver publication,
            ContentRevisionRepository revisions,
            ContentLocalizationRevisionRepository localizations) {
        this.content = Objects.requireNonNull(content);
        this.publication = Objects.requireNonNull(publication);
        this.revisions = Objects.requireNonNull(revisions);
        this.localizations = Objects.requireNonNull(localizations);
    }

    @Transactional(readOnly = true)
    public ExactLocalization get(
            String contentType, String contentCode, int contentRevision,
            String locale, int localizationRevision) {
        if (contentRevision < 1 || localizationRevision < 1) {
            throw new IllegalArgumentException("revision numbers must be positive");
        }
        if (locale == null || locale.isBlank()) {
            throw new IllegalArgumentException("locale is required");
        }
        String canonicalLocale = Locale.forLanguageTag(locale).toLanguageTag();
        if (canonicalLocale.equals("und") || !canonicalLocale.equals(locale)) {
            throw new IllegalArgumentException("locale must be canonical BCP-47");
        }

        var current = content.get(contentType, contentCode);
        if (current.revisionNumber() != contentRevision) {
            throw new LearnerContentNotFoundException(contentType, contentCode);
        }
        var id = revisions.findIdByExactIdentity(contentCode, contentType, contentRevision)
                .orElseThrow(() -> new IllegalStateException("CURRENT revision is missing"));
        var publishedAt = publication.resolve().publishedAt();
        ContentLocalizationRevisionEntity localized = localizations
                .findAllByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberAsc(id, canonicalLocale)
                .stream()
                .filter(item -> item.getLocalizationRevisionNumber() == localizationRevision)
                .filter(item -> item.getLifecycle() == ContentLocalizationLifecycleStatus.APPROVED)
                .filter(item -> item.getApprovedAt() != null && !item.getApprovedAt().isAfter(publishedAt))
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException(contentType, contentCode));

        return new ExactLocalization(
                contentCode, contentType, contentRevision,
                canonicalLocale, localizationRevision, localized.getChecksumSha256(),
                localized.getTitle(), localized.getSubtitle(), localized.getDescription(),
                localized.getTranslation(), localized.getHint(), localized.getExplanation());
    }

    public record ExactLocalization(
            String contentCode,
            String contentType,
            int contentRevision,
            String locale,
            int localizationRevision,
            String checksum,
            String title,
            String subtitle,
            String description,
            String translation,
            String hint,
            String explanation) {
    }
}
