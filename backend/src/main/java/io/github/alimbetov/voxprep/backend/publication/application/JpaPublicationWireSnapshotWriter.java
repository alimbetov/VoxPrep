package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalRepository;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.application.AssessmentDeliveryConfigurationService;
import io.github.alimbetov.voxprep.backend.content.persistence.PracticeTestContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.learner.application.FlutterPublicationCanonicalHash;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentKind;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationWireDocumentRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

/**
 * API-R2 publication writer. Creates a frozen Flutter v2 root, canonical packs
 * and six universal catalogues. Does not fall back to mutable rows on reads.
 *
 * All source rows are resolved before CURRENT advances, in the publish
 * transaction. Missing catalogue membership, dangling references or non-READY
 * assets fail the whole transaction; there is no partial release.
 */
@Component
public class JpaPublicationWireSnapshotWriter implements PublicationWireSnapshotWriter {

    private static final List<String> CATALOGUE_KINDS = List.of(
            "vertical-sections", "verticals", "vertical-presentation",
            "learning-goals", "learning-tracks", "learning-collections");

    private final VerticalRepository verticals;
    private final LearningGoalRepository goals;
    private final LearningTrackRepository tracks;
    private final LearningCollectionRepository collections;
    private final CollectionContentMemberRepository members;
    private final ContentRevisionRepository revisions;
    private final AssessmentDeliveryConfigurationService assessmentConfig;
    private final FileAssetRepository fileAssets;
    private final ContentAssetBindingRepository bindings;
    private final ContentLocalizationRevisionRepository localizations;
    private final PublicationWireDocumentRepository documents;
    private final ObjectMapper json;

    public JpaPublicationWireSnapshotWriter(
            VerticalRepository verticals,
            LearningGoalRepository goals,
            LearningTrackRepository tracks,
            LearningCollectionRepository collections,
            CollectionContentMemberRepository members,
            ContentRevisionRepository revisions,
            AssessmentDeliveryConfigurationService assessmentConfig,
            FileAssetRepository fileAssets,
            ContentAssetBindingRepository bindings,
            ContentLocalizationRevisionRepository localizations,
            PublicationWireDocumentRepository documents,
            ObjectMapper json) {
        this.verticals = Objects.requireNonNull(verticals);
        this.goals = Objects.requireNonNull(goals);
        this.tracks = Objects.requireNonNull(tracks);
        this.collections = Objects.requireNonNull(collections);
        this.members = Objects.requireNonNull(members);
        this.revisions = Objects.requireNonNull(revisions);
        this.assessmentConfig = Objects.requireNonNull(assessmentConfig);
        this.fileAssets = Objects.requireNonNull(fileAssets);
        this.bindings = Objects.requireNonNull(bindings);
        this.localizations = Objects.requireNonNull(localizations);
        this.documents = Objects.requireNonNull(documents);
        this.json = Objects.requireNonNull(json);
    }

