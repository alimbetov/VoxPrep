package io.github.alimbetov.voxprep.backend.content.application;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

/**
 * Security and boundary regression for the public XML document format.
 * These scenarios are independent of PostgreSQL so they execute quickly in B1.
 */
class ContentXmlBoundaryTest {
    private final ContentXmlDryRunService service = new ContentXmlDryRunService();

    private static String phrase(String code) {
        return """
              <content code="%s" type="phrase">
                <title>Java backend</title>
                <subtitle>Interview</subtitle>
                <description>Example</description>
                <categoryCode>INTERVIEW</categoryCode>
                <levelCode>B2</levelCode>
                <minutes>2</minutes>
                <availability>ACTIVE</availability>
                <skill>SPEAKING</skill>
                <body>
                  <phrase>My experience</phrase>
                  <usage>Interview answer</usage>
                  <example>Spring Boot</example>
                </body>
              </content>
                """.formatted(code);
    }

    private static byte[] document(int count) {
        var xml = new StringBuilder("<voxprep schemaVersion=\"1\">");
        for (int index = 0; index < count; index++) {
            xml.append(phrase("BOUNDARY_%03d".formatted(index)));
        }
        xml.append("</voxprep>");
        return xml.toString().getBytes(StandardCharsets.UTF_8);
    }

    @Test
    void acceptsOneHundredUniqueEntriesButRejectsOneHundredAndOne() {
        var maximum = service.validate(document(100));
        assertThat(maximum.valid()).as(maximum.issues().toString()).isTrue();
        assertThat(maximum.preview()).hasSize(100);

        var overLimit = service.validate(document(101));
        assertThat(overLimit.valid()).isFalse();
        assertThat(overLimit.preview()).isEmpty();
    }

    @Test
    void rejectsEmptyAndOversizePayloadWithoutParsing() {
        assertThat(service.validate(null).valid()).isFalse();
        assertThat(service.validate(new byte[0]).valid()).isFalse();
        assertThat(service.validate(new byte[ContentXmlDryRunService.MAX_BYTES + 1]).valid())
                .isFalse();
    }

    @Test
    void rejectsInternalEntityAndRemoteDtdWithoutReadingResources() {
        String internalEntity = """
                <!DOCTYPE voxprep [<!ENTITY payload "injected">]>
                <voxprep schemaVersion="1">&payload;</voxprep>
                """;
        String remoteDtd = """
                <!DOCTYPE voxprep SYSTEM "https://invalid.example/evil.dtd">
                <voxprep schemaVersion="1"></voxprep>
                """;
        assertThat(service.validate(internalEntity.getBytes(StandardCharsets.UTF_8)).valid()).isFalse();
        assertThat(service.validate(remoteDtd.getBytes(StandardCharsets.UTF_8)).valid()).isFalse();
    }

    @Test
    void rejectsDuplicateIdentityAndMalformedVersions() {
        String duplicate = "<voxprep schemaVersion=\"1\">"
                + phrase("SAME_CODE") + phrase("SAME_CODE") + "</voxprep>";
        var result = service.validate(duplicate.getBytes(StandardCharsets.UTF_8));
        assertThat(result.valid()).isFalse();
        assertThat(result.issues()).anyMatch(s -> s.contains("duplicate content code"));

        String unknownVersion = new String(document(1), StandardCharsets.UTF_8)
                .replace("schemaVersion=\"1\"", "schemaVersion=\"99\"");
        assertThat(service.validate(unknownVersion.getBytes(StandardCharsets.UTF_8)).valid()).isFalse();
    }

    @Test
    void downloadableExampleRemainsValidAlongsideBoundaryFixtures() throws Exception {
        byte[] template = new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray();
        var result = service.validate(template);
        assertThat(result.valid()).as(result.issues().toString()).isTrue();
        assertThat(result.preview()).hasSize(7);
    }
}
