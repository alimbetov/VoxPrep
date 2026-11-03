package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
class ContentAssetBindingIntegrationTest {

    @Autowired private ContentAssetBindingService bindingService;
    @Autowired private ContentAssetBindingRepository bindingRepository;
    @Autowired private ContentRevisionRepository contentRevisionRepository;
    @Autowired private FileAssetRepository fileAssetRepository;

    @Test
    void bindsReadyCoverImageToExactRevision() {
        var revision = revision("IMAGE");
        var asset = asset(FileAssetKind.COVER_IMAGE, FileAssetStatus.READY, "image/webp", "cover");

        var binding = bindingService.bind(
                revision.getId(), ContentAssetRole.COVER_IMAGE, asset.getId(), null);

        assertThat(binding.getContentRevision().getId()).isEqualTo(revision.getId());
        assertThat(binding.getFileAsset().getId()).isEqualTo(asset.getId());
        assertThat(bindingService.state(revision.getId(), ContentAssetRole.COVER_IMAGE, null))
                .isEqualTo(ContentAssetBindingService.BindingState.READY);
    }

    @Test
    void replacementKeepsOneActiveBindingPerRevisionAndRole() {
        var revision = revision("REPLACE");
        var first = asset(FileAssetKind.COVER_IMAGE, FileAssetStatus.READY, "image/png", "cover-first");
        var second = asset(FileAssetKind.COVER_IMAGE, FileAssetStatus.READY, "image/webp", "cover-second");

        bindingService.bind(revision.getId(), ContentAssetRole.COVER_IMAGE, first.getId(), null);
        bindingService.bind(revision.getId(), ContentAssetRole.COVER_IMAGE, second.getId(), null);

        var bindings = bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(revision.getId());
        assertThat(bindings).hasSize(1);
        assertThat(bindings.getFirst().getFileAsset().getId()).isEqualTo(second.getId());
    }

    @Test
    void audioBindingBecomesStaleWhenExpectedFingerprintChanges() {
        var revision = revision("AUDIO");
        var asset = asset(FileAssetKind.TTS_AUDIO, FileAssetStatus.READY, "audio/mpeg", "audio");
        String fingerprint = String.valueOf('a').repeat(64);

        bindingService.bind(
                revision.getId(), ContentAssetRole.PRONUNCIATION, asset.getId(), fingerprint);

        assertThat(bindingService.state(revision.getId(), ContentAssetRole.PRONUNCIATION, fingerprint))
                .isEqualTo(ContentAssetBindingService.BindingState.READY);
        assertThat(bindingService.state(
                revision.getId(), ContentAssetRole.PRONUNCIATION, String.valueOf('b').repeat(64)))
                .isEqualTo(ContentAssetBindingService.BindingState.STALE);
    }

    @Test
    void rejectsMutationAfterPublication() {
        var revision = revision("PUBLISHED");
        var first = asset(FileAssetKind.COVER_IMAGE, FileAssetStatus.READY, "image/png", "published-first");
        var second = asset(FileAssetKind.COVER_IMAGE, FileAssetStatus.READY, "image/webp", "published-second");
        bindingService.bind(revision.getId(), ContentAssetRole.COVER_IMAGE, first.getId(), null);

        revision.markReadyForAudio();
        contentRevisionRepository.saveAndFlush(revision);
        revision.markReadyForReview();
        contentRevisionRepository.saveAndFlush(revision);
        revision.approve(Instant.parse("2026-11-03T10:00:00Z"));
        contentRevisionRepository.saveAndFlush(revision);
        revision.publish(Instant.parse("2026-11-03T10:05:00Z"));
        contentRevisionRepository.saveAndFlush(revision);

        assertThatThrownBy(() -> bindingService.bind(
                revision.getId(), ContentAssetRole.COVER_IMAGE, second.getId(), null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("immutable");
    }

    @Test
    void rejectsWrongKindNonReadyAssetAndUnsupportedAudioRole() {
        var revision = revision("REJECT");
        var readyImage = asset(FileAssetKind.COVER_IMAGE, FileAssetStatus.READY, "image/png", "wrong-kind");
        var pendingAudio = asset(FileAssetKind.TTS_AUDIO, FileAssetStatus.REGISTERED, "audio/mpeg", "pending");
        var readyAudio = asset(FileAssetKind.TTS_AUDIO, FileAssetStatus.READY, "audio/mpeg", "wrong-role");

        assertThatThrownBy(() -> bindingService.bind(
                revision.getId(), ContentAssetRole.PRONUNCIATION, readyImage.getId(), String.valueOf('c').repeat(64)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("kind");
        assertThatThrownBy(() -> bindingService.bind(
                revision.getId(), ContentAssetRole.PRONUNCIATION, pendingAudio.getId(), String.valueOf('c').repeat(64)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("READY");
        assertThatThrownBy(() -> bindingService.bind(
                revision.getId(), ContentAssetRole.NARRATION, readyAudio.getId(), String.valueOf('c').repeat(64)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("phrase");
    }

    private PhraseContentRevisionEntity revision(String suffix) {
        return contentRevisionRepository.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode("R4_" + suffix),
                new RevisionNumber(1),
                new Sha256Digest(String.valueOf('1').repeat(64)),
                "Title",
                "Subtitle",
                "Description",
                new CatalogueCode("GENERAL"),
                new CatalogueCode("B1"),
                1,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "Could you tell me more?",
                "Usage",
                List.of("Example")));
    }

    private FileAssetEntity asset(
            FileAssetKind kind,
            FileAssetStatus status,
            String mediaType,
            String suffix) {
        return fileAssetRepository.saveAndFlush(new FileAssetEntity(
                kind,
                status,
                "voxprep-assets",
                "content/r4/" + suffix,
                mediaType,
                10,
                String.valueOf('2').repeat(64)));
    }
}
