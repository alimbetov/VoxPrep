package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicSectionEmbeddable;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class LearnerLocalizationServiceTest {

    private static final String ROOT = "a".repeat(64);
    private static final String CHECKSUM = "b".repeat(64);
    private static final Instant PUBLISHED_AT = Instant.parse("2026-11-03T11:00:00Z");

    private CurrentPublicationResolver currentPublicationResolver;
    private ContentRevisionRepository contentRevisionRepository;
    private ContentLocalizationRevisionRepository localizationRepository;
    private LearnerLocalizationService service;
    private PublicationExactContentRef ref;
    private TopicContentRevisionEntity revision;

    @BeforeEach
    void setUp() {
        currentPublicationResolver = mock(CurrentPublicationResolver.class);
        contentRevisionRepository = mock(ContentRevisionRepository.class);
        localizationRepository = mock(ContentLocalizationRevisionRepository.class);
        service = new LearnerLocalizationService(
                currentPublicationResolver,
                contentRevisionRepository,
                localizationRepository);
        ref = new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode("topic-1"),
                        ContentType.TOPIC,
                        new RevisionNumber(1)),
                new Sha256Digest(CHECKSUM));
        revision = new TopicContentRevisionEntity(
                new BusinessCode("topic-1"),
                new RevisionNumber(1),
                new Sha256Digest(CHECKSUM),
                "Source title",
                "Source subtitle",
                "Source description",
                new CatalogueCode("TOPIC"),
                new CatalogueCode("B1"),
                5,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                List.of(new TopicSectionEmbeddable("Heading", "Body")));
        when(currentPublicationResolver.resolve()).thenReturn(new CurrentPublicationSnapshot(
                12L, ROOT, PUBLISHED_AT, List.of(ref)));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));
    }

    @Test
    void exactApprovedLocaleWinsAndRequestIsCanonicalized() {
        ContentLocalizationRevisionEntity exact = approved("ru-KZ", "Локальный заголовок");
        whenApprovedAsOf("ru-KZ", Optional.of(exact));

        LearnerLocalizationSnapshot result = service.get("topic", "topic-1", "ru-kz");

        assertThat(result.requestedLocale()).isEqualTo("ru-KZ");
        assertThat(result.resolvedLocale()).isEqualTo("ru-KZ");
        assertThat(result.fallback()).isEqualTo("EXACT");
        assertThat(result.title()).isEqualTo("Локальный заголовок");
        assertThat(result.subtitle()).isEqualTo("Source subtitle");
    }

    @Test
    void fallsBackFromRegionalLocaleToApprovedBaseLanguage() {
        whenApprovedAsOf("ru-KZ", Optional.empty());
        ContentLocalizationRevisionEntity base = approved("ru", "Русский заголовок");
        whenApprovedAsOf("ru", Optional.of(base));

        LearnerLocalizationSnapshot result = service.get("topic", "topic-1", "ru-KZ");

        assertThat(result.resolvedLocale()).isEqualTo("ru");
        assertThat(result.fallback()).isEqualTo("LANGUAGE");
        assertThat(result.title()).isEqualTo("Русский заголовок");
    }

    @Test
    void fallsBackToPublishedSourceInsteadOfAnotherLanguage() {
        whenApprovedAsOf("kk-KZ", Optional.empty());
        whenApprovedAsOf("kk", Optional.empty());

        LearnerLocalizationSnapshot result = service.get("topic", "topic-1", "kk-KZ");

        assertThat(result.resolvedLocale()).isNull();
        assertThat(result.fallback()).isEqualTo("SOURCE");
        assertThat(result.localizationRevisionNumber()).isNull();
        assertThat(result.title()).isEqualTo("Source title");
        assertThat(result.translation()).isNull();
    }

    private void whenApprovedAsOf(String locale, Optional<ContentLocalizationRevisionEntity> value) {
        when(localizationRepository
                .findTopByContentRevisionIdAndLocaleAndLifecycleAndApprovedAtLessThanEqualOrderByLocalizationRevisionNumberDesc(
                        any(),
                        eq(locale),
                        eq(ContentLocalizationLifecycleStatus.APPROVED),
                        eq(PUBLISHED_AT)))
                .thenReturn(value);
    }

    private static ContentLocalizationRevisionEntity approved(String locale, String title) {
        ContentLocalizationRevisionEntity entity = new ContentLocalizationRevisionEntity(
                UUID.randomUUID(),
                locale,
                1,
                new Sha256Digest("c".repeat(64)),
                title,
                null,
                null,
                "translation",
                null,
                null);
        entity.submitForReview();
        entity.approve(Instant.parse("2026-11-03T10:00:00Z"));
        return entity;
    }
}
