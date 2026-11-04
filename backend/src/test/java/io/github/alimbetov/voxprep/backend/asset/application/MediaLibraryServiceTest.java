package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;

@ExtendWith(MockitoExtension.class)
class MediaLibraryServiceTest {
    @Mock FileAssetRepository files;
    @Mock FileAssetIngestService ingest;
    @Mock ContentAssetBindingService binding;
    @Mock ObjectStoragePort storage;
    @Mock JdbcTemplate jdbc;
    @Mock PlatformTransactionManager manager;
    @Mock TransactionStatus status;

    private MediaLibraryService library;

    @BeforeEach
    void setUp() {
        library = new MediaLibraryService(files, ingest, binding, storage,
                jdbc, manager, "voxprep-assets");
    }

    @Test
    void imageBindingReusesExistingReadyAssetId() {
        var revisionId = UUID.randomUUID();
        var assetId = UUID.randomUUID();
        library.bind(revisionId, ContentAssetRole.COVER_IMAGE, assetId);
        verify(binding).bind(revisionId, ContentAssetRole.COVER_IMAGE, assetId, null);
        verifyNoInteractions(ingest);
    }

    @Test
    void cannotBindAudioThroughImageLibrary() {
        assertThatThrownBy(() -> library.bind(UUID.randomUUID(),
                ContentAssetRole.NARRATION, UUID.randomUUID()))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(binding);
    }

    @Test
    void previewVerifiesStoredImageChecksum() throws Exception {
        var id = UUID.randomUUID();
        byte[] png = new byte[] {(byte) 137, 80, 78, 71, 13, 10, 26, 10};
        var digest = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(png));
        var file = new FileAssetEntity(FileAssetKind.COVER_IMAGE, FileAssetStatus.READY,
                "voxprep-assets", "sample.png", "image/png", png.length, digest);
        when(files.findById(id)).thenReturn(Optional.of(file));
        when(storage.read("voxprep-assets", "sample.png")).thenReturn(png);
        assertThat(library.preview(id)).isEqualTo(png);
    }

    @Test
    void rejectsCorruptPreview() {
        var id = UUID.randomUUID();
        var file = new FileAssetEntity(FileAssetKind.CONTENT_IMAGE, FileAssetStatus.READY,
                "voxprep-assets", "sample.png", "image/png", 8, "a".repeat(64));
        when(files.findById(id)).thenReturn(Optional.of(file));
        when(storage.read("voxprep-assets", "sample.png")).thenReturn(new byte[8]);
        assertThatThrownBy(() -> library.preview(id))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("integrity");
    }

    @Test
    void rejectsSpoofedMimeBeforeDatabaseOrStorageAccess() {
        assertThatThrownBy(() -> library.upload(ContentAssetRole.CONTENT_IMAGE,
                "image/png", new byte[] {1, 2, 3, 4, 5, 6, 7, 8}))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("signature");
        verifyNoInteractions(files, ingest, storage);
    }

    @Test
    void rejectsAudioUpload() {
        assertThatThrownBy(() -> library.upload(ContentAssetRole.NARRATION,
                "image/png", new byte[] {1, 2, 3}))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