    @Override
    @Transactional(propagation = Propagation.MANDATORY)
    public void freeze(PublicationReleaseEntity release, List<PublicationExactContentRef> refs, Instant publishedAt) {
        Objects.requireNonNull(release, "release");
        Objects.requireNonNull(refs, "refs");
        Objects.requireNonNull(publishedAt, "publishedAt");
        if (refs.isEmpty() || documents.existsByRelease_Id(release.getId())) {
            throw new IllegalStateException("publication must have content and no existing frozen wire documents");
        }

        Map<String, PublicationExactContentRef> published = new LinkedHashMap<>();
        for (var ref : refs) {
            if (published.putIfAbsent(key(ref), ref) != null) {
                throw new IllegalStateException("duplicate exact publication identity");
            }
        }

        List<Snapshot> assessmentSnapshots = validateAssessmentOwnership(refs, published);

        var sectionItems = new ArrayList<Map<String, Object>>();
        var verticalItems = new ArrayList<Map<String, Object>>();
        var goalItems = new ArrayList<Map<String, Object>>();
        var trackItems = new ArrayList<Map<String, Object>>();
        var collectionItems = new ArrayList<Map<String, Object>>();
        var packRefs = new ArrayList<Map<String, Object>>();
        var sourcePacks = new ArrayList<Snapshot>();

        Set<String> sectionCodes = new LinkedHashSet<>();
        Set<String> covered = new HashSet<>();
        var allVerticals = verticals.findAllByOrderBySortOrderAscCodeAsc();
        for (var vertical : allVerticals) {
            if (!active(vertical.getAvailability())) {
                continue;
            }
            var verticalCode = vertical.getCode().value();
            // Flutter schema-v2 requires all catalogue icon asset IDs to resolve
            // to an exact image asset listed in the frozen pack manifest.
            var icon = requireReadyIcon(vertical.getIconAssetId(), verticalCode);
            var iconDescriptor = assetDescriptor(icon);
            var sectionCode = vertical.getSectionCode().value();
            if (sectionCodes.add(sectionCode)) {
                // Section metadata does not yet exist in the authoring schema.
                // Use the stable backend code as an explicit display fallback.
                sectionItems.add(object(
                        "code", sectionCode, "title", sectionCode,
                        "description", null, "iconAssetId", null,
                        "sortOrder", sectionItems.size(), "active", active(vertical.getAvailability())));
            }
            verticalItems.add(object("code", verticalCode, "sectionCode", sectionCode,
                    "title", vertical.getTitle(), "description", vertical.getDescription(),
                    "iconAssetId", vertical.getIconAssetId(),
                    "sortOrder", vertical.getSortOrder(), "active", active(vertical.getAvailability())));
            for (var goal : goals.findAllByVertical_IdOrderBySortOrderAscCodeAsc(vertical.getId())) {
                if (!active(goal.getAvailability())) {
                    continue;
                }
                var goalCode = goal.getCode().value();
                goalItems.add(object("code", goalCode, "verticalCode", verticalCode,
                        "title", goal.getTitle(), "description", goal.getDescription(),
                        "sortOrder", goal.getSortOrder(), "active", active(goal.getAvailability())));
                for (var track : tracks.findAllByGoal_IdOrderBySortOrderAscCodeAsc(goal.getId())) {
                    if (!active(track.getAvailability())) {
                        continue;
                    }
                    var trackCode = track.getCode().value();
                    trackItems.add(object("code", trackCode, "verticalCode", verticalCode,
                            "goalCode", goalCode, "title", track.getTitle(),
                            "description", track.getDescription(),
                            "levelCode", track.getLevelCode().value(),
                            "careerTrackCode", track.getCareerTrackCode() == null
                                    ? null : track.getCareerTrackCode().value(),
                            "sortOrder", track.getSortOrder(), "active", active(track.getAvailability())));
                    for (var collection : collections.findAllByTrack_IdOrderBySortOrderAscCodeAsc(track.getId())) {
                        if (!active(collection.getAvailability())) {
                            continue;
                        }
                        var collectionCode = collection.getCode().value();
                        var memberItems = new ArrayList<Map<String, Object>>();
                        var packContents = new ArrayList<Map<String, Object>>();
                        var assetDescriptors = new LinkedHashMap<String, Map<String, Object>>();
                        assetDescriptors.put(icon.getId().toString(), iconDescriptor);
                        var contentAssets = new ArrayList<Map<String, Object>>();
                        var translatedByLocale = new LinkedHashMap<String, List<Map<String, Object>>>();
                        List<CollectionContentMemberEntity> sortedMembers =
                                members.findAllByCollectionIdOrderByPositionAsc(collection.getId());
                        boolean fullBranch = true; // inactive branches are excluded before projection.
                        if (fullBranch && sortedMembers.isEmpty()) {
                            throw new IllegalStateException("active collection has no published members: " + collectionCode);
                        }
                        for (int pos = 0; pos < sortedMembers.size(); pos++) {
                            var member = sortedMembers.get(pos);
                            if (member.getPosition() != pos) {
                                throw new IllegalStateException("collection membership positions must be contiguous");
                            }
                            var revision = member.getContentRevision();
                            var ref = published.get(key(revision.getIdentity()));
                            if (ref == null || !ref.checksum().equals(revision.getChecksum())) {
                                throw new IllegalStateException("collection member is not in exact publication: " + collectionCode);
                            }
                            if (revision.getContentType() == ContentType.QUESTION) {
                                throw new IllegalStateException("question must be referenced through a practice test");
                            }
                            if (fullBranch) {
                                covered.add(key(ref));
                            }
                            if (revision.getContentType() == ContentType.PRACTICE_TEST) {
                                memberItems.add(object("position", pos, "type", "PRACTICE_TEST",
                                        "practiceTest", object("practiceTestCode", ref.identity().contentCode().value(),
                                                "revision", ref.identity().revisionNumber().value(),
                                                "checksum", ref.checksum().value())));
                                continue;
                            }
                            memberItems.add(object("position", pos, "type", "CONTENT",
                                    "content", object(
                                            "contentCode", ref.identity().contentCode().value(),
                                            "contentType", ref.identity().contentType().wireName(),
                                            "revision", ref.identity().revisionNumber().value(),
                                            "checksum", ref.checksum().value())));
                            if (!fullBranch) {
                                continue;
                            }
                            packContents.add(object(
                                    "contentCode", ref.identity().contentCode().value(),
                                    "contentType", ref.identity().contentType().wireName(),
                                    "revision", ref.identity().revisionNumber().value(),
                                    "checksum", ref.checksum().value(),
                                    "sortOrder", pos, "publishedAt", utc(publishedAt)));
                            for (var localized : localizations
                                    .findAllByContentRevisionIdOrderByLocaleAscLocalizationRevisionNumberDesc(revision.getId())) {
                                if (localized.getLifecycle() != ContentLocalizationLifecycleStatus.APPROVED
                                        || localized.getApprovedAt() == null
                                        || localized.getApprovedAt().isAfter(publishedAt)) {
                                    continue;
                                }
                                var list = translatedByLocale.computeIfAbsent(localized.getLocale(), ignored -> new ArrayList<>());
                                if (list.stream().anyMatch(item ->
                                        revision.getContentCode().value().equals(item.get("contentCode"))
                                                && ref.identity().contentType().wireName().equals(item.get("contentType")))) {
                                    continue; // latest APPROVED as-of the publication timestamp
                                }
                                list.add(object("contentCode", ref.identity().contentCode().value(),
                                        "contentType", ref.identity().contentType().wireName(),
                                        "contentRevision", ref.identity().revisionNumber().value(),
                                        "locale", localized.getLocale(),
                                        "localizationRevision", localized.getLocalizationRevisionNumber(),
                                        "checksum", localized.getChecksumSha256()));
                            }
                            for (var binding : bindings.findAllByContentRevision_IdOrderByRoleAsc(revision.getId())) {
                                var asset = binding.getFileAsset();
                                if (asset.getStatus() != FileAssetStatus.READY
                                        || asset.getKind() != binding.getRole().assetKind()) {
                                    throw new IllegalStateException("publication contains non-READY or wrong-kind asset");
                                }
                                var assetId = asset.getId().toString();
                                assetDescriptors.putIfAbsent(assetId, object(
                                        "assetId", assetId, "checksumSha256", asset.getSha256(),
                                        "deliveryKey", asset.getObjectKey(), "sizeBytes", asset.getSizeBytes(),
                                        "mediaType", asset.getMediaType(), "requiredOffline", false));
                                contentAssets.add(object(
                                        "contentCode", ref.identity().contentCode().value(),
                                        "contentType", ref.identity().contentType().wireName(),
                                        "contentRevision", ref.identity().revisionNumber().value(),
                                        "assetId", assetId, "role", binding.getRole().wireName()));
                            }
                        }
                        collectionItems.add(object("code", collectionCode,
                                "verticalCode", verticalCode, "trackCode", trackCode,
                                "title", collection.getTitle(), "description", collection.getDescription(),
                                "accessLevel", collection.getAccessLevel().name(),
                                "sortOrder", collection.getSortOrder(), "active", fullBranch,
                                "members", memberItems));
                        if (!fullBranch) {
                            continue;
                        }
                        var pack = packBody(collectionCode, release.getContentVersion(), "canonical",
                                packContents, List.of(), new ArrayList<>(assetDescriptors.values()), contentAssets);
                        sourcePacks.add(new Snapshot(PublicationWireDocumentKind.PACK, collectionCode, "canonical",
                                pack, FlutterPublicationCanonicalHash.pack(json, pack)));
                        for (var localeEntry : translatedByLocale.entrySet()) {
                            var locale = localeEntry.getKey();
                            var variant = "locale:" + locale;
                            var translatedPack = packBody(collectionCode, release.getContentVersion(),
                                    variant, packContents, localeEntry.getValue(),
                                    new ArrayList<>(assetDescriptors.values()), contentAssets);
                            sourcePacks.add(new Snapshot(PublicationWireDocumentKind.PACK, collectionCode,
                                    variant, translatedPack, FlutterPublicationCanonicalHash.pack(json, translatedPack)));
                        }
                    }
                }
            }
        }
        if (sourcePacks.isEmpty()) {
            throw new IllegalStateException("no active published collection produces a Flutter pack");
        }
        // Every published non-question revision must belong to an active collection.
        for (var ref : refs) {
            if (ref.identity().contentType() != ContentType.QUESTION && !covered.contains(key(ref))) {
                throw new IllegalStateException("published content lacks active collection: " + ref.identityKey());
            }
        }

        var catalogues = new LinkedHashMap<String, List<Map<String, Object>>>();
        catalogues.put("vertical-sections", sectionItems);
        catalogues.put("verticals", verticalItems);
        catalogues.put("vertical-presentation", List.of(object(
                "mode", "GRID", "showFeatured", false,
                "showSeeAll", true, "featuredSectionCode", null)));
        catalogues.put("learning-goals", goalItems);
        catalogues.put("learning-tracks", trackItems);
        catalogues.put("learning-collections", collectionItems);

        var catalogueRefs = new ArrayList<Map<String, Object>>();
        var staged = new ArrayList<Snapshot>(sourcePacks);
        staged.addAll(assessmentSnapshots);
        for (String kind : CATALOGUE_KINDS) {
            var body = object("kind", kind, "revision", release.getContentVersion(),
                    "items", catalogues.get(kind));
            var digest = sha256(body);
            staged.add(new Snapshot(PublicationWireDocumentKind.CATALOGUE, kind, "-", body, digest));
            catalogueRefs.add(object("kind", kind, "revision", release.getContentVersion(), "checksum", digest));
        }

        for (var pack : sourcePacks) {
            packRefs.add(object("code", pack.code(), "variant", pack.variant(),
                    "revision", release.getContentVersion(), "checksum", pack.checksum()));
        }
        var practiceRefs = refs.stream()
                .filter(ref -> ref.identity().contentType() == ContentType.PRACTICE_TEST)
                .map(ref -> object("practiceTestCode", ref.identity().contentCode().value(),
                        "revision", ref.identity().revisionNumber().value(),
                        "checksum", ref.checksum().value()))
                .toList();
        var root = object(
                "schemaVersion", 2,
                "contentVersion", release.getContentVersion(),
                "minimumAppContractVersion", 2,
                "publishedAt", utc(publishedAt),
                "packs", packRefs, "practiceTests", practiceRefs,
                "catalogues", catalogueRefs,
                "localeFallbacks", List.of(), "tombstones", List.of());
        staged.add(new Snapshot(PublicationWireDocumentKind.ROOT, "root", "-",
                root, FlutterPublicationCanonicalHash.root(json, root)));

        for (var doc : staged) {
            var payload = new LinkedHashMap<>(doc.body());
            // Assessment payload.checksum denotes the exact content revision;
            // the immutable document checksum is stored separately in the DB.
            if (doc.kind() != PublicationWireDocumentKind.ASSESSMENT) {
                payload.put("checksum", doc.checksum());
            }
            documents.save(new PublicationWireDocumentEntity(
                    release, doc.kind(), doc.code(), doc.variant(), release.getContentVersion(),
                    doc.checksum(), encode(payload)));
        }
        documents.flush();
    }

