package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import java.util.Objects;
import java.util.Optional;
import org.springframework.stereotype.Component;

@Component
public class JpaPublicationExactContentResolver implements PublicationExactContentResolver {

    private final ContentRevisionRepository repository;

    public JpaPublicationExactContentResolver(ContentRevisionRepository repository) {
        this.repository = Objects.requireNonNull(repository, "repository");
    }

    @Override
    public Optional<ResolvedContentRevision> resolveExact(ContentRevisionIdentity identity) {
        Objects.requireNonNull(identity, "identity");
        return repository.findExact(identity)
                .map(entity -> new ResolvedContentRevision(
                        entity.getIdentity(), entity.getChecksum(), entity.getLifecycle()));
    }
}
