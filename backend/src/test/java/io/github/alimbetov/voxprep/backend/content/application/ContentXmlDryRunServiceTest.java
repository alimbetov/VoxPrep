package io.github.alimbetov.voxprep.backend.content.application;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

class ContentXmlDryRunServiceTest {
    private final ContentXmlDryRunService validator = new ContentXmlDryRunService();

    @Test
    void downloadableTemplatePassesValidationWithoutWritingAnything() throws Exception {
        var xml = new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray();
        var report = validator.validate(xml);
        assertThat(report.valid()).as(report.issues().toString()).isTrue();
        assertThat(report.preview()).hasSize(7);
        assertThat(report.preview().getFirst().code()).isEqualTo("PHRASE_INTERVIEW_INTRO_01");
    }

    @Test
    void rejectsDoctypeAndExternalEntityBeforeProcessing() {
        var payload = """
                <?xml version="1.0"?>
                <!DOCTYPE voxprep [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
                <voxprep schemaVersion="1"><content code="XXE" type="phrase">
                <title>&xxe;</title></content></voxprep>
                """;
        assertThat(validator.validate(payload.getBytes(StandardCharsets.UTF_8)).valid()).isFalse();
    }

    @Test
    void rejectsInvalidXsdUnknownVersionAndMalformedDocument() {
        var sample = """
                <voxprep schemaVersion="2"><content code="X" type="phrase">
                <title>X</title></content></voxprep>
                """;
        assertThat(validator.validate(sample.getBytes(StandardCharsets.UTF_8)).valid()).isFalse();
        assertThat(validator.validate("<voxprep>".getBytes(StandardCharsets.UTF_8)).valid()).isFalse();
    }

    @Test
    void rejectsUnexpectedNestedMarkupAndDuplicateSingletonBodyFields() throws Exception {
        var sample = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        var nested = sample.replace("<heading>HTTP</heading>",
                "<heading>HTTP<arbitrary>injection</arbitrary></heading>");
        var nestedResult = validator.validate(nested.getBytes(StandardCharsets.UTF_8));
        assertThat(nestedResult.valid()).isFalse();
        assertThat(nestedResult.issues()).anyMatch(x -> x.contains("invalid section field"));

        var duplicate = sample.replace("<phrase>I specialize in Java backend development.</phrase>",
                "<phrase>I specialize in Java backend development.</phrase>"
                        + "<phrase>Unexpected duplicate</phrase>");
        var result = validator.validate(duplicate.getBytes(StandardCharsets.UTF_8));
        assertThat(result.valid()).isFalse();
        assertThat(result.issues()).anyMatch(x -> x.contains("duplicate field phrase"));
    }

    @Test
    void rejectsUnexpectedOptionAttributesAndUnknownBodyElement() throws Exception {
        var sample = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        var tampered = sample.replace("correct=\"true\"", "correct=\"true\" executable=\"anything\"");
        var result = validator.validate(tampered.getBytes(StandardCharsets.UTF_8));
        assertThat(result.valid()).isFalse();
        assertThat(result.issues()).anyMatch(x -> x.contains("unsupported attribute executable"));

        var unknown = sample.replace("<usage>Introduce your technical background.</usage>",
                "<usage>Introduce your technical background.</usage><unexpected>Extra</unexpected>");
        assertThat(validator.validate(unknown.getBytes(StandardCharsets.UTF_8)).valid()).isFalse();
    }

    @Test
    void enforcesByteBoundAndRejectsDuplicateCodes() throws Exception {
        assertThat(validator.validate(new byte[ContentXmlDryRunService.MAX_BYTES + 1]).valid()).isFalse();
        var original = new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray();
        var xml = new String(original, StandardCharsets.UTF_8);
        var start = xml.indexOf("  <content ");
        var end = xml.indexOf("  </content>") + "  </content>".length();
        var duplicate = xml.replace("</voxprep>", xml.substring(start, end) + "\n</voxprep>");
        var result = validator.validate(duplicate.getBytes(StandardCharsets.UTF_8));
        assertThat(result.valid()).isFalse();
        assertThat(result.issues()).anyMatch(x -> x.contains("duplicate"));
    }
}