    /**
     * Prevents publishing unowned questions, dangling assessment references,
     * or question choices incompatible with the Flutter singleChoice contract.
     */
    private List<Snapshot> validateAssessmentOwnership(
            List<PublicationExactContentRef> refs,
            Map<String, PublicationExactContentRef> published) {
        Set<String> questionOwners = new HashSet<>();
        var snapshots = new ArrayList<Snapshot>();
        for (var ref : refs) {
            if (ref.identity().contentType() != ContentType.PRACTICE_TEST) {
                continue;
            }
            var rawTest = revisions.findExact(ref.identity())
                    .orElseThrow(() -> new IllegalStateException("published practice test is missing"));
            if (!(rawTest instanceof PracticeTestContentRevisionEntity test)
                    || !rawTest.getIdentity().equals(ref.identity())
                    || !rawTest.getChecksum().equals(ref.checksum())) {
                throw new IllegalStateException("published practice test is inconsistent");
            }
            var questionIds = test.getQuestionRevisionIds();
            var delivery = assessmentConfig.requireReady(test.getId(), questionIds.size());
            var questionRefs = new ArrayList<Map<String, Object>>();
            for (int position = 0; position < questionIds.size(); position++) {
                UUID id = questionIds.get(position);
                var rawQuestion = revisions.findById(id)
                        .orElseThrow(() -> new IllegalStateException("published question reference is dangling"));
                if (!(rawQuestion instanceof QuestionContentRevisionEntity question)) {
                    throw new IllegalStateException("practice test references non-question revision");
                }
                var exact = published.get(key(question.getIdentity()));
                if (exact == null || !question.getChecksum().equals(exact.checksum())) {
                    throw new IllegalStateException("practice test references unpublished question");
                }
                if (question.getSkillCodes().size() != 1
                        || question.getOptions().size() < 2
                        || question.getOptions().stream()
                                .filter(io.github.alimbetov.voxprep.backend.content.persistence.QuestionOptionEmbeddable::isCorrect)
                                .count() != 1) {
                    throw new IllegalStateException("question does not satisfy Flutter singleChoice contract");
                }
                questionOwners.add(key(exact));
                questionRefs.add(object("order", position,
                        "question", object(
                                "questionCode", exact.identity().contentCode().value(),
                                "revision", exact.identity().revisionNumber().value(),
                                "checksum", exact.checksum().value()),
                        "points", delivery.points().get(position)));
            }
            var body = object("practiceTestCode", ref.identity().contentCode().value(),
                    "revision", ref.identity().revisionNumber().value(),
                    "checksum", ref.checksum().value(),
                    "title", test.getTitle(), "subtitle", test.getSubtitle(),
                    "mode", delivery.mode(),
                    "passingScoreBasisPoints", test.getPassingScorePercent() * 100,
                    "questionRefs", questionRefs);
            snapshots.add(new Snapshot(PublicationWireDocumentKind.ASSESSMENT,
                    ref.identity().contentCode().value(), "-", body, sha256(body)));
        }
        for (var ref : refs) {
            if (ref.identity().contentType() == ContentType.QUESTION
                    && !questionOwners.contains(key(ref))) {
                throw new IllegalStateException("published question has no published practice-test owner");
            }
        }
        return List.copyOf(snapshots);
    }

