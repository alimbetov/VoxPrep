package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionOptionEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingSegmentEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicSectionEmbeddable;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import org.springframework.stereotype.Component;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/** XML → typed domain command without lossy pipe/newline MVC form codecs. */
@Component
final class ContentXmlTypedMapper {
    ContentDraftUpdate toCommand(Element entry) {
        var body = requiredChild(entry, "body");
        var type = entry.getAttribute("type");
        ContentDraftUpdate.Body typedBody = switch (type) {
            case "vocabulary" -> new ContentDraftUpdate.VocabularyBody(
                    required(body, "term"), required(body, "definition"),
                    required(body, "partOfSpeech"), values(body, "example"));
            case "phrase" -> new ContentDraftUpdate.PhraseBody(
                    required(body, "phrase"), required(body, "usage"), values(body, "example"));
            case "interview" -> new ContentDraftUpdate.InterviewBody(
                    required(body, "prompt"), required(body, "modelAnswer"), values(body, "keyPoint"));
            case "topic" -> new ContentDraftUpdate.TopicBody(children(body, "section").stream()
                    .map(section -> new TopicSectionEmbeddable(
                            required(section, "heading"), required(section, "text"))).toList());
            case "shadowing" -> new ContentDraftUpdate.ShadowingBody(
                    required(body, "transcript"), children(body, "segment").stream()
                    .map(segment -> new ShadowingSegmentEmbeddable(
                            text(segment), Integer.valueOf(segment.getAttribute("startMs")),
                            Integer.valueOf(segment.getAttribute("endMs")))).toList());
            case "question" -> new ContentDraftUpdate.QuestionBody(
                    required(body, "questionText"), required(body, "explanation"),
                    children(body, "option").stream().map(option -> new QuestionOptionEmbeddable(
                            option.getAttribute("key"), text(option),
                            Boolean.parseBoolean(option.getAttribute("correct")))).toList());
            case "practice_test" -> new ContentDraftUpdate.PracticeTestBody(
                    required(body, "instructions"), Integer.parseInt(required(body, "passingScorePercent")),
                    values(body, "questionRevisionId").stream().map(java.util.UUID::fromString).toList());
            default -> throw new IllegalArgumentException("Unsupported content type: " + type);
        };
        return new ContentDraftUpdate(
                semanticDigest(entry),
                required(entry, "title"), required(entry, "subtitle"),
                required(entry, "description"),
                new CatalogueCode(required(entry, "categoryCode")),
                new CatalogueCode(required(entry, "levelCode")),
                Integer.parseInt(required(entry, "minutes")),
                values(entry, "skill").stream().map(CatalogueCode::new).toList(),
                AvailabilityStatus.valueOf(required(entry, "availability")),
                typedBody);
    }

    /**
     * Hashes element names, sorted attribute names and length-prefixed leaf values.
     * Formatting whitespace between elements and XML comments do not change identity;
     * punctuation, embedded newlines and order of repeated values are preserved.
     */
    private static Sha256Digest semanticDigest(Element entry) {
        try {
            var md = MessageDigest.getInstance("SHA-256");
            digestNode(md, entry);
            return new Sha256Digest(HexFormat.of().formatHex(md.digest()));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }

    private static void digestNode(MessageDigest digest, Element element) {
        add(digest, element.getTagName());
        var attributes = element.getAttributes();
        var names = new ArrayList<String>();
        for (int i = 0; i < attributes.getLength(); i++) {
            names.add(attributes.item(i).getNodeName());
        }
        names.sort(Comparator.naturalOrder());
        add(digest, Integer.toString(names.size()));
        for (String name : names) {
            add(digest, name);
            add(digest, element.getAttribute(name));
        }
        var nested = children(element, null);
        add(digest, Integer.toString(nested.size()));
        if (nested.isEmpty()) {
            add(digest, text(element));
        } else {
            for (Element child : nested) digestNode(digest, child);
        }
    }

    private static void add(MessageDigest digest, String value) {
        var bytes = value.getBytes(StandardCharsets.UTF_8);
        digest.update(ByteBuffer.allocate(Integer.BYTES).putInt(bytes.length).array());
        digest.update(bytes);
    }

    private static Element requiredChild(Element parent, String name) {
        var matches = children(parent, name);
        if (matches.size() != 1) {
            throw new IllegalArgumentException("Expected one " + name);
        }
        return matches.getFirst();
    }

    private static String required(Element parent, String name) {
        return text(requiredChild(parent, name));
    }

    private static String text(Element element) {
        return element.getTextContent().strip();
    }

    private static List<String> values(Element parent, String name) {
        return children(parent, name).stream().map(ContentXmlTypedMapper::text).toList();
    }

    private static List<Element> children(Element parent, String name) {
        var list = new ArrayList<Element>();
        for (Node node = parent.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node instanceof Element element && (name == null || name.equals(element.getTagName()))) {
                list.add(element);
            }
        }
        return list;
    }
}
