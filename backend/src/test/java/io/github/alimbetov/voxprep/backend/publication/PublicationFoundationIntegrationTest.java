package io.github.alimbetov.voxprep.backend.publication;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.publication.application.PublicationContentVersionAllocator;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseRepository;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
class PublicationFoundationIntegrationTest {

    private static final String ROOT_SHA = "a".repeat(64);

    @Autowired private PublicationCandidateRepository candidateRepository;
    @Autowired private PublicationReleaseRepository releaseRepository;
    @Autowired private PublicationCurrentRepository currentRepository;
    @Autowired private PublicationContentVersionAllocator versionAllocator;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void candidateStartsDraftAndCanBecomeValidated() {
        var candidate = candidateRepository.saveAndFlush(
                new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT));
        candidate.markValidated(ROOT_SHA, Instant.parse("2026-11-03T08:00:00Z"));
        candidateRepository.saveAndFlush(candidate);

        var loaded = candidateRepository.findById(candidate.getId()).orElseThrow();
        assertThat(loaded.getStatus()).isEqualTo(PublicationCandidateStatus.VALIDATED);
        assertThat(loaded.getRootSha256()).isEqualTo(ROOT_SHA);
        assertThat(loaded.getValidatedAt()).isNotNull();
    }

    @Test
    void contentVersionsAreStrictlyIncreasingAndNeverReused() {
        long first = versionAllocator.nextVersion();
        long second = versionAllocator.nextVersion();

        assertThat(second).isGreaterThan(first);
    }

    @Test
    void persistedReleaseIsImmutableAtDatabaseBoundary() {
        var candidate = candidateRepository.saveAndFlush(
                new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT));
        candidate.markValidated(ROOT_SHA, Instant.parse("2026-11-03T08:00:00Z"));
        candidateRepository.saveAndFlush(candidate);
        long contentVersion = versionAllocator.nextVersion();
        var release = releaseRepository.saveAndFlush(new PublicationReleaseEntity(
                candidate,
                contentVersion,
                ROOT_SHA,
                Instant.parse("2026-11-03T08:01:00Z")));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.publication_release set root_sha256 = ? where id = ?",
                        "b".repeat(64),
                        release.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void currentPointerIsASingleSeededRow() {
        var current = currentRepository.findById(PublicationCurrentEntity.SINGLETON_ID).orElseThrow();
        assertThat(current.getSingletonId()).isEqualTo(PublicationCurrentEntity.SINGLETON_ID);
        assertThat(current.getRelease()).isNull();

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "insert into app.publication_current(singleton_id, version, release_id, updated_at) values (2, 0, null, now())"))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
