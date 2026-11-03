package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class LearnerAssetResolutionServiceTest {
    private final UUID assetId = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private final CurrentPublicationResolver publication = mock(CurrentPublicationResolver.class);
    private final ContentAssetBindingRepository repository = mock(ContentAssetBindingRepository.class);
    private final LearnerContentAccessPolicy access = mock(LearnerContentAccessPolicy.class);
    private final LearnerMediaService media = mock(LearnerMediaService.class);
    private final LearnerWirePublicationService wire = mock(LearnerWirePublicationService.class);
    private final LearnerAssetResolutionService service =
            new LearnerAssetResolutionService(publication, repository, access, media, wire);

    @Test
    void deniesAssetsNotReferencedByCurrentManifest() {
        givenPublication();
        when(repository.findAllByFileAsset_Id(assetId)).thenReturn(List.of());
        assertThatThrownBy(() -> service.requirePublished(assetId))
                .isInstanceOf(LearnerMediaService.MediaUnavailableException.class);
        verifyNoInteractions(access, media);
    }

    @Test
    void verifiesExactCurrentIdentityBeforeReturningDescriptor() {
        givenPublication();
        var binding = currentBinding();
        when(repository.findAllByFileAsset_Id(assetId)).thenReturn(List.of(binding));

        service.requirePublished(assetId);

        verify(access).requireAccessible("phrase", "HELLO");
        verify(media).describe(assetId);
    }

    @Test
    void cannotBypassPremiumAccessUsingDirectAssetId() {
        givenPublication();
        var binding = currentBinding();
        when(repository.findAllByFileAsset_Id(assetId)).thenReturn(List.of(binding));
        doThrow(new LearnerPremiumAccessDeniedException())
                .when(access).requireAccessible("phrase", "HELLO");

        assertThatThrownBy(() -> service.requirePublished(assetId))
                .isInstanceOf(LearnerPremiumAccessDeniedException.class);
        verifyNoInteractions(media);
    }

    @Test
    void staleRevisionBindingDoesNotQualifyForCurrentAssetDelivery() {
        givenPublication();
        var binding = currentBinding();
        when(binding.getContentRevision().getChecksum()).thenReturn(new Sha256Digest("c".repeat(64)));
        when(repository.findAllByFileAsset_Id(assetId)).thenReturn(List.of(binding));

        assertThatThrownBy(() -> service.requirePublished(assetId))
                .isInstanceOf(LearnerMediaService.MediaUnavailableException.class);
        verifyNoInteractions(access, media);
    }

    @Test
    void deliversFrozenVerticalIconListedInPublishedPack() {
        givenPublication();
        when(repository.findAllByFileAsset_Id(assetId)).thenReturn(List.of());
        var descriptor = new LearnerMediaService.MediaDescriptor(assetId, "bucket",
                "icons/vertical.webp", "image/webp", 12L, "d".repeat(64), "\"" + "d".repeat(64) + "\"");
        when(media.describe(assetId)).thenReturn(descriptor);
        when(wire.catalogue("verticals", 1)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("items", List.of(Map.of("active", true,
                                "iconAssetId", assetId.toString()))), "a".repeat(64)));
        when(wire.root()).thenReturn(new LearnerWirePublicationService.WireResponse(
                Map.of("contentVersion", 1, "packs", List.of(
                        Map.of("code", "COLLECTION", "variant", "canonical", "revision", 1))),
                "a".repeat(64)));
        when(wire.pack("COLLECTION", "canonical", 1)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("assets", List.of(Map.of(
                                "assetId", assetId.toString(),
                                "checksumSha256", "d".repeat(64),
                                "deliveryKey", "icons/vertical.webp",
                                "mediaType", "image/webp", "sizeBytes", 12L))),
                        "a".repeat(64)));

        assertThat(service.requirePublished(assetId)).isEqualTo(descriptor);
        verifyNoInteractions(access);
    }

    @Test
    void iconNotPresentInFrozenPackIsDeniedBeforeDownloading() {
        givenPublication();
        when(repository.findAllByFileAsset_Id(assetId)).thenReturn(List.of());
        var descriptor = new LearnerMediaService.MediaDescriptor(assetId, "bucket",
                "icons/vertical.webp", "image/webp", 12L, "d".repeat(64), "\"" + "d".repeat(64) + "\"");
        when(media.describe(assetId)).thenReturn(descriptor);
        when(wire.catalogue("verticals", 1)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("items", List.of(Map.of("active", true,
                                "iconAssetId", assetId.toString()))), "a".repeat(64)));
        when(wire.root()).thenReturn(new LearnerWirePublicationService.WireResponse(
                Map.of("contentVersion", 1, "packs", List.of(
                        Map.of("code", "COLLECTION", "variant", "canonical", "revision", 1))),
                "a".repeat(64)));
        when(wire.pack("COLLECTION", "canonical", 1)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("assets", List.of()), "a".repeat(64)));

        assertThatThrownBy(() -> service.requirePublished(assetId))
                .isInstanceOf(LearnerMediaService.MediaUnavailableException.class);
    }

    private void givenPublication() {
        var identity = new ContentRevisionIdentity(new BusinessCode("HELLO"), ContentType.PHRASE,
                new RevisionNumber(1));
        var ref = new PublicationExactContentRef(identity, new Sha256Digest("b".repeat(64)));
        when(publication.resolve()).thenReturn(new CurrentPublicationSnapshot(
                1, "a".repeat(64), Instant.parse("2026-11-03T12:00:00Z"), List.of(ref)));
    }

    private ContentAssetBindingEntity currentBinding() {
        var binding = mock(ContentAssetBindingEntity.class);
        var revision = mock(ContentRevisionEntity.class);
        var file = mock(FileAssetEntity.class);
        when(binding.getContentRevision()).thenReturn(revision);
        when(binding.getFileAsset()).thenReturn(file);
        when(binding.getRole()).thenReturn(ContentAssetRole.COVER_IMAGE);
        when(file.getStatus()).thenReturn(FileAssetStatus.READY);
        when(file.getKind()).thenReturn(FileAssetKind.COVER_IMAGE);
        when(revision.getIdentity()).thenReturn(new ContentRevisionIdentity(
                new BusinessCode("HELLO"), ContentType.PHRASE, new RevisionNumber(1)));
        when(revision.getChecksum()).thenReturn(new Sha256Digest("b".repeat(64)));
        return binding;
    }
}
