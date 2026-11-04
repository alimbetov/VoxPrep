package io.github.alimbetov.voxprep.backend.learner.application;

import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LearnerCatalogueService {

    private final CurrentPublicationResolver currentPublicationResolver;

    public LearnerCatalogueService(CurrentPublicationResolver currentPublicationResolver) {
        this.currentPublicationResolver = Objects.requireNonNull(currentPublicationResolver, "currentPublicationResolver");
    }

    @Transactional(readOnly = true)
    public LearnerCatalogueSnapshot getCurrentCatalogue() {
        CurrentPublicationSnapshot publication = currentPublicationResolver.resolve();
        var entries = publication.refs().stream()
                .map(LearnerCatalogueEntry::from)
                .toList();

        return new LearnerCatalogueSnapshot(
                publication.contentVersion(),
                publication.rootSha256(),
                publication.publishedAt(),
                entries);
    }
}
