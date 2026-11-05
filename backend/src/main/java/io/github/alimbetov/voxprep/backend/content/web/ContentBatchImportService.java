package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

/**
 * JSON-only Content Studio import. XML is handled by ContentXmlImportService. No direct SQL and no
 * auto-approval. All bodies use the exact production MVC body mapper.
 */
@Service
public class ContentBatchImportService {
    static final int MAX_BYTES = 262_144;
    static final int MAX_ITEMS = 100;
    private final ObjectMapper json;
    private final ContentMvcMapper mapper;
    private final ContentAuthoringService authoring;
    private final ContentRevisionRepository revisions;
    private final JdbcTemplate jdbc;

    public ContentBatchImportService(ObjectMapper json, ContentMvcMapper mapper,
            ContentAuthoringService authoring, ContentRevisionRepository revisions,
            JdbcTemplate jdbc) {
        this.json = json;
        this.mapper = mapper;
        this.authoring = authoring;
        this.revisions = revisions;
        this.jdbc = jdbc;
    }

    public record PreviewRow(String code, String contentType, String title, boolean alreadyExists) {}
    public record Preview(List<PreviewRow> rows, int newCount) {}

    private record Validated(BusinessCode code, String type, String title,
                             ContentDraftUpdate command, boolean exists) {}

    public Preview preview(String filename, byte[] content) {
        var records = validate(filename, content);
        return new Preview(records.stream()
                .map(r -> new PreviewRow(r.code().value(), r.type(), r.title(), r.exists()))
                .toList(), (int) records.stream().filter(r -> !r.exists()).count());
    }

    @Transactional
    public int importDrafts(String filename, byte[] content) {
        var records = validate(filename, content);

        // Match XML import's PostgreSQL advisory lock namespace so that
        // concurrent JSON/XML uploads of the same identities serialize.
        var identities = records.stream()
                .map(row -> row.type() + ":" + row.code().value()).sorted().toList();
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

        // Recheck under locks after validation; preview is advisory only.
        records = validate(filename, content);
        var missing = new ArrayList<Validated>();
        for (var row : records) {
            if (row.exists()) {
                var id = revisions.findIdByExactIdentity(
                        row.code().value(), row.type(), 1).orElseThrow();
                var existing = revisions.findById(id).orElseThrow();
                if (existing.getLifecycle() != ContentLifecycleStatus.DRAFT
                        || !existing.getChecksum().equals(row.command().checksum())) {
                    throw new IllegalArgumentException("Conflicting or immutable revision: "
                            + row.code().value());
                }
            } else {
                if (revisions.findLatestId(row.code().value(), row.type()).isPresent()) {
                    throw new IllegalArgumentException("Later revision exists: "
                            + row.code().value());
                }
                missing.add(row);
            }

            if (row.command().body() instanceof ContentDraftUpdate.PracticeTestBody test) {
                var unique = new HashSet<UUID>();
                for (UUID questionId : test.questionRevisionIds()) {
                    if (!unique.add(questionId)) {
                        throw new IllegalArgumentException("Duplicate Question revision");
                    }
                    var question = revisions.findById(questionId).orElseThrow(() ->
                            new IllegalArgumentException("Unresolved Question revision"));
                    if (!(question instanceof QuestionContentRevisionEntity)
                            || (question.getLifecycle() != ContentLifecycleStatus.APPROVED
                                && question.getLifecycle() != ContentLifecycleStatus.PUBLISHED)) {
                        throw new IllegalArgumentException(
                                "Practice Test requires approved Question revision");
                    }
                }
            }
        }
        // All conflicts are identified before the first write. A later
        // persistence failure rolls the complete batch back.
        for (var row : missing) {
            authoring.createInitialRevision(row.code(), row.command());
        }
        return missing.size();
    }

    private List<Validated> validate(String filename, byte[] content) {
        if (content == null || content.length == 0 || content.length > MAX_BYTES) {
            throw new IllegalArgumentException("Import must contain 1..262144 bytes");
        }
        if (filename == null) throw new IllegalArgumentException("Import filename is missing");
        List<?> rows;
        if (filename.toLowerCase(java.util.Locale.ROOT).endsWith(".json")) {
            try {
                var root = json.readValue(content, Map.class);
                rows = rows(root.get("schemaVersion"), root.get("items"));
            } catch (Exception invalid) {
                throw new IllegalArgumentException("Invalid JSON import schema", invalid);
            }
        } else {
            throw new IllegalArgumentException("Only .json imports are supported; XML uses the versioned XSD importer");
        }

        var validated = new ArrayList<Validated>();
        var identities = new HashSet<String>();
        for (var raw : rows) {
            if (!(raw instanceof Map<?, ?> item)) {
                throw new IllegalArgumentException("Each import entry must be an object");
            }
            String code = require(item, "contentCode");
            String type = require(item, "bodyType");
            var identity = new BusinessCode(code);
            if (!identities.add(code + "|" + type)) {
                throw new IllegalArgumentException("Duplicate import identity: " + code);
            }
            var form = new ContentMvcForms.DraftForm();
            form.setExpectedVersion(0L);
            form.setTitle(require(item, "title"));
            form.setSubtitle(require(item, "subtitle"));
            form.setDescription(require(item, "description"));
            form.setCategoryCode(require(item, "categoryCode"));
            form.setLevelCode(require(item, "levelCode"));
            form.setMinutes(integer(item, "minutes"));
            form.setAvailability(require(item, "availability"));
            form.setBodyType(type);
            form.setSkillCodes(lines(item.get("skillCodes"), "skillCodes"));
            if (!(item.get("body") instanceof Map<?, ?> body)) {
                throw new IllegalArgumentException(code + ": typed content body is required");
            }
            typedBody(form, body);
            var command = mapper.toCommand(form);
            var exists = revisions.findIdByExactIdentity(code, type, 1).isPresent();
            validated.add(new Validated(identity, type, form.getTitle(), command, exists));
        }
        return List.copyOf(validated);
    }

