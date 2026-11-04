package io.github.alimbetov.voxprep.backend.content.application;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import java.util.List;
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

    /** Bounded, server-filtered approved revision selector; posting still revalidates state. */
    @Transactional(readOnly = true)
    public Page<ContentRevisionSnapshot> approvedCandidates(String titleQuery, int page) {
        if (page < 0 || page > 10000) {
            throw new IllegalArgumentException("Invalid candidate page");
        }
        String query = titleQuery == null ? "" : titleQuery.strip();
        if (query.length() > 100) {
            throw new IllegalArgumentException("Candidate search exceeds 100 characters");
        }
        var statuses = List.of(ContentLifecycleStatus.APPROVED, ContentLifecycleStatus.PUBLISHED);
        var pageable = PageRequest.of(page, 30, Sort.by(Sort.Direction.DESC, "updatedAt"));
        var selected = query.isEmpty()
                ? repository.findByLifecycleIn(statuses, pageable)
                : repository.findByLifecycleInAndTitleContainingIgnoreCase(statuses, query, pageable);
        return selected.map(ContentRevisionSnapshot::from);
    }

    /** Exact approved question revisions only; bounded search for Practice Test picker. */
    @Transactional(readOnly = true)
    public Page<QuestionChoice> approvedQuestions(String titleQuery, int page) {
        if (page < 0 || page > 10000) {
            throw new IllegalArgumentException("Invalid question page");
        }
        String title = titleQuery == null ? "" : titleQuery.strip();
        if (title.length() > 100) {
            throw new IllegalArgumentException("Question search exceeds 100 characters");
        }
        var statuses = List.of(ContentLifecycleStatus.APPROVED, ContentLifecycleStatus.PUBLISHED);
        var pageable = PageRequest.of(page, 30, Sort.by(Sort.Direction.DESC, "updatedAt"));
        return repository.searchApprovedQuestions(statuses, title, pageable)
                .map(entity -> new QuestionChoice(entity.getId(),
                        entity.getContentCode().value(), entity.getRevisionNumber().value(),
                        entity.getTitle()));
    }

    public record QuestionChoice(UUID id, String code, int revision, String title) {}

    @Transactional(readOnly = true)
    public ContentRevisionSnapshot get(UUID revisionId) {
        return repository.findById(revisionId)
                .map(ContentRevisionSnapshot::from)
                .orElseThrow(() -> new ContentRevisionNotFoundException(revisionId));
    }
}
