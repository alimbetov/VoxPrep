package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.application.ContentXmlDryRunService;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import java.io.ByteArrayInputStream;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/** One validated XML file becomes one atomic batch of DRAFT revisions; no approval/publishing. */
@Service
public class ContentXmlImportService {
    private final ContentXmlDryRunService validation;
    private final ContentMvcMapper mapper;
    private final ContentAuthoringService authoring;
    private final ContentRevisionRepository revisions;
    private final JdbcTemplate jdbc;

    public ContentXmlImportService(ContentXmlDryRunService validation, ContentMvcMapper mapper,
            ContentAuthoringService authoring, ContentRevisionRepository revisions, JdbcTemplate jdbc) {
        this.validation = Objects.requireNonNull(validation);
        this.mapper = Objects.requireNonNull(mapper);
        this.authoring = Objects.requireNonNull(authoring);
        this.revisions = Objects.requireNonNull(revisions);
        this.jdbc = Objects.requireNonNull(jdbc);
    }

    @Transactional
    public ImportReport importDrafts(byte[] xml) {
        var structure = validation.validate(xml);
        if (!structure.valid()) {
            throw new IllegalArgumentException("XML validation failed. Run Validate XML and fix every issue.");
        }
        List<PlannedDraft> plan = parsePlan(xml);
        if (plan.isEmpty()) throw new IllegalArgumentException("No draft records found.");

        // Serialize two concurrent imports of the same identities before checking duplicates.
        // Sorted lock order prevents deadlocks when batches overlap in different orders.
        var identities = plan.stream().map(p -> p.type() + ":" + p.code()).sorted().toList();
        for (String identity : identities) {
            jdbc.execute((ConnectionCallback<Void>) connection -> {
                try (var statement = connection.prepareStatement(
                        "SELECT pg_advisory_xact_lock(hashtextextended(?, 0))")) {
                    statement.setString(1, "voxprep:xml-import:" + identity);
                    statement.execute();
                }
                return null;
            });
        }

        int existing = 0;
        List<PlannedDraft> missing = new ArrayList<>();
        // Preflight *all* records before the first database write.
        for (PlannedDraft draft : plan) {
            var found = revisions.findIdByExactIdentity(draft.code(), draft.type(), 1);
            if (found.isPresent()) {
                var revision = revisions.findById(found.orElseThrow()).orElseThrow();
                if (revision.getLifecycle() != ContentLifecycleStatus.DRAFT
                        || !revision.getChecksum().equals(draft.command().checksum())) {
                    throw new IllegalArgumentException(
                            "Row conflict for " + draft.code() + ": existing revision differs or is immutable.");
                }
                existing++;
            } else {
                // Never create revision 1 when any later revision already exists.
                if (revisions.findLatestId(draft.code(), draft.type()).isPresent()) {
                    throw new IllegalArgumentException("Cannot import over existing content " + draft.code());
                }
                missing.add(draft);
            }
            if (draft.command().body() instanceof ContentDraftUpdate.PracticeTestBody test) {
                Set<UUID> unique = new HashSet<>();
                for (UUID questionId : test.questionRevisionIds()) {
                    if (!unique.add(questionId)) {
                        throw new IllegalArgumentException("Duplicate Question revision in " + draft.code());
                    }
                    var question = revisions.findById(questionId).orElseThrow(() ->
                            new IllegalArgumentException("Unresolved approved Question revision in " + draft.code()));
                    if (!(question instanceof QuestionContentRevisionEntity)
                            || !(question.getLifecycle() == ContentLifecycleStatus.APPROVED
                            || question.getLifecycle() == ContentLifecycleStatus.PUBLISHED)) {
                        throw new IllegalArgumentException(
                                "Practice Test requires APPROVED/PUBLISHED Question revisions: " + draft.code());
                    }
                }
            }
        }

        for (PlannedDraft item : missing) {
            authoring.createInitialRevision(new BusinessCode(item.code()), item.command());
        }
        // Transaction commits only after all new DRAFT revisions are persisted.
        return new ImportReport(missing.size(), existing, plan.size());
    }

