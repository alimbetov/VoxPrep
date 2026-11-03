package io.github.alimbetov.voxprep.backend.tts.support;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.util.UUID;

public final class TtsTestAssets {

    private TtsTestAssets() {
    }

    public static ModelAssets createModelAssets(
            FileAssetRepository repository,
            String suffix,
            char modelHash,
            char configHash) {
        FileAssetEntity model = repository.saveAndFlush(new FileAssetEntity(
                FileAssetKind.TTS_MODEL,
                FileAssetStatus.READY,
                "voxprep-assets",
                "tts/models/" + suffix + ".onnx",
                "application/octet-stream",
                1024,
                String.valueOf(modelHash).repeat(64)));
        FileAssetEntity config = repository.saveAndFlush(new FileAssetEntity(
                FileAssetKind.TTS_CONFIG,
                FileAssetStatus.READY,
                "voxprep-assets",
                "tts/models/" + suffix + ".onnx.json",
                "application/json",
                512,
                String.valueOf(configHash).repeat(64)));
        return new ModelAssets(model.getId(), config.getId());
    }

    public record ModelAssets(UUID modelAssetId, UUID configAssetId) {
    }
}
