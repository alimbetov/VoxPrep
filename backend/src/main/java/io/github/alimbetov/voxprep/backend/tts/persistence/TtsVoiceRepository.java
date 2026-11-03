package io.github.alimbetov.voxprep.backend.tts.persistence;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TtsVoiceRepository extends JpaRepository<TtsVoiceEntity, UUID> {

    Optional<TtsVoiceEntity> findByCode(String code);
}
