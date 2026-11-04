package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reads FREE/FULL from the IMMUTABLE published universal catalogue, never from
 * mutable authoring memberships. Every exact content ref must be listed in
 * the same release. The most restrictive collection access wins.
 */
@Service
public class LearnerFrozenAccessResolver {

    private final LearnerWirePublicationService publication;

    public LearnerFrozenAccessResolver(LearnerWirePublicationService publication) {
        this.publication = Objects.requireNonNull(publication);
    }

    @Transactional(readOnly = true)
    public boolean requiresFull(PublicationExactContentRef ref, long contentVersion) {
        Objects.requireNonNull(ref, "ref");
        if (ref.identity().contentType() == ContentType.QUESTION) {
            // Questions are authorized through their parent practice-test read.
            throw new IllegalArgumentException("questions require a parent assessment");
        }
        var catalogue = publication.catalogue(
                "learning-collections", Math.toIntExact(contentVersion)).body();
        if (!(catalogue.get("items") instanceof List<?> items)) {
            throw new LearnerWireSnapshotUnavailableException("immutable collections payload missing");
        }

        boolean found = false;
        boolean requiresFull = false;
        for (Object item : items) {
            if (!(item instanceof Map<?, ?> collection)) {
                throw new LearnerWireSnapshotUnavailableException("invalid frozen collection");
            }
            if (!Boolean.TRUE.equals(collection.get("active"))) {
                continue;
            }
            String accessLevel = readAccessLevel(collection);
            if (!(collection.get("members") instanceof List<?> members)) {
                throw new LearnerWireSnapshotUnavailableException("frozen collection membership missing");
            }
            for (Object memberValue : members) {
                if (!(memberValue instanceof Map<?, ?> member)) {
                    throw new LearnerWireSnapshotUnavailableException("invalid frozen collection member");
                }
                if (matches(ref, member)) {
                    found = true;
                    requiresFull |= "FULL".equals(accessLevel);
                }
            }
        }
        if (!found) {
            throw new LearnerContentNotFoundException(
                    ref.identity().contentType().wireName(), ref.identity().contentCode().value());
        }
        return requiresFull;
    }

    private static String readAccessLevel(Map<?, ?> collection) {
        Object value = collection.get("accessLevel");
        if (!"FREE".equals(value) && !"FULL".equals(value)) {
            throw new LearnerWireSnapshotUnavailableException("invalid published FREE/FULL level");
        }
        return (String) value;
    }

    private static boolean matches(PublicationExactContentRef ref, Map<?, ?> member) {
        boolean isTest = ref.identity().contentType() == ContentType.PRACTICE_TEST;
        String expectedType = isTest ? "PRACTICE_TEST" : "CONTENT";
        if (!expectedType.equals(member.get("type"))) {
            return false;
        }
        Object nested = member.get(isTest ? "practiceTest" : "content");
        if (!(nested instanceof Map<?, ?> exact)) {
            throw new LearnerWireSnapshotUnavailableException("invalid frozen member identity");
        }
        String codeField = isTest ? "practiceTestCode" : "contentCode";
        return ref.identity().contentCode().value().equals(exact.get(codeField))
                && (isTest || ref.identity().contentType().wireName().equals(exact.get("contentType")))
                && exact.get("revision") instanceof Number number
                && number.intValue() == ref.identity().revisionNumber().value()
                && ref.checksum().value().equals(exact.get("checksum"));
    }
}
