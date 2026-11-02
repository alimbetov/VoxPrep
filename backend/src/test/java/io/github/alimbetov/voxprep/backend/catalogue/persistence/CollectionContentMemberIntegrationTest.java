package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.UUID;
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
class CollectionContentMemberIntegrationTest {

    @Autowired
    private VerticalRepository verticalRepository;

    @Autowired
    private LearningGoalRepository goalRepository;

    @Autowired
    private LearningTrackRepository trackRepository;

    @Autowired
    private LearningCollectionRepository collectionRepository;

    @Autowired
    private ContentRevisionRepository contentRevisionRepository;

    @Autowired
    private CollectionContentMemberRepository memberRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void collectionPersistsOrderedExactContentRevisionMembers() {
        var collection = persistCollection("MEMBER_ORDER");
        var firstRevision = contentRevisionRepository.saveAndFlush(vocabulary("member-first"));
        var secondRevision = contentRevisionRepository.saveAndFlush(vocabulary("member-second"));

        memberRepository.save(new CollectionContentMemberEntity(collection, 1, secondRevision));
        memberRepository.save(new CollectionContentMemberEntity(collection, 0, firstRevision));
        memberRepository.flush();

        var loaded = memberRepository.findAllByCollectionIdOrderByPositionAsc(collection.getId());

        assertThat(loaded).hasSize(2);
        assertThat(loaded.get(0).getPosition()).isZero();
        assertThat(loaded.get(0).getContentRevision().getId()).isEqualTo(firstRevision.getId());
        assertThat(loaded.get(1).getPosition()).isEqualTo(1);
        assertThat(loaded.get(1).getContentRevision().getId()).isEqualTo(secondRevision.getId());
        assertThat(memberRepository.existsByCollectionIdAndContentRevisionId(
                collection.getId(), firstRevision.getId())).isTrue();
    }

    @Test
    void postgresRejectsDuplicatePositionInsideCollection() {
        var collection = persistCollection("MEMBER_DUP_POSITION");
        var firstRevision = contentRevisionRepository.saveAndFlush(vocabulary("position-first"));
        var secondRevision = contentRevisionRepository.saveAndFlush(vocabulary("position-second"));

        memberRepository.saveAndFlush(new CollectionContentMemberEntity(collection, 0, firstRevision));
        memberRepository.save(new CollectionContentMemberEntity(collection, 0, secondRevision));

        assertThatThrownBy(memberRepository::flush)
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void postgresRejectsSameExactRevisionTwiceInsideCollection() {
        var collection = persistCollection("MEMBER_DUP_REVISION");
        var revision = contentRevisionRepository.saveAndFlush(vocabulary("revision-duplicate"));

        memberRepository.saveAndFlush(new CollectionContentMemberEntity(collection, 0, revision));
        memberRepository.save(new CollectionContentMemberEntity(collection, 1, revision));

        assertThatThrownBy(memberRepository::flush)
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void databaseRestrictsDeletionOfReferencedExactRevision() {
        var collection = persistCollection("MEMBER_RESTRICT");
        var revision = contentRevisionRepository.saveAndFlush(vocabulary("referenced-revision"));
        memberRepository.saveAndFlush(new CollectionContentMemberEntity(collection, 0, revision));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "delete from app.content_revision where id = ?",
                        revision.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private LearningCollectionEntity persistCollection(String suffix) {
        var vertical = verticalRepository.saveAndFlush(new VerticalEntity(
                new CatalogueCode("VERTICAL_" + suffix),
                new CatalogueCode("SOFTWARE_ENGINEERING"),
                "Vertical " + suffix,
                "Description " + suffix,
                "asset-" + suffix.toLowerCase(),
                0,
                AvailabilityStatus.ACTIVE));
        var goal = goalRepository.saveAndFlush(new LearningGoalEntity(
                new CatalogueCode("GOAL_" + suffix),
                vertical,
                "Goal " + suffix,
                "Description " + suffix,
                0,
                AvailabilityStatus.ACTIVE));
        var track = trackRepository.saveAndFlush(new LearningTrackEntity(
                new CatalogueCode("TRACK_" + suffix),
                goal,
                "Track " + suffix,
                "Description " + suffix,
                new CatalogueCode("B2"),
                null,
                0,
                AvailabilityStatus.ACTIVE));
        return collectionRepository.saveAndFlush(new LearningCollectionEntity(
                new CatalogueCode("COLLECTION_" + suffix),
                track,
                "Collection " + suffix,
                "Description " + suffix,
                CollectionAccessLevel.FREE,
                0,
                AvailabilityStatus.ACTIVE));
    }

    private static VocabularyContentRevisionEntity vocabulary(String prefix) {
        String code = prefix + "-" + UUID.randomUUID();
        return new VocabularyContentRevisionEntity(
                new BusinessCode(code),
                new RevisionNumber(1),
                new Sha256Digest("a".repeat(64)),
                "Vocabulary title",
                "Vocabulary subtitle",
                "Vocabulary description",
                new CatalogueCode("VOCABULARY"),
                new CatalogueCode("B2"),
                4,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "negotiate",
                "to discuss in order to reach agreement",
                "verb",
                List.of("Example one"));
    }
}
