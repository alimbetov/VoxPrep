package io.github.alimbetov.voxprep.backend.infrastructure.storage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Response;
import software.amazon.awssdk.services.s3.model.S3Object;

@ExtendWith(MockitoExtension.class)
class RustFsOrphanInventoryServiceTest {

    @Mock private S3Client s3;
    @Mock private FileAssetRepository assets;
    @Mock private FileAssetEntity known;
    private RustFsOrphanInventoryService inventory;

    @BeforeEach
    void setup() {
        var properties = new RustFsProperties();
        properties.setBucket("voxprep-assets");
        inventory = new RustFsOrphanInventoryService(s3, assets, properties);
    }

    @Test
    void returnsSuspectsWithoutDeletingAndLimitsS3Listing() {
        var now = Instant.parse("2026-11-03T10:00:00Z");
        when(s3.listObjectsV2(any(ListObjectsV2Request.class))).thenReturn(
                ListObjectsV2Response.builder()
                        .contents(
                                S3Object.builder().key("content/a.png").size(12L).lastModified(now).build(),
                                S3Object.builder().key("content/b.png").size(8L).lastModified(now).build())
                        .isTruncated(true)
                        .nextContinuationToken("next-page")
                        .build());
        when(assets.findByBucketAndObjectKey("voxprep-assets", "content/a.png"))
                .thenReturn(Optional.of(known));
        when(assets.findByBucketAndObjectKey("voxprep-assets", "content/b.png"))
                .thenReturn(Optional.empty());

        var page = inventory.scan("content/", null, 2);

        assertThat(page.entries()).hasSize(2);
        assertThat(page.entries().getFirst().suspectedOrphan()).isFalse();
        assertThat(page.entries().getLast().suspectedOrphan()).isTrue();
        assertThat(page.truncated()).isTrue();
        assertThat(page.nextContinuationToken()).isEqualTo("next-page");
        var request = ArgumentCaptor.forClass(ListObjectsV2Request.class);
        verify(s3).listObjectsV2(request.capture());
        assertThat(request.getValue().maxKeys()).isEqualTo(2);
        assertThat(request.getValue().prefix()).isEqualTo("content/");
    }

    @Test
    void rejectsUnsafePrefixesAndUnboundedPages() {
        assertThatThrownBy(() -> inventory.scan("", null, 10))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> inventory.scan("../", null, 10))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> inventory.scan("content/", null, 101))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> inventory.scan("content/", null, 0))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
