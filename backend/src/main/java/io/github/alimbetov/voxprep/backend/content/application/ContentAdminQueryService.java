package io.github.alimbetov.voxprep.backend.content.application;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ContentAdminQueryService {

    private static final int MAX_PAGE_SIZE = 100;

    private final ContentRevisionRepository repository;

    public ContentAdminQueryService(ContentRevisionRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public Page<ContentRevisionSnapshot> list(int page, int size) {
        if (page < 0) {
            throw new IllegalArgumentException("page must be >= 0");
        }
        if (size < 1 || size > MAX_PAGE_SIZE) {
            throw new IllegalArgumentException("size must be between 1 and " + MAX_PAGE_SIZE);
        }
        return repository.findAll(PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "updatedAt")))
                .map(ContentRevisionSnapshot::from);
    }

    @Transactional(readOnly = true)
    public ContentRevisionSnapshot get(UUID revisionId) {
        return repository.findById(revisionId)
                .map(ContentRevisionSnapshot::from)
                .orElseThrow(() -> new ContentRevisionNotFoundException(revisionId));
    }
}
