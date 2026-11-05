package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest
class ContentXmlImportServiceIntegrationTest {
    @Autowired private ContentXmlImportService importer;
    @Autowired private ContentRevisionRepository revisions;

    private byte[] exampleWithoutUnresolvedPracticeTest() throws Exception {
        String xml = new String(new ClassPathResource(
                "imports/voxprep-content-template-v1.xml").getContentAsByteArray(), StandardCharsets.UTF_8);
        return xml.replaceAll("(?s)\\s*<content code=\"PRACTICE_ARCH_01\".*?</content>", "")
                .getBytes(StandardCharsets.UTF_8);
    }

    @Test
    void importsSixTypedDraftsAtomicallyAndReplaysWithoutDuplicates() throws Exception {
        byte[] xml = exampleWithoutUnresolvedPracticeTest();
        long before = revisions.count();
        var imported = importer.importDrafts(xml);
        assertThat(imported.created()).isEqualTo(6);
        assertThat(imported.alreadyPresent()).isZero();
        assertThat(revisions.count()).isEqualTo(before + 6);
        var replay = importer.importDrafts(xml);
        assertThat(replay.created()).isZero();
        assertThat(replay.alreadyPresent()).isEqualTo(6);
        assertThat(revisions.count()).isEqualTo(before + 6);
        var draftId = revisions.findIdByExactIdentity("PHRASE_INTERVIEW_INTRO_01", "phrase", 1);
        assertThat(draftId).isPresent();
        assertThat(revisions.findById(draftId.orElseThrow()).orElseThrow().getLifecycle())
                .isEqualTo(ContentLifecycleStatus.DRAFT);
    }

    @Test
    void unresolvedPracticeTestQuestionRejectsAllWrites() throws Exception {
        byte[] xml = new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray();
        long before = revisions.count();
        assertThatThrownBy(() -> importer.importDrafts(xml))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unresolved approved Question");
        assertThat(revisions.count()).isEqualTo(before);
    }

    @Test
    void invalidXmlCannotCausePartialWrites() throws Exception {
        byte[] xml = exampleWithoutUnresolvedPracticeTest();
        String invalid = new String(xml, StandardCharsets.UTF_8)
                .replace("<minutes>2</minutes>", "<minutes>-5</minutes>");
        long before = revisions.count();
        assertThatThrownBy(() -> importer.importDrafts(invalid.getBytes(StandardCharsets.UTF_8)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("XML validation failed");
        assertThat(revisions.count()).isEqualTo(before);
    }
}
