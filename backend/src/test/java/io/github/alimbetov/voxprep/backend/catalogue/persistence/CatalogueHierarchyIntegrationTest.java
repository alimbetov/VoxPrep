package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import java.util.List;
import java.util.Map;
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
class CatalogueHierarchyIntegrationTest {

    @Autowired
    private VerticalRepository verticalRepository;

    @Autowired
    private LearningGoalRepository goalRepository;

    @Autowired
    private LearningTrackRepository trackRepository;

    @Autowired
    private LearningCollectionRepository collectionRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void persistsNormalizedCatalogueHierarchyAndDerivesVerticalThroughParentChain() {
        var vertical = verticalRepository.saveAndFlush(vertical("VERTICAL_ALPHA", 0));
        var goal = goalRepository.saveAndFlush(goal("GOAL_ALPHA", vertical, 0));
        var track = trackRepository.saveAndFlush(track("TRACK_ALPHA", goal, 0));
        var collection = collectionRepository.saveAndFlush(collection("COLLECTION_ALPHA", track, 0));

        var loaded = collectionRepository.findByCode(new CatalogueCode("COLLECTION_ALPHA")).orElseThrow();

        assertThat(loaded.getTrack().getGoal().getVertical().getCode().value()).isEqualTo("VERTICAL_ALPHA");
        assertThat(loaded.getAccessLevel()).isEqualTo(CollectionAccessLevel.FREE);

        String persistedAccess = jdbcTemplate.queryForObject(
                "select access_level from app.catalogue_learning_collection where id = ?",
                String.class,
                collection.getId());
        assertThat(persistedAccess).isEqualTo("FREE");

        String projectedVertical = jdbcTemplate.queryForObject(
                """
                select v.code
                  from app.catalogue_learning_collection c
                  join app.catalogue_learning_track t on t.id = c.track_id
                  join app.catalogue_learning_goal g on g.id = t.goal_id
                  join app.catalogue_vertical v on v.id = g.vertical_id
                 where c.id = ?
                """,
                String.class,
                collection.getId());
        assertThat(projectedVertical).isEqualTo("VERTICAL_ALPHA");
    }

    @Test
    void childOrderingIsDeterministicBySortOrderThenCode() {
        var vertical = verticalRepository.saveAndFlush(vertical("VERTICAL_ORDER", 0));
        goalRepository.save(goal("GOAL_B", vertical, 1));
        goalRepository.save(goal("GOAL_Z", vertical, 0));
        goalRepository.save(goal("GOAL_A", vertical, 1));
        goalRepository.flush();

        List<String> codes = goalRepository
                .findAllByVertical_IdOrderBySortOrderAscCodeAsc(vertical.getId())
                .stream()
                .map(entity -> entity.getCode().value())
                .toList();

        assertThat(codes).containsExactly("GOAL_Z", "GOAL_A", "GOAL_B");
    }

    @Test
    void productionCatalogueTablesAreOwnedByNoLoginOwnerRole() {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                """
                select tablename, tableowner
                  from pg_tables
                 where schemaname = 'app'
                   and tablename in (
                     'catalogue_vertical',
                     'catalogue_learning_goal',
                     'catalogue_learning_track',
                     'catalogue_learning_collection')
                 order by tablename
                """);

        assertThat(rows).hasSize(4);
        assertThat(rows).allSatisfy(row -> assertThat(row.get("tableowner")).isEqualTo("voxprep_owner"));
    }

    @Test
    void catalogueCodeUniquenessIsEnforcedByPostgres() {
        verticalRepository.saveAndFlush(vertical("VERTICAL_UNIQUE", 0));
        verticalRepository.save(vertical("VERTICAL_UNIQUE", 1));

        assertThatThrownBy(verticalRepository::flush)
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void parentDeletionIsRestrictedByDatabaseWhileChildrenExist() {
        var vertical = verticalRepository.saveAndFlush(vertical("VERTICAL_RESTRICT", 0));
        goalRepository.saveAndFlush(goal("GOAL_RESTRICT", vertical, 0));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "delete from app.catalogue_vertical where id = ?",
                        vertical.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void postgresRejectsNegativeSortOrderEvenWhenJavaValidationIsBypassed() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(() -> jdbcTemplate.update(
                        """
                        insert into app.catalogue_vertical(
                          id, version, created_at, updated_at, code, section_code,
                          title, description, icon_asset_id, sort_order, availability)
                        values (?, 0, now(), now(), 'VERTICAL_BAD_SORT', 'SOFTWARE_ENGINEERING',
                                'Bad sort', 'Database constraint qualification', 'asset-bad', -1, 'ACTIVE')
                        """,
                        id))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private static VerticalEntity vertical(String code, int sortOrder) {
        return new VerticalEntity(
                new CatalogueCode(code),
                new CatalogueCode("SOFTWARE_ENGINEERING"),
                "Vertical " + code,
                "Description for " + code,
                "asset-" + code.toLowerCase(),
                sortOrder,
                AvailabilityStatus.ACTIVE);
    }

    private static LearningGoalEntity goal(String code, VerticalEntity vertical, int sortOrder) {
        return new LearningGoalEntity(
                new CatalogueCode(code),
                vertical,
                "Goal " + code,
                "Description for " + code,
                sortOrder,
                AvailabilityStatus.ACTIVE);
    }

    private static LearningTrackEntity track(String code, LearningGoalEntity goal, int sortOrder) {
        return new LearningTrackEntity(
                new CatalogueCode(code),
                goal,
                "Track " + code,
                "Description for " + code,
                new CatalogueCode("B2"),
                null,
                sortOrder,
                AvailabilityStatus.ACTIVE);
    }

    private static LearningCollectionEntity collection(
            String code,
            LearningTrackEntity track,
            int sortOrder) {
        return new LearningCollectionEntity(
                new CatalogueCode(code),
                track,
                "Collection " + code,
                "Description for " + code,
                CollectionAccessLevel.FREE,
                sortOrder,
                AvailabilityStatus.ACTIVE);
    }
}
