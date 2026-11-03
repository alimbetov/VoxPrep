package io.github.alimbetov.voxprep.backend.publication.persistence;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PublicationWireDocumentRepository extends JpaRepository<PublicationWireDocumentEntity, UUID> {

    Optional<PublicationWireDocumentEntity> findByRelease_IdAndKindAndResourceCodeAndVariantAndRevision(
            UUID releaseId,
            PublicationWireDocumentKind kind,
            String resourceCode,
            String variant,
            long revision);
}