    private static void typedBody(ContentMvcForms.DraftForm form, Map<?, ?> body) {
        switch (form.getBodyType()) {
            case "vocabulary" -> {
                form.setTerm(require(body, "term"));
                form.setDefinition(require(body, "definition"));
                form.setPartOfSpeech(require(body, "partOfSpeech"));
                form.setExamples(lines(body.get("examples"), "examples"));
            }
            case "interview" -> {
                form.setPrompt(require(body, "prompt"));
                form.setModelAnswer(require(body, "modelAnswer"));
                form.setKeyPoints(lines(body.get("keyPoints"), "keyPoints"));
            }
            case "topic" -> form.setSections(structured(body, "sections", List.of("heading", "text")));
            case "phrase" -> {
                form.setPhrase(require(body, "phrase"));
                form.setUsage(require(body, "usage"));
                form.setExamples(lines(body.get("examples"), "examples"));
            }
            case "shadowing" -> {
                form.setTranscript(require(body, "transcript"));
                form.setSegments(structured(body, "segments", List.of("startMs", "endMs", "text")));
            }
            case "question" -> {
                form.setQuestionText(require(body, "questionText"));
                form.setExplanation(require(body, "explanation"));
                form.setOptions(options(body.get("options")));
            }
            case "practice_test" -> {
                form.setInstructions(require(body, "instructions"));
                int score = integer(body, "passingScorePercent");
                if (score > 100) throw new IllegalArgumentException("Passing score must be 1..100");
                form.setPassingScorePercent(score);
                String ids = lines(body.get("questionRevisionIds"), "questionRevisionIds");
                var unique = new HashSet<java.util.UUID>();
                for (var id : ids.split("\n")) {
                    if (!unique.add(java.util.UUID.fromString(id))) {
                        throw new IllegalArgumentException("Duplicate question revision ID");
                    }
                }
                form.setQuestionRevisionIds(ids);
            }
            default -> throw new IllegalArgumentException("Unsupported content body type");
        }
    }

    private static List<?> rows(Object schema, Object items) {
        if (!(schema instanceof Number version) || version.intValue() != 1
                || !(items instanceof List<?> list) || list.isEmpty() || list.size() > MAX_ITEMS) {
            throw new IllegalArgumentException("Expected schemaVersion 1 and 1..100 items");
        }
        return list;
    }

    private static String require(Map<?, ?> data, String key) {
        Object value = data.get(key);
        if (!(value instanceof String text) || text.isBlank()) {
            throw new IllegalArgumentException("Missing required field: " + key);
        }
        return text.trim();
    }

    private static int integer(Map<?, ?> data, String key) {
        Object value = data.get(key);
        if (!(value instanceof Number n) || n.intValue() != n.doubleValue()
                || n.intValue() < 1 || n.intValue() > 10000) {
            throw new IllegalArgumentException("Invalid integer field: " + key);
        }
        return n.intValue();
    }

    private static String lines(Object raw, String field) {
        if (!(raw instanceof List<?> values) || values.isEmpty()) {
            throw new IllegalArgumentException("Expected nonempty array: " + field);
        }
        var result = new ArrayList<String>();
        for (var v : values) {
            if (!(v instanceof String s) || s.isBlank() || s.contains("\n") || s.contains("\r")) {
                throw new IllegalArgumentException("Invalid item in " + field);
            }
            result.add(s.trim());
        }
        return String.join("\n", result);
    }

    private static String structured(Map<?, ?> body, String field, List<String> keys) {
        if (!(body.get(field) instanceof List<?> rows) || rows.isEmpty()) {
            throw new IllegalArgumentException("Expected nonempty array: " + field);
        }
        var parts = new ArrayList<String>();
        for (var raw : rows) {
            if (!(raw instanceof Map<?, ?> row)) {
                throw new IllegalArgumentException("Invalid structured " + field);
            }
            var values = new ArrayList<String>();
            for (var key : keys) {
                Object value = row.get(key);
                String s = value == null ? "" : String.valueOf(value);
                if (("text".equals(key) || "heading".equals(key)) && s.isBlank()) {
                    throw new IllegalArgumentException(field + ": " + key + " required");
                }
                if (s.contains("|") || s.contains("\n") || s.contains("\r")) {
                    throw new IllegalArgumentException(field + ": unsafe field delimiter");
                }
                values.add(s);
            }
            parts.add(String.join("|", values));
        }
        return String.join("\n", parts);
    }

    private static String options(Object raw) {
        if (!(raw instanceof List<?> values) || values.size() < 2) {
            throw new IllegalArgumentException("Question options must contain at least two entries");
        }
        var rows = new ArrayList<String>();
        var keys = new HashSet<String>();
        boolean hasCorrect = false;
        for (var value : values) {
            if (!(value instanceof Map<?, ?> option)
                    || !(option.get("correct") instanceof Boolean correct)) {
                throw new IllegalArgumentException("Option needs a boolean correct flag");
            }
            var key = require(option, "key");
            var text = require(option, "text");
            if (!keys.add(key)) {
                throw new IllegalArgumentException("Duplicate question option key");
            }
            if (key.contains("|") || text.contains("|") || text.contains("\n")) {
                throw new IllegalArgumentException("Unsafe question option separator");
            }
            hasCorrect |= correct;
            rows.add(key + "|" + correct + "|" + text);
        }
        if (!hasCorrect) {
            throw new IllegalArgumentException("At least one question answer must be correct");
        }
        return String.join("\n", rows);
    }

}
