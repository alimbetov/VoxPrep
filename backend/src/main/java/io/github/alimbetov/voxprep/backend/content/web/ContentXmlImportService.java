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
    private final ContentXmlTypedMapper mapper;
    private final ContentAuthoringService authoring;
    private final ContentRevisionRepository revisions;
    private final JdbcTemplate jdbc;

    public ContentXmlImportService(ContentXmlDryRunService validation, ContentXmlTypedMapper mapper,
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
                items.add(new PlannedDraft(
                        element.getAttribute("code"), element.getAttribute("type"), mapper.toCommand(element)));
            }
            return List.copyOf(items);
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new IllegalArgumentException("XML cannot be converted to content drafts.", exception);
        }
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
