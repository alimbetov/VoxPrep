package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationPrincipal;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.Objects;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Server authorization for exact CURRENT content. Installation authentication
 * alone never grants access to FULL; authoring catalogue edits never affect
 * permissions in an already published release.
 */
@Service
public class LearnerContentAccessPolicy {

    private final CurrentPublicationResolver currentPublicationResolver;
    private final ContentRevisionRepository revisionRepository;
    private final LearnerFrozenAccessResolver frozenAccess;
    private final VerifiedLifetimeEntitlementPort entitlements;

    public LearnerContentAccessPolicy(
            CurrentPublicationResolver currentPublicationResolver,
            ContentRevisionRepository revisionRepository,
            LearnerFrozenAccessResolver frozenAccess,
            VerifiedLifetimeEntitlementPort entitlements) {
        this.currentPublicationResolver = Objects.requireNonNull(currentPublicationResolver);
        this.revisionRepository = Objects.requireNonNull(revisionRepository);
        this.frozenAccess = Objects.requireNonNull(frozenAccess);
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
        if (type == ContentType.QUESTION) {
            throw new AccessDeniedException("Assessment questions require parent test authorization");
        }
        var publication = currentPublicationResolver.resolve();
        PublicationExactContentRef exact = publication.refs().stream()
                .filter(ref -> ref.identity().contentType() == type)
                .filter(ref -> ref.identity().contentCode().value().equals(contentCode))
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException(contentTypeWireName, contentCode));

        var revision = revisionRepository.findExact(exact.identity())
                .orElseThrow(() -> new IllegalStateException("CURRENT content revision is missing"));
        if (!revision.getIdentity().equals(exact.identity()) || !revision.getChecksum().equals(exact.checksum())) {
            throw new IllegalStateException("CURRENT content revision differs from publication manifest");
        }

        boolean full = frozenAccess.requiresFull(exact, publication.contentVersion());
        if (full && !entitlements.hasVerifiedLifetimeUnlock(principal.installationId())) {
            throw new LearnerPremiumAccessDeniedException();
        }
    }
}
