package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LearnerLocalizationService {

    private final CurrentPublicationResolver currentPublicationResolver;
    private final ContentRevisionRepository contentRevisionRepository;
    private final ContentLocalizationRevisionRepository localizationRepository;

    public LearnerLocalizationService(
            CurrentPublicationResolver currentPublicationResolver,
            ContentRevisionRepository contentRevisionRepository,
            ContentLocalizationRevisionRepository localizationRepository) {
        this.currentPublicationResolver = Objects.requireNonNull(currentPublicationResolver, "currentPublicationResolver");
        this.contentRevisionRepository = Objects.requireNonNull(contentRevisionRepository, "contentRevisionRepository");
        this.localizationRepository = Objects.requireNonNull(localizationRepository, "localizationRepository");
    }

    @Transactional(readOnly = true)
    public LearnerLocalizationSnapshot get(String contentTypeWireName, String contentCode, String requestedLocale) {
        ContentType contentType = ContentType.fromWireName(contentTypeWireName);
        if (contentType == ContentType.QUESTION || contentType == ContentType.PRACTICE_TEST) {
            throw new IllegalArgumentException("assessment localization must be requested through the learner assessment API");
        }

        String canonicalRequestedLocale = canonicalLocale(requestedLocale);
        CurrentPublicationSnapshot publication = currentPublicationResolver.resolve();
        PublicationExactContentRef ref = publication.refs().stream()
                .filter(value -> value.identity().contentType() == contentType)
                .filter(value -> value.identity().contentCode().value().equals(contentCode))
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException(contentTypeWireName, contentCode));

        ContentRevisionEntity revision = contentRevisionRepository.findExact(ref.identity())
                .orElseThrow(() -> new IllegalStateException("published content revision is missing"));
        if (!revision.getChecksum().equals(ref.checksum())) {
            throw new IllegalStateException("published content checksum differs from publication manifest");
        }

        ContentRevisionSnapshot source = ContentRevisionSnapshot.from(revision);
        ResolvedLocalization resolved = resolveLocalization(
                revision,
                canonicalRequestedLocale,
                publication);

        ContentLocalizationRevisionEntity localization = resolved.localization().orElse(null);
        return new LearnerLocalizationSnapshot(
                publication.contentVersion(),
                publication.rootSha256(),
                source.contentCode(),
                source.contentType().wireName(),
                source.revisionNumber(),
                canonicalRequestedLocale,
                localization == null ? null : localization.getLocale(),
                resolved.fallback(),
                localization == null ? null : localization.getLocalizationRevisionNumber(),
                localization == null ? null : localization.getChecksumSha256(),
                localization == null || localization.getTitle() == null ? source.title() : localization.getTitle(),
                localization == null || localization.getSubtitle() == null ? source.subtitle() : localization.getSubtitle(),
                localization == null || localization.getDescription() == null
                        ? source.description()
                        : localization.getDescription(),
                localization == null ? null : localization.getTranslation(),
                localization == null ? null : localization.getHint(),
                localization == null ? null : localization.getExplanation());
    }

    private ResolvedLocalization resolveLocalization(
            ContentRevisionEntity revision,
            String requestedLocale,
            CurrentPublicationSnapshot publication) {
        Optional<ContentLocalizationRevisionEntity> exact = approvedAsOf(
                revision,
                requestedLocale,
                publication);
        if (exact.isPresent()) {
            return new ResolvedLocalization(exact, "EXACT");
        }

        String baseLanguage = Locale.forLanguageTag(requestedLocale).getLanguage();
        if (!baseLanguage.isBlank() && !baseLanguage.equalsIgnoreCase(requestedLocale)) {
            Optional<ContentLocalizationRevisionEntity> base = approvedAsOf(
                    revision,
                    baseLanguage,
                    publication);
            if (base.isPresent()) {
                return new ResolvedLocalization(base, "LANGUAGE");
            }
        }
        return new ResolvedLocalization(Optional.empty(), "SOURCE");
    }

    private Optional<ContentLocalizationRevisionEntity> approvedAsOf(
            ContentRevisionEntity revision,
            String locale,
            CurrentPublicationSnapshot publication) {
        return localizationRepository
                .findTopByContentRevisionIdAndLocaleAndLifecycleAndApprovedAtLessThanEqualOrderByLocalizationRevisionNumberDesc(
                        revision.getId(),
                        locale,
                        ContentLocalizationLifecycleStatus.APPROVED,
                        publication.publishedAt());
    }

    static String canonicalLocale(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("locale must not be blank");
        }
        String canonical = Locale.forLanguageTag(value.trim()).toLanguageTag();
        if (canonical.equals("und")) {
            throw new IllegalArgumentException("locale must be a valid BCP-47 language tag");
        }
        return canonical;
    }

    private record ResolvedLocalization(
            Optional<ContentLocalizationRevisionEntity> localization,
            String fallback) {
    }
}
