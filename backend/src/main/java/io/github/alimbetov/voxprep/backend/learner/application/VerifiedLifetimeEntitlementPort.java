package io.github.alimbetov.voxprep.backend.learner.application;

import java.util.UUID;

/**
 * Only the server-side store-verified entitlement domain may implement a positive grant.
 * A Flutter local purchase flag is never a trusted authority.
 */
public interface VerifiedLifetimeEntitlementPort {

    boolean hasVerifiedLifetimeUnlock(UUID installationId);
}