    private FileAssetEntity requireReadyIcon(String assetId, String verticalCode) {
        final UUID id;
        try {
            id = UUID.fromString(assetId);
            if (!id.toString().equals(assetId)) {
                throw new IllegalArgumentException("noncanonical UUID");
            }
        } catch (RuntimeException exception) {
            throw new IllegalStateException(
                    "vertical icon must be a canonical persisted UUID: " + verticalCode, exception);
        }
        var asset = fileAssets.findById(id)
                .orElseThrow(() -> new IllegalStateException(
                        "vertical icon asset does not exist: " + verticalCode));
        if (asset.getStatus() != FileAssetStatus.READY
                || (asset.getKind() != FileAssetKind.COVER_IMAGE
                    && asset.getKind() != FileAssetKind.CONTENT_IMAGE)
                || !asset.getMediaType().startsWith("image/")
                || asset.getSizeBytes() <= 0
                || !asset.getSha256().matches("[0-9a-f]{64}")) {
            throw new IllegalStateException("vertical icon must be a READY image: " + verticalCode);
        }
        return asset;
    }

    private static Map<String, Object> assetDescriptor(FileAssetEntity asset) {
        return object(
                "assetId", asset.getId().toString(), "checksumSha256", asset.getSha256(),
                "deliveryKey", asset.getObjectKey(), "sizeBytes", asset.getSizeBytes(),
                "mediaType", asset.getMediaType(), "requiredOffline", false);
    }

