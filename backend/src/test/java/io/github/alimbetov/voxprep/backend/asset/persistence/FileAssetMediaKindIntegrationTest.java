package io.github.alimbetov.voxprep.backend.asset.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest
@Transactional
class FileAssetMediaKindIntegrationTest {

    @Autowired private FileAssetRepository repository;

    @Test
    void postgresAcceptsCoverAndContentImageKinds() {
        FileAssetEntity cover = repository.saveAndFlush(asset(FileAssetKind.COVER_IMAGE, "media/cover.jpg", 'a'));
        FileAssetEntity content = repository.saveAndFlush(asset(FileAssetKind.CONTENT_IMAGE, "media/content.webp", 'b'));

        assertThat(cover.getKind()).isEqualTo(FileAssetKind.COVER_IMAGE);
        assertThat(content.getKind()).isEqualTo(FileAssetKind.CONTENT_IMAGE);
    }

    private static FileAssetEntity asset(FileAssetKind kind, String key, char hashChar) {
        return new FileAssetEntity(
                kind,
                FileAssetStatus.REGISTERED,
                "voxprep-test",
                key,
                kind == FileAssetKind.COVER_IMAGE ? "image/jpeg" : "image/webp",
                128,
                String.valueOf(hashChar).repeat(64));
    }
}
