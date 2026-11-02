package io.github.alimbetov.voxprep.backend.tts.persistence;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TtsVoiceModelRepository extends JpaRepository<TtsVoiceModelEntity, UUID> {

    Optional<TtsVoiceModelEntity> findByCode(String code);

    List<TtsVoiceModelEntity> findAllByVoice_IdAndStatusOrderByCodeAsc(
            UUID voiceId,
            TtsVoiceModelStatus status);
}
