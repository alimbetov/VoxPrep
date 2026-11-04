package io.github.alimbetov.voxprep.backend.tts.persistence;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TtsJobRepository extends JpaRepository<TtsJobEntity, UUID> {

    List<TtsJobEntity> findAllByStatusOrderByCreatedAtAsc(TtsJobStatus status);

    List<TtsJobEntity> findAllByContentRevisionIdAndStatusOrderByAudioRoleAsc(
            UUID contentRevisionId,
            TtsJobStatus status);

    Optional<TtsJobEntity> findByFingerprint(String fingerprint);

    Page<TtsJobEntity> findByContentRevisionId(UUID contentRevisionId, Pageable pageable);
}
