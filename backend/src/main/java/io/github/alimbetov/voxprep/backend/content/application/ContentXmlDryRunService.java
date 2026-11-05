package io.github.alimbetov.voxprep.backend.content.application;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.validation.SchemaFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

/** Strict, bounded, read-only XML validation; does not persist imported records. */
@Service
public final class ContentXmlDryRunService {
    public static final int MAX_BYTES = 1024 * 1024;
    private static final int MAX_ISSUES = 50;

    private static final Map<String, Set<String>> BODY_FIELDS = Map.of(
            "phrase", Set.of("phrase", "usage", "example"),
            "vocabulary", Set.of("term", "definition", "partOfSpeech", "example"),
            "interview", Set.of("prompt", "modelAnswer", "keyPoint"),
            "topic", Set.of("section"),
            "shadowing", Set.of("transcript", "segment"),
            "question", Set.of("questionText", "explanation", "option"),
            "practice_test", Set.of("instructions", "passingScorePercent", "questionRevisionId"));

    public ValidationReport validate(byte[] bytes) {
        List<String> problems = new ArrayList<>();
        List<ContentPreview> previews = new ArrayList<>();
        if (bytes == null || bytes.length == 0 || bytes.length > MAX_BYTES) {
            return new ValidationReport(false, List.of("XML file must be between 1 byte and 1 MiB."), List.of());
        }
        try {
            var factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
            var builder = factory.newDocumentBuilder();
            builder.setErrorHandler(new org.xml.sax.helpers.DefaultHandler() {
                @Override public void error(org.xml.sax.SAXParseException exception) throws SAXException {
                    throw exception;
                }
                @Override public void fatalError(org.xml.sax.SAXParseException exception) throws SAXException {
                    throw exception;
                }
            });
            var document = builder.parse(new ByteArrayInputStream(bytes));
            var schemaFactory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
            schemaFactory.setProperty(XMLConstants.ACCESS_EXTERNAL_DTD, "");
            schemaFactory.setProperty(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
            schemaFactory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
            var schemaResource = new ClassPathResource("imports/voxprep-content-v1.xsd");
            try (InputStream stream = schemaResource.getInputStream()) {
                var schema = schemaFactory.newSchema(new javax.xml.transform.stream.StreamSource(stream));
                schema.newValidator().validate(new javax.xml.transform.dom.DOMSource(document));
            }
            var codes = new HashSet<String>();
            int index = 0;
            for (Element entry : children(document.getDocumentElement())) {
                index++;
                String label = "Row " + index + ": ";
                String code = entry.getAttribute("code");
                String type = entry.getAttribute("type");
                if (!code.matches("[A-Za-z0-9][A-Za-z0-9._-]{0,127}") || !codes.add(code)) {
                    issue(problems, label + "invalid or duplicate content code");
                }
                for (String field : List.of("title", "subtitle", "description", "categoryCode", "levelCode")) {
                    var child = one(entry, field);
                    if (child == null || child.getTextContent().isBlank()
                            || child.getTextContent().length() > ("description".equals(field) ? 4000 : 512)) {
                        issue(problems, label + "invalid " + field);
                    }
                }
                for (String field : List.of("categoryCode", "levelCode")) {
                    var child = one(entry, field);
                    if (child != null && !child.getTextContent().matches("[A-Za-z0-9][A-Za-z0-9._-]{0,127}")) {
                        issue(problems, label + "invalid " + field + " code");
                    }
                }
                Element body = one(entry, "body");
                if (body == null) {
                    issue(problems, label + "missing body");
                    continue;
                }
                var fields = BODY_FIELDS.get(type);
                if (fields == null) {
                    issue(problems, label + "unsupported content type");
                    continue;
                }
                for (Element child : children(body)) {
                    if (!fields.contains(child.getTagName())) {
                        issue(problems, label + "unsupported body element: " + child.getTagName());
                    } else if (child.getTextContent().isBlank() || child.getTextContent().length() > 4000) {
                        issue(problems, label + "empty or oversized " + child.getTagName());
                    }
                }
                String[] required = switch (type) {
                    case "phrase" -> new String[] {"phrase", "usage"};
                    case "vocabulary" -> new String[] {"term", "definition"};
                    case "interview" -> new String[] {"prompt", "modelAnswer"};
                    case "topic" -> new String[] {"section"};
                    case "shadowing" -> new String[] {"transcript", "segment"};
                    case "question" -> new String[] {"questionText", "option"};
                    case "practice_test" -> new String[] {"instructions", "passingScorePercent", "questionRevisionId"};
                    default -> new String[0];
                };
                for (String field : required) {
                    if (one(body, field) == null) issue(problems, label + "missing " + field);
                }
                if ("practice_test".equals(type)) {
                    var percent = one(body, "passingScorePercent");
                    if (percent != null && !percent.getTextContent().matches("(100|[0-9]|[1-9][0-9])")) {
                        issue(problems, label + "passingScorePercent must be 0-100");
                    }
                    for (Element id : children(body)) {
                        if ("questionRevisionId".equals(id.getTagName())) {
                            try { UUID.fromString(id.getTextContent().strip()); }
                            catch (IllegalArgumentException ex) { issue(problems, label + "invalid question UUID"); }
                        }
                    }
                }
                if ("question".equals(type)) {
                    int correct = 0;
                    var optionKeys = new HashSet<String>();
                    for (Element option : children(body)) {
                        if (!"option".equals(option.getTagName())) continue;
                        if (!option.getAttribute("key").matches("[A-Za-z0-9_-]{1,32}")
                                || !optionKeys.add(option.getAttribute("key"))) {
                            issue(problems, label + "invalid or duplicate option key");
                        }
                        if (!Set.of("true", "false").contains(option.getAttribute("correct"))) {
                            issue(problems, label + "option correct must be true or false");
                        }
                        if ("true".equals(option.getAttribute("correct"))) correct++;
                    }
                    if (correct != 1) issue(problems, label + "question requires exactly one correct option");
                }
                if ("shadowing".equals(type)) {
                    long previousEnd = -1;
                    for (Element seg : children(body)) {
                        if (!"segment".equals(seg.getTagName())) continue;
                        try {
                            long start = Long.parseLong(seg.getAttribute("startMs"));
                            long end = Long.parseLong(seg.getAttribute("endMs"));
                            if (start < 0 || end <= start || start < previousEnd) throw new NumberFormatException();
                            previousEnd = end;
                        } catch (NumberFormatException ex) { issue(problems, label + "invalid or overlapping segment times"); }
                    }
                }
                if ("topic".equals(type)) {
                    for (Element section : children(body)) {
                        if ("section".equals(section.getTagName())
                                && (one(section, "heading") == null || one(section, "text") == null)) {
                            issue(problems, label + "section requires heading and text");
                        }
                    }
                }
                previews.add(new ContentPreview(code, type,
                        one(entry, "title") == null ? "" : one(entry, "title").getTextContent()));
            }
            return new ValidationReport(problems.isEmpty(), List.copyOf(problems), List.copyOf(previews));
        } catch (Exception exception) {
            // Never expose parser file paths, uploaded XML or implementation internals.
            return new ValidationReport(false, List.of("Malformed XML or XSD validation failed. Check the v1 template and schema."), List.of());
        }
    }

    private static Element one(Element parent, String name) {
        for (Element element : children(parent)) if (name.equals(element.getTagName())) return element;
        return null;
    }
    private static List<Element> children(Element parent) {
        var result = new ArrayList<Element>();
        for (Node item = parent.getFirstChild(); item != null; item = item.getNextSibling()) {
            if (item instanceof Element element) result.add(element);
        }
        return result;
    }
    private static void issue(List<String> problems, String message) {
        if (problems.size() < MAX_ISSUES) problems.add(message);
    }
    public record ContentPreview(String code, String type, String title) {}
    public record ValidationReport(boolean valid, List<String> issues, List<ContentPreview> preview) {}
}
