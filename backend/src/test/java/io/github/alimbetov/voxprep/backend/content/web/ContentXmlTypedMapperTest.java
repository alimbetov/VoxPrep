package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import javax.xml.parsers.DocumentBuilderFactory;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Element;

class ContentXmlTypedMapperTest {
    private final ContentXmlTypedMapper mapper = new ContentXmlTypedMapper();

    private static Element entry(String type, String body) throws Exception {
        String xml = """
                <content code="REVIEW_001" type="%s">
                  <title>Architectures | APIs</title><subtitle>Java interviews</subtitle>
                  <description>Multi-line preservation</description>
                  <categoryCode>INTERVIEW</categoryCode><levelCode>B2</levelCode>
                  <minutes>3</minutes><availability>ACTIVE</availability>
                  <skill>SPEAKING</skill><body>%s</body>
                </content>
                """.formatted(type, body);
        var factory = DocumentBuilderFactory.newInstance();
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        factory.setExpandEntityReferences(false);
        return factory.newDocumentBuilder().parse(new ByteArrayInputStream(
                xml.getBytes(StandardCharsets.UTF_8))).getDocumentElement();
    }

    @Test
    void topicPreservesPipeAndMultilineBodyWithoutMvcCodec() throws Exception {
        var update = mapper.toCommand(entry("topic", """
                <section><heading>REST | HTTP</heading>
                <text>Line one | API
                Line two</text></section>
                """));
        var body = (ContentDraftUpdate.TopicBody) update.body();
        assertThat(body.sections()).hasSize(1);
        assertThat(body.sections().getFirst().getHeading()).isEqualTo("REST | HTTP");
        assertThat(body.sections().getFirst().getText()).isEqualTo("Line one | API\nLine two");
    }

    @Test
    void phraseExamplesKeepEmbeddedNewlinesAsSingleValue() throws Exception {
        var update = mapper.toCommand(entry("phrase", """
                <phrase>Java | Spring</phrase><usage>Use in interviews</usage>
                <example>First | line
                Second line</example>
                """));
        var body = (ContentDraftUpdate.PhraseBody) update.body();
        assertThat(body.examples()).containsExactly("First | line\nSecond line");
    }

    @Test
    void questionOptionsRetainTextOrderAndCorrectness() throws Exception {
        var update = mapper.toCommand(entry("question", """
                <questionText>Select a solution</questionText><explanation>Clean architecture</explanation>
                <option key="A" correct="false">A | B</option>
                <option key="B" correct="true">Second
                line</option>
                """));
        var body = (ContentDraftUpdate.QuestionBody) update.body();
        assertThat(body.options()).hasSize(2);
        assertThat(body.options().getFirst().getText()).isEqualTo("A | B");
        assertThat(body.options().get(1).getText()).isEqualTo("Second\nline");
        assertThat(body.options().get(1).isCorrect()).isTrue();
    }

    @Test
    void semanticHashIgnoresXmlFormattingButDetectsValueChanges() throws Exception {
        var first = mapper.toCommand(entry("phrase",
                "<phrase>Java</phrase><usage>Interview</usage><example>A | B</example>"));
        var formatted = mapper.toCommand(entry("phrase",
                "\n  <phrase>Java</phrase>\n <usage>Interview</usage>\n <example>A | B</example>\n"));
        var changed = mapper.toCommand(entry("phrase",
                "<phrase>Java</phrase><usage>Interview</usage><example>A | C</example>"));
        assertThat(first.checksum()).isEqualTo(formatted.checksum());
        assertThat(changed.checksum()).isNotEqualTo(first.checksum());
    }

    @Test
    void shadowingSegmentKeepsMillisecondsExactly() throws Exception {
        var update = mapper.toCommand(entry("shadowing", """
                <transcript>Hello</transcript>
                <segment startMs="125" endMs="875">Hello | world</segment>
                """));
        var body = (ContentDraftUpdate.ShadowingBody) update.body();
        assertThat(body.segments().getFirst().getStartMs()).isEqualTo(125);
        assertThat(body.segments().getFirst().getEndMs()).isEqualTo(875);
        assertThat(body.segments().getFirst().getText()).isEqualTo("Hello | world");
    }
}
