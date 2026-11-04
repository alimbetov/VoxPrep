package io.github.alimbetov.voxprep.backend.asset.persistence;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
        name = "content_asset_binding",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_content_asset_binding__revision_role",
                columnNames = {"content_revision_id", "role"}))
public class ContentAssetBindingEntity extends AbstractJpaEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "content_revision_id", nullable = false, updatable = false)
    private ContentRevisionEntity contentRevision;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, updatable = false, length = 32)
    private ContentAssetRole role;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "file_asset_id", nullable = false)
    private FileAssetEntity fileAsset;

    @Column(name = "source_fingerprint", length = 64)
    private String sourceFingerprint;

    protected ContentAssetBindingEntity() {
    }

    public ContentAssetBindingEntity(
            ContentRevisionEntity contentRevision,
            ContentAssetRole role,
            FileAssetEntity fileAsset,
            String sourceFingerprint) {
        this.contentRevision = java.util.Objects.requireNonNull(contentRevision, "contentRevision");
        this.role = java.util.Objects.requireNonNull(role, "role");
        this.fileAsset = java.util.Objects.requireNonNull(fileAsset, "fileAsset");
        this.sourceFingerprint = validateFingerprint(sourceFingerprint);
    }

    public void replaceFileAsset(FileAssetEntity fileAsset, String sourceFingerprint) {
        this.fileAsset = java.util.Objects.requireNonNull(fileAsset, "fileAsset");
        this.sourceFingerprint = validateFingerprint(sourceFingerprint);
    }

    public ContentRevisionEntity getContentRevision() {
        return contentRevision;
    }

    public ContentAssetRole getRole() {
        return role;
    }

    public FileAssetEntity getFileAsset() {
        return fileAsset;
    }

    public String getSourceFingerprint() {
        return sourceFingerprint;
    }

    private static String validateFingerprint(String value) {
        if (value == null) {
            return null;
        }
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("sourceFingerprint must be lowercase SHA-256");
        }
        return value;
    }
}