    private static LinkedHashMap<String, Object> packBody(
            String code, long revision, String variant,
            List<Map<String, Object>> contents, List<Map<String, Object>> locales,
            List<Map<String, Object>> assets, List<Map<String, Object>> assetRefs) {
        return object("schemaVersion", 2, "code", code, "variant", variant,
                "revision", revision, "contents", contents,
                "localizations", locales, "assets", assets, "contentAssets", assetRefs);
    }

    private String sha256(Map<String, Object> body) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(encode(body).getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }

    private String encode(Map<String, Object> body) {
        try {
            return json.writeValueAsString(body);
        } catch (Exception exception) {
            throw new IllegalStateException("Cannot serialize publication wire document", exception);
        }
    }

    private static String utc(Instant value) {
        return value.toString();
    }

    private static boolean active(AvailabilityStatus value) {
        return value == AvailabilityStatus.ACTIVE;
    }

    private static String key(PublicationExactContentRef ref) {
        return key(ref.identity());
    }

    private static String key(io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity id) {
        return id.contentType().wireName() + "|" + id.contentCode().value()
                + "|" + id.revisionNumber().value();
    }

    private static LinkedHashMap<String, Object> object(Object... parts) {
        if (parts.length % 2 != 0) {
            throw new IllegalArgumentException("invalid key-value pairs");
        }
        var result = new LinkedHashMap<String, Object>();
        for (int i = 0; i < parts.length; i += 2) {
            result.put((String) parts[i], parts[i + 1]);
        }
        return result;
    }

    private record Snapshot(
            PublicationWireDocumentKind kind, String code, String variant,
            Map<String, Object> body, String checksum) {
    }
}