    private List<PlannedDraft> parsePlan(byte[] xml) {
        try {
            var factory = DocumentBuilderFactory.newInstance();
            factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);
            var document = factory.newDocumentBuilder().parse(new ByteArrayInputStream(xml));
            var items = new ArrayList<PlannedDraft>();
            for (Element element : children(document.getDocumentElement())) {
                var form = toForm(element);
                items.add(new PlannedDraft(
                        element.getAttribute("code"), element.getAttribute("type"), mapper.toCommand(form)));
            }
            return List.copyOf(items);
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new IllegalArgumentException("XML cannot be converted to content drafts.", exception);
        }
    }

    private static ContentMvcForms.DraftForm toForm(Element element) {
        var form = new ContentMvcForms.DraftForm();
        form.setExpectedVersion(0L);
        form.setBodyType(element.getAttribute("type"));
        form.setTitle(value(element, "title"));
        form.setSubtitle(value(element, "subtitle"));
        form.setDescription(value(element, "description"));
        form.setCategoryCode(value(element, "categoryCode"));
        form.setLevelCode(value(element, "levelCode"));
        form.setMinutes(Integer.parseInt(value(element, "minutes")));
        form.setAvailability(value(element, "availability"));
        form.setSkillCodes(joinChildren(element, "skill"));
        Element body = child(element, "body");
        if (body == null) throw new IllegalArgumentException("Content body is required");
        switch (form.getBodyType()) {
            case "phrase" -> {
                form.setPhrase(value(body, "phrase"));
                form.setUsage(value(body, "usage"));
                form.setExamples(joinChildren(body, "example"));
            }
            case "vocabulary" -> {
                form.setTerm(value(body, "term"));
                form.setDefinition(value(body, "definition"));
                form.setPartOfSpeech(value(body, "partOfSpeech"));
                form.setExamples(joinChildren(body, "example"));
            }
            case "interview" -> {
                form.setPrompt(value(body, "prompt"));
                form.setModelAnswer(value(body, "modelAnswer"));
                form.setKeyPoints(joinChildren(body, "keyPoint"));
            }
            case "topic" -> {
                var sections = new ArrayList<String>();
                for (Element section : children(body)) {
                    sections.add(value(section, "heading") + "|" + value(section, "text"));
                }
                form.setSections(String.join("\n", sections));
            }
            case "shadowing" -> {
                form.setTranscript(value(body, "transcript"));
                var segments = new ArrayList<String>();
                for (Element segment : children(body)) {
                    segments.add(segment.getAttribute("startMs") + "|"
                            + segment.getAttribute("endMs") + "|" + segment.getTextContent());
                }
                form.setSegments(String.join("\n", segments));
            }
            case "question" -> {
                form.setQuestionText(value(body, "questionText"));
                form.setExplanation(value(body, "explanation"));
                var options = new ArrayList<String>();
                for (Element option : children(body)) {
                    if ("option".equals(option.getTagName())) {
                        options.add(option.getAttribute("key") + "|"
                                + option.getAttribute("correct") + "|" + option.getTextContent());
                    }
                }
                form.setOptions(String.join("\n", options));
            }
            case "practice_test" -> {
                form.setInstructions(value(body, "instructions"));
                form.setPassingScorePercent(Integer.parseInt(value(body, "passingScorePercent")));
                form.setQuestionRevisionIds(joinChildren(body, "questionRevisionId"));
            }
            default -> throw new IllegalArgumentException("Unsupported content type");
        }
        return form;
    }

    private static String value(Element parent, String name) {
        var match = child(parent, name);
        return match == null ? null : match.getTextContent().strip();
    }

    private static String joinChildren(Element parent, String name) {
        return children(parent).stream().filter(element -> name.equals(element.getTagName()))
                .map(element -> element.getTextContent().strip())
                .reduce((left, right) -> left + "\n" + right).orElse("");
    }

    private static Element child(Element parent, String name) {
        for (Element value : children(parent)) if (name.equals(value.getTagName())) return value;
        return null;
    }

    private static List<Element> children(Element parent) {
        var elements = new ArrayList<Element>();
        for (Node item = parent.getFirstChild(); item != null; item = item.getNextSibling()) {
            if (item instanceof Element element) elements.add(element);
        }
        return elements;
    }

    private record PlannedDraft(String code, String type, ContentDraftUpdate command) {}
    public record ImportReport(int created, int alreadyPresent, int total) {}
}
