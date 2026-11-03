package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PublicationCandidateManifestService {

    private final PublicationCandidateRepository candidateRepository;
    private final PublicationCandidateManifestRefRepository manifestRepository;
    private final PublicationCandidateValidator validator;

    public PublicationCandidateManifestService(
            PublicationCandidateRepository candidateRepository,
            PublicationCandidateManifestRefRepository manifestRepository,
            PublicationCandidateValidator validator) {
        this.candidateRepository = Objects.requireNonNull(candidateRepository, "candidateRepository");
        this.manifestRepository = Objects.requireNonNull(manifestRepository, "manifestRepository");
        this.validator = Objects.requireNonNull(validator, "validator");
    }

    @Transactional
    public PublicationValidationResult validateAndFreeze(
            UUID candidateId,
            List<PublicationExactContentRef> refs,
            Instant validatedAt) {
        Objects.requireNonNull(candidateId, "candidateId");
        Objects.requireNonNull(refs, "refs");
        Objects.requireNonNull(validatedAt, "validatedAt");

        PublicationCandidateEntity candidate = candidateRepository.findById(candidateId)
                .orElseThrow(() -> new IllegalArgumentException("publication candidate not found: " + candidateId));
        if (candidate.getStatus() != PublicationCandidateStatus.DRAFT) {
            throw new IllegalStateException("only DRAFT candidate can be frozen");
        }
        if (manifestRepository.existsByCandidateId(candidateId)) {
            throw new IllegalStateException("candidate manifest is already persisted");
        }

        PublicationValidationResult result = validator.validate(refs);
        if (!result.valid()) {
            return result;
        }

        List<PublicationExactContentRef> canonicalRefs = refs.stream().sorted().toList();
        List<String> canonicalKeys = canonicalRefs.stream().map(PublicationExactContentRef::canonicalKey).toList();
        if (!canonicalKeys.equals(result.canonicalRefs())) {
            throw new IllegalStateException("validator canonical manifest differs from persistence manifest");
        }

        List<PublicationCandidateManifestRefEntity> persistedRefs = new ArrayList<>(canonicalRefs.size());
        for (int position = 0; position < canonicalRefs.size(); position++) {
            persistedRefs.add(new PublicationCandidateManifestRefEntity(candidateId, position, canonicalRefs.get(position)));
        }
        manifestRepository.saveAll(persistedRefs);
        manifestRepository.flush();

        candidate.markValidated(result.rootSha256(), validatedAt);
        candidateRepository.save(candidate);
        return result;
    }

    @Transactional(readOnly = true)
    public List<PublicationExactContentRef> loadFrozenManifest(UUID candidateId) {
        Objects.requireNonNull(candidateId, "candidateId");
        return manifestRepository.findAllByCandidateIdOrderByPositionAsc(candidateId).stream()
                .map(PublicationCandidateManifestRefEntity::toExactRef)
                .toList();
    }
}
