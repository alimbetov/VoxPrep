package io.github.alimbetov.voxprep.backend.content.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.OptimisticLockException;
import jakarta.persistence.RollbackException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ContentRevisionIntegrationTest {

    @Autowired
    private ContentRevisionRepository repository;

    @Autowired
    private EntityManagerFactory entityManagerFactory;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void persistsExactTypedVocabularyRevisionAndOrderedChildren() {
        String codeValue = code("content-vocabulary");
        var revision = repository.saveAndFlush(vocabulary(codeValue, 1, checksum('a')));

        var loaded = repository.findExact(new ContentRevisionIdentity(
                        new BusinessCode(codeValue), ContentType.VOCABULARY, new RevisionNumber(1)))
                .orElseThrow();

        assertThat(loaded).isInstanceOf(VocabularyContentRevisionEntity.class);
        assertThat(loaded.getLifecycle()).isEqualTo(ContentLifecycleStatus.DRAFT);
        assertThat(loaded.getChecksum()).isEqualTo(checksum('a'));

        List<String> skills = jdbcTemplate.queryForList(
                "select skill_code from app.content_revision_skill where revision_id = ? order by position",
                String.class,
                revision.getId());
        assertThat(skills).containsExactly("SPEAKING", "VOCABULARY");

        List<String> examples = jdbcTemplate.queryForList(
                "select example_text from app.content_vocabulary_example where revision_id = ? order by position",
                String.class,
                revision.getId());
        assertThat(examples).containsExactly("Example one", "Example two");
    }

    @Test
    void allFiveTypedContentBodiesPersistThroughJoinedInheritance() {
        String suffix = UUID.randomUUID().toString();

        var interview = repository.saveAndFlush(new InterviewContentRevisionEntity(
                new BusinessCode("interview-" + suffix), new RevisionNumber(1), checksum('a'),
                "Interview", "Interview subtitle", "Interview description",
                new CatalogueCode("INTERVIEW"), new CatalogueCode("B2"), 5,
                List.of(new CatalogueCode("SPEAKING")), AvailabilityStatus.ACTIVE,
                "Tell me about yourself", "Model answer", List.of("Point one")));

        var topic = repository.saveAndFlush(new TopicContentRevisionEntity(
                new BusinessCode("topic-" + suffix), new RevisionNumber(1), checksum('b'),
                "Topic", "Topic subtitle", "Topic description",
                new CatalogueCode("TOPIC"), new CatalogueCode("B2"), 6,
                List.of(new CatalogueCode("READING")), AvailabilityStatus.ACTIVE,
                List.of(new TopicSectionEmbeddable("Heading", "Section text"))));

        var phrase = repository.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode("phrase-" + suffix), new RevisionNumber(1), checksum('c'),
                "Phrase", "Phrase subtitle", "Phrase description",
                new CatalogueCode("PHRASE"), new CatalogueCode("B1"), 3,
                List.of(new CatalogueCode("SPEAKING")), AvailabilityStatus.ACTIVE,
                "Could you clarify?", "Professional clarification", List.of("Could you clarify the deadline?")));

        var shadowing = repository.saveAndFlush(new ShadowingContentRevisionEntity(
                new BusinessCode("shadowing-" + suffix), new RevisionNumber(1), checksum('d'),
                "Shadowing", "Shadowing subtitle", "Shadowing description",
                new CatalogueCode("SHADOWING"), new CatalogueCode("B2"), 7,
                List.of(new CatalogueCode("LISTENING")), AvailabilityStatus.ACTIVE,
                "Full transcript",
                List.of(new ShadowingSegmentEmbeddable("First segment", 0, 1200))));

        assertThat(jdbcTemplate.queryForObject(
                "select count(*) from app.content_interview_revision where revision_id = ?",
                Integer.class, interview.getId())).isEqualTo(1);
        assertThat(jdbcTemplate.queryForObject(
                "select count(*) from app.content_topic_revision where revision_id = ?",
                Integer.class, topic.getId())).isEqualTo(1);
        assertThat(jdbcTemplate.queryForObject(
                "select count(*) from app.content_phrase_revision where revision_id = ?",
                Integer.class, phrase.getId())).isEqualTo(1);
        assertThat(jdbcTemplate.queryForObject(
                "select count(*) from app.content_shadowing_revision where revision_id = ?",
                Integer.class, shadowing.getId())).isEqualTo(1);
    }

    @Test
    void exactIdentityIncludesContentType() {
        String sharedCode = code("shared-code");
        repository.saveAndFlush(vocabulary(sharedCode, 1, checksum('a')));
        repository.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode(sharedCode), new RevisionNumber(1), checksum('b'),
                "Phrase", "Subtitle", "Description",
                new CatalogueCode("PHRASE"), new CatalogueCode("B1"), 2,
                List.of(), AvailabilityStatus.ACTIVE,
                "A phrase", "Usage", List.of("Example")));

        assertThat(repository.findExact(new ContentRevisionIdentity(
                new BusinessCode(sharedCode), ContentType.VOCABULARY, new RevisionNumber(1)))).isPresent();
        assertThat(repository.findExact(new ContentRevisionIdentity(
                new BusinessCode(sharedCode), ContentType.PHRASE, new RevisionNumber(1)))).isPresent();
    }

    @Test
    void postgresEnforcesGaplessMonotonicRevisionNumbers() {
        String codeValue = code("revision-sequence");
        repository.saveAndFlush(vocabulary(codeValue, 1, checksum('a')));

        assertThatThrownBy(() -> repository.saveAndFlush(vocabulary(codeValue, 3, checksum('b'))))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void draftUsesOptimisticLockingForConcurrentEditors() {
        UUID id = repository.saveAndFlush(vocabulary(code("optimistic"), 1, checksum('a'))).getId();
        EntityManager first = entityManagerFactory.createEntityManager();
        EntityManager second = entityManagerFactory.createEntityManager();

        try {
            first.getTransaction().begin();
            second.getTransaction().begin();

            var firstCopy = first.find(VocabularyContentRevisionEntity.class, id);
            var staleCopy = second.find(VocabularyContentRevisionEntity.class, id);

            firstCopy.replaceDraftMetadata(
                    checksum('b'), "First writer", firstCopy.getSubtitle(), firstCopy.getDescription(),
                    firstCopy.getCategoryCode(), firstCopy.getLevelCode(), firstCopy.getMinutes(), firstCopy.getSkillCodes());
            first.getTransaction().commit();

            staleCopy.replaceDraftMetadata(
                    checksum('c'), "Stale writer", staleCopy.getSubtitle(), staleCopy.getDescription(),
                    staleCopy.getCategoryCode(), staleCopy.getLevelCode(), staleCopy.getMinutes(), staleCopy.getSkillCodes());

            assertThatThrownBy(() -> second.getTransaction().commit())
                    .isInstanceOfAny(RollbackException.class, OptimisticLockException.class);
        } finally {
            rollbackIfActive(first);
            rollbackIfActive(second);
            first.close();
            second.close();
        }
    }

    @Test
    void lifecycleAdvancesStrictlyAndPublishedRevisionIsNotEditableInJava() {
        var published = publish(vocabulary(code("published-java"), 1, checksum('a')));

        assertThat(published.getLifecycle()).isEqualTo(ContentLifecycleStatus.PUBLISHED);
        assertThat(published.getApprovedAt()).isNotNull();
        assertThat(published.getPublishedAt()).isNotNull();

        assertThatThrownBy(() -> published.replaceDraftMetadata(
                checksum('b'), "Changed", published.getSubtitle(), published.getDescription(),
                published.getCategoryCode(), published.getLevelCode(), published.getMinutes(), published.getSkillCodes()))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(published::markReadyForReview)
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void postgresRejectsPublishedPayloadMutationWhenJavaIsBypassed() {
        var published = publish(vocabulary(code("published-db"), 1, checksum('a')));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.content_revision set title = 'Bypassed mutation' where id = ?",
                        published.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void postgresRejectsPublishedTypedBodyMutationWhenJavaIsBypassed() {
        var published = publish(vocabulary(code("published-body"), 1, checksum('a')));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.content_vocabulary_revision set term = 'Bypassed term' where revision_id = ?",
                        published.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void postgresRejectsLifecycleSkippingAndIncompleteFreeze() {
        var draft = repository.saveAndFlush(vocabulary(code("skip-lifecycle"), 1, checksum('a')));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.content_revision set lifecycle = 'PUBLISHED', published_at = now() where id = ?",
                        draft.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);

        UUID incompleteId = UUID.randomUUID();
        String incompleteCode = code("incomplete");
        jdbcTemplate.update("""
                insert into app.content_revision(
                    id, version, created_at, updated_at, content_code, content_type, revision_number,
                    lifecycle, checksum_sha256, title, subtitle, description, category_code, level_code,
                    minutes, availability, approved_at, published_at)
                values (?, 0, now(), now(), ?, 'topic', 1, 'DRAFT', ?, 'Title', 'Subtitle', 'Description',
                        'TOPIC', 'B2', 5, 'ACTIVE', null, null)
                """, incompleteId, incompleteCode, checksum('b').value());

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.content_revision set lifecycle = 'READY_FOR_AUDIO' where id = ?",
                        incompleteId))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void hardDeleteIsRejectedSoRevisionIdentityCannotBeReused() {
        var draft = repository.saveAndFlush(vocabulary(code("no-delete"), 1, checksum('a')));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "delete from app.content_revision where id = ?",
                        draft.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void productionContentTablesAreOwnedByNoLoginOwnerRole() {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList("""
                select tablename, tableowner
                  from pg_tables
                 where schemaname = 'app'
                   and tablename in (
                     'content_revision', 'content_revision_skill',
                     'content_vocabulary_revision', 'content_vocabulary_example',
                     'content_interview_revision', 'content_interview_key_point',
                     'content_topic_revision', 'content_topic_section',
                     'content_phrase_revision', 'content_phrase_example',
                     'content_shadowing_revision', 'content_shadowing_segment')
                 order by tablename
                """);

        assertThat(rows).hasSize(12);
        assertThat(rows).allSatisfy(row -> assertThat(row.get("tableowner")).isEqualTo("voxprep_owner"));
    }

    private VocabularyContentRevisionEntity publish(VocabularyContentRevisionEntity revision) {
        ContentRevisionEntity current = repository.saveAndFlush(revision);
        current.markReadyForAudio();
        current = repository.saveAndFlush(current);
        current.markReadyForReview();
        current = repository.saveAndFlush(current);
        current.approve(Instant.parse("2026-11-02T11:30:00Z"));
        current = repository.saveAndFlush(current);
        current.publish(Instant.parse("2026-11-02T12:00:00Z"));
        return (VocabularyContentRevisionEntity) repository.saveAndFlush(current);
    }

    private static VocabularyContentRevisionEntity vocabulary(String code, int revision, Sha256Digest checksum) {
        return new VocabularyContentRevisionEntity(
                new BusinessCode(code),
                new RevisionNumber(revision),
                checksum,
                "Vocabulary title",
                "Vocabulary subtitle",
                "Vocabulary description",
                new CatalogueCode("VOCABULARY"),
                new CatalogueCode("B2"),
                4,
                List.of(new CatalogueCode("SPEAKING"), new CatalogueCode("VOCABULARY")),
                AvailabilityStatus.ACTIVE,
                "negotiate",
                "to discuss in order to reach agreement",
                "verb",
                List.of("Example one", "Example two"));
    }

    private static Sha256Digest checksum(char value) {
        return new Sha256Digest(String.valueOf(value).repeat(64));
    }

    private static String code(String prefix) {
        return prefix + "-" + UUID.randomUUID();
    }

    private static void rollbackIfActive(EntityManager entityManager) {
        if (entityManager.getTransaction().isActive()) {
            entityManager.getTransaction().rollback();
        }
    }
}
