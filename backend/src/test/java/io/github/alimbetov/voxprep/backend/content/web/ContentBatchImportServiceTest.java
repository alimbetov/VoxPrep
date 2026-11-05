package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

/** Real JSON/XML parsers, production mapper, mocked persistence boundary. */
class ContentBatchImportServiceTest {
    private final ContentAuthoringService authoring = mock(ContentAuthoringService.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final ContentBatchImportService importer = new ContentBatchImportService(
            new ObjectMapper(), new ContentMvcMapper(), authoring, revisions);

    @BeforeEach
    void setup() {
        when(revisions.findIdByExactIdentity(anyString(), anyString(), eq(1)))
                .thenReturn(Optional.empty());
    }

    @Test
    void jsonPreviewDoesNotWriteAndImportCreatesOneDraftThroughAuthoringService() {
        byte[] body = validJson();
        var preview = importer.preview("content.json", body);
        assertThat(preview.rows()).hasSize(1);
        assertThat(preview.newCount()).isEqualTo(1);
        verifyNoInteractions(authoring);

        assertThat(importer.importDrafts("content.json", body)).isEqualTo(1);
        verify(authoring).createInitialRevision(any(BusinessCode.class),
                any(ContentDraftUpdate.class));
    }

    @Test
    void xmlIsDelegatedToTheXsdBackedImporter() {
        assertThatThrownBy(() -> importer.preview("content.xml",
                "<voxprepImport/>".getBytes(StandardCharsets.UTF_8)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("XSD importer");
        verifyNoInteractions(authoring);
    }

    @Test
    void existingFirstRevisionIsIdempotentlySkipped() {
        when(revisions.findIdByExactIdentity(anyString(), anyString(), eq(1)))
                .thenReturn(Optional.of(UUID.randomUUID()));
        assertThat(importer.importDrafts("content.json", validJson())).isZero();
        verifyNoInteractions(authoring);
    }

    @Test
    void xmlExternalEntityIsRejectedBeforePreviewAndNoWriteOccurs() {
        var xml = """
                <!DOCTYPE voxprepImport [
                  <!ENTITY xxe SYSTEM "file:///etc/passwd">
                ]><voxprepImport schemaVersion="1">
                  <item contentCode="XXX" bodyType="phrase">&xxe;</item>
                </voxprepImport>
                """.getBytes(StandardCharsets.UTF_8);
        assertThatThrownBy(() -> importer.preview("content.xml", xml))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(authoring);
    }

    @Test
    void incompleteBodyCannotBePreviewedOrImported() {
        var invalid = new String(validJson(), StandardCharsets.UTF_8)
                .replace("\"body\":{\"phrase\":\"Hello\",\"usage\":\"Greeting context\",\"examples\":[\"Hello there\"]}",
                        "\"body\":{}")
                .getBytes(StandardCharsets.UTF_8);
        assertThatThrownBy(() -> importer.preview("content.json", invalid))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> importer.importDrafts("content.json", invalid))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(authoring);
    }

    private static byte[] validJson() {
        return """
                {"schemaVersion":1,"items":[{
                 "contentCode":"IMPORT_PHRASE_JSON","bodyType":"phrase",
                 "title":"Hello","subtitle":"Greetings",
                 "description":"Greeting exercise",
                 "categoryCode":"COMMUNICATION","levelCode":"B1",
                 "minutes":3,"availability":"ACTIVE","skillCodes":["SPEAKING"],
                 "body":{"phrase":"Hello","usage":"Greeting context","examples":["Hello there"]}
                }]}
                """.getBytes(StandardCharsets.UTF_8);
    }
}
