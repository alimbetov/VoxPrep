package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberRepository;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationPrincipal;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import java.util.List;
import java.util.Objects;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Product access check for exact CURRENT content revisions. Does not confuse
 * publication validity or installation authentication with a paid entitlement.
 *
 * <p>Until the B8 verification adapter is provided, FULL collections remain closed.
 */
@Service
public class LearnerContentAccessPolicy {

    private final CurrentPublicationResolver currentPublicationResolver;
    private final ContentRevisionRepository revisionRepository;
    private final CollectionContentMemberRepository memberRepository;
    private final VerifiedLifetimeEntitlementPort entitlements;

    public LearnerContentAccessPolicy(
            CurrentPublicationResolver currentPublicationResolver,
            ContentRevisionRepository revisionRepository,
            CollectionContentMemberRepository memberRepository,
            VerifiedLifetimeEntitlementPort entitlements) {
        this.currentPublicationResolver = Objects.requireNonNull(currentPublicationResolver);
        this.revisionRepository = Objects.requireNonNull(revisionRepository);
        this.memberRepository = Objects.requireNonNull(memberRepository);
        this.entitlements = Objects.requireNonNull(entitlements);
    }

    @Transactional(readOnly = true)
    public void requireAccessible(String contentTypeWireName, String contentCode) {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || !(authentication.getPrincipal() instanceof InstallationPrincipal principal)) {
            throw new AccessDeniedException("Installation authentication is required");
        }

        ContentType type = ContentType.fromWireName(contentTypeWireName);
        PublicationExactContentRef exact = currentPublicationResolver.resolve().refs().stream()
                .filter(ref -> ref.identity().contentType() == type)
                .filter(ref -> ref.identity().contentCode().value().equals(contentCode))
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException(contentTypeWireName, contentCode));

        var revision = revisionRepository.findExact(exact.identity())
                .orElseThrow(() -> new IllegalStateException("CURRENT content revision is missing"));
        if (!revision.getIdentity().equals(exact.identity()) || !revision.getChecksum().equals(exact.checksum())) {
            throw new IllegalStateException("CURRENT content revision differs from publication manifest");
        }

        List<CollectionContentMemberEntity> members =
                memberRepository.findAllByContentRevision_Id(revision.getId());
        if (members.isEmpty()) {
            // Publication alone is not proof of FREE access.
            throw new LearnerContentNotFoundException(contentTypeWireName, contentCode);
        }

        boolean requiresFull = false;
        for (CollectionContentMemberEntity member : members) {
            var collection = member.getCollection();
            var track = collection.getTrack();
            var goal = track.getGoal();
            var vertical = goal.getVertical();

            // No stale/inactive authoring branch should establish access.
            if (collection.getAvailability() != AvailabilityStatus.ACTIVE
                    || track.getAvailability() != AvailabilityStatus.ACTIVE
                    || goal.getAvailability() != AvailabilityStatus.ACTIVE
                    || vertical.getAvailability() != AvailabilityStatus.ACTIVE) {
                throw new AccessDeniedException("Published content catalogue branch is not active");
            }
            if (collection.getAccessLevel() == CollectionAccessLevel.FULL) {
                requiresFull = true;
            } else if (collection.getAccessLevel() != CollectionAccessLevel.FREE) {
                throw new AccessDeniedException("Unrecognized collection access level");
            }
        }

        // Most restrictive membership wins to avoid a FREE alias bypass for FULL content.
        if (requiresFull && !entitlements.hasVerifiedLifetimeUnlock(principal.installationId())) {
            throw new LearnerPremiumAccessDeniedException();
        }
    }
}
