package io.github.alimbetov.voxprep.backend.publication.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class PublicationCandidateValidatorTest {

    private static final String A = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final String B = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";

    @Test
    void producesSameCanonicalRefsAndRootForAnyInputOrder() {
        PublicationExactContentRef first = ref("alpha", ContentType.VOCABULARY, 2, A);
        PublicationExactContentRef second = ref("beta", ContentType.TOPIC, 4, B);
        PublicationCandidateValidator validator = validator(Map.of(
                first.identity(), resolved(first, ContentLifecycleStatus.APPROVED),
                second.identity(), resolved(second, ContentLifecycleStatus.PUBLISHED)));

        PublicationValidationResult left = validator.validate(List.of(first, second));
        PublicationValidationResult right = validator.validate(List.of(second, first));

        assertTrue(left.valid());
        assertEquals(left.canonicalRefs(), right.canonicalRefs());
        assertEquals(left.rootSha256(), right.rootSha256());
        assertEquals(64, left.rootSha256().length());
    }

    @Test
    void failsClosedForMissingChecksumMismatchAndNonPublishableRevisionInStableOrder() {
        PublicationExactContentRef missing = ref("missing", ContentType.TOPIC, 1, A);
        PublicationExactContentRef mismatch = ref("mismatch", ContentType.PHRASE, 3, A);
        PublicationExactContentRef draft = ref("draft", ContentType.INTERVIEW, 7, B);
        PublicationCandidateValidator validator = validator(Map.of(
                mismatch.identity(), new PublicationExactContentResolver.ResolvedContentRevision(
                        mismatch.identity(), new Sha256Digest(B), ContentLifecycleStatus.APPROVED),
                draft.identity(), resolved(draft, ContentLifecycleStatus.DRAFT)));

        PublicationValidationResult result = validator.validate(List.of(draft, missing, mismatch));

        assertFalse(result.valid());
        assertNull(result.rootSha256());
        assertEquals(List.of(
                PublicationValidationCode.CHECKSUM_MISMATCH,
                PublicationValidationCode.MISSING_REVISION,
                PublicationValidationCode.NOT_PUBLISHABLE),
                result.issues().stream().map(PublicationValidationIssue::code).toList());
    }

    @Test
    void rejectsDuplicateExactIdentityEvenWhenChecksumsDiffer() {
        PublicationExactContentRef first = ref("same", ContentType.QUESTION, 5, A);
        PublicationExactContentRef second = ref("same", ContentType.QUESTION, 5, B);

        PublicationValidationResult result = validator(Map.of()).validate(List.of(second, first));

        assertFalse(result.valid());
        assertNull(result.rootSha256());
        assertEquals(1, result.issues().size());
        assertEquals(PublicationValidationCode.DUPLICATE_REF, result.issues().get(0).code());
    }

    @Test
    void rejectsEmptyCandidate() {
        PublicationValidationResult result = validator(Map.of()).validate(List.of());
        assertEquals(List.of(PublicationValidationCode.EMPTY_CANDIDATE),
                result.issues().stream().map(PublicationValidationIssue::code).toList());
    }

    private static PublicationCandidateValidator validator(
            Map<ContentRevisionIdentity, PublicationExactContentResolver.ResolvedContentRevision> values) {
        return new PublicationCandidateValidator(identity -> Optional.ofNullable(values.get(identity)));
    }

    private static PublicationExactContentResolver.ResolvedContentRevision resolved(
            PublicationExactContentRef ref, ContentLifecycleStatus lifecycle) {
        return new PublicationExactContentResolver.ResolvedContentRevision(ref.identity(), ref.checksum(), lifecycle);
    }

    private static PublicationExactContentRef ref(
            String code, ContentType type, int revision, String checksum) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(new BusinessCode(code), type, new RevisionNumber(revision)),
                new Sha256Digest(checksum));
    }
}
