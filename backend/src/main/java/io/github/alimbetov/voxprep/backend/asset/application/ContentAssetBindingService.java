package io.github.alimbetov.voxprep.backend.asset.application;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicy;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ContentAssetBindingService {

    private final ContentRevisionRepository contentRevisionRepository;
    private final FileAssetRepository fileAssetRepository;
    private final ContentAssetBindingRepository bindingRepository;
    private final ContentAudioPolicy contentAudioPolicy;

    public ContentAssetBindingService(
            ContentRevisionRepository contentRevisionRepository,
            FileAssetRepository fileAssetRepository,
            ContentAssetBindingRepository bindingRepository,
            ContentAudioPolicy contentAudioPolicy) {
        this.contentRevisionRepository = contentRevisionRepository;
        this.fileAssetRepository = fileAssetRepository;
        this.bindingRepository = bindingRepository;
        this.contentAudioPolicy = contentAudioPolicy;
    }

    @Transactional
    public ContentAssetBindingEntity bind(
            UUID contentRevisionId,
            ContentAssetRole role,
            UUID fileAssetId,
            String sourceFingerprint) {
        Objects.requireNonNull(contentRevisionId, "contentRevisionId");
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(fileAssetId, "fileAssetId");

        var revision = contentRevisionRepository.findById(contentRevisionId)
                .orElseThrow(() -> new IllegalArgumentException("Content revision not found: " + contentRevisionId));
        var asset = fileAssetRepository.findById(fileAssetId)
                .orElseThrow(() -> new IllegalArgumentException("File asset not found: " + fileAssetId));

        validateBinding(revision.getContentType(), role, asset, sourceFingerprint);

        var existing = bindingRepository.findByContentRevision_IdAndRole(contentRevisionId, role);
        if (existing.isPresent()) {
            var binding = existing.orElseThrow();
            binding.replaceFileAsset(asset, sourceFingerprint);
            return bindingRepository.save(binding);
        }
        return bindingRepository.save(new ContentAssetBindingEntity(revision, role, asset, sourceFingerprint));
    }

    @Transactional(readOnly = true)
    public BindingState state(UUID contentRevisionId, ContentAssetRole role, String expectedFingerprint) {
        Objects.requireNonNull(contentRevisionId, "contentRevisionId");
        Objects.requireNonNull(role, "role");
        return bindingRepository.findByContentRevision_IdAndRole(contentRevisionId, role)
                .map(binding -> state(binding, expectedFingerprint))
                .orElse(BindingState.MISSING);
    }

    private BindingState state(ContentAssetBindingEntity binding, String expectedFingerprint) {
        FileAssetEntity asset = binding.getFileAsset();
        if (asset.getStatus() != FileAssetStatus.READY) {
            return BindingState.NOT_READY;
        }
        if (binding.getRole().audio()) {
            if (expectedFingerprint == null || !expectedFingerprint.equals(binding.getSourceFingerprint())) {
                return BindingState.STALE;
            }
        }
        return BindingState.READY;
    }

    private void validateBinding(
            io.github.alimbetov.voxprep.backend.content.domain.ContentType contentType,
            ContentAssetRole role,
            FileAssetEntity asset,
            String sourceFingerprint) {
        if (asset.getStatus() != FileAssetStatus.READY) {
            throw new IllegalStateException("Only READY file assets may be bound to content");
        }
        if (asset.getKind() != role.assetKind()) {
            throw new IllegalArgumentException("File asset kind does not match content asset role " + role.wireName());
        }
        if (role.audio()) {
            var audioRole = role.audioRole().orElseThrow();
            contentAudioPolicy.requireAllowed(contentType, audioRole);
            if (sourceFingerprint == null || !sourceFingerprint.matches("[0-9a-f]{64}")) {
                throw new IllegalArgumentException("Audio binding requires lowercase SHA-256 sourceFingerprint");
            }
            if (!asset.getMediaType().startsWith("audio/")) {
                throw new IllegalArgumentException("Audio content asset requires audio/* media type");
            }
        } else {
            if (sourceFingerprint != null) {
                throw new IllegalArgumentException("Image binding must not carry a TTS sourceFingerprint");
            }
            if (role.assetKind() != FileAssetKind.COVER_IMAGE && role.assetKind() != FileAssetKind.CONTENT_IMAGE) {
                throw new IllegalArgumentException("Unsupported image content asset role");
            }
            if (!asset.getMediaType().startsWith("image/")) {
                throw new IllegalArgumentException("Image content asset requires image/* media type");
            }
        }
    }

    public enum BindingState {
        MISSING,
        NOT_READY,
        STALE,
        READY
    }
}
