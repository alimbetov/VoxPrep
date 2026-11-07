package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import org.mockito.ArgumentMatchers;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;
import org.springframework.transaction.TransactionStatus;

import io.github.alimbetov.voxprep.backend.asset.application.FileAssetIngestService;
import io.github.alimbetov.voxprep.backend.asset.application.ObjectStoragePort;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.support.TransactionTemplate;

class KokoroBundleProvisioningTest {

    private final TtsModelArtifactSource source = mock(TtsModelArtifactSource.class);
    private final FileAssetIngestService ingest = mock(FileAssetIngestService.class);
    private final FileAssetRepository assets = mock(FileAssetRepository.class);
    private final ObjectStoragePort storage = mock(ObjectStoragePort.class);
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final TransactionTemplate transaction = mock(TransactionTemplate.class);
    private final TtsProvisioningLock lock = mock(TtsProvisioningLock.class);

    private KokoroBundleProvisioningService service() {
        return new KokoroBundleProvisioningService(
                source, ingest, assets, storage, jdbc, transaction, lock);
    }

    private KokoroProvisioningProperties.Bundle fixture() {
        var bundle = new KokoroProvisioningProperties.Bundle();
        bundle.setModelCode("kokoro-en-us-int8");
        bundle.setSourceRepository("onnx-community/Kokoro-82M-v1.0-ONNX");
        bundle.setSourceRevision("1939ad2a8e416c0acfeecc08a694d14ef25f2231");
        bundle.setLicenseName("Apache-2.0");
        bundle.setLicenseReference("https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX");
        var item = new KokoroProvisioningProperties.Artifact();
        item.setPath("onnx/model_quantized.onnx");
        item.setRole("MODEL");
        item.setSha256("fbae9257e1e05ffc727e951ef9b9c98418e6d79f1c9b6b13bd59f5c9028a1478");
        item.setSizeBytes(92400000L);
        item.setUrl("https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/"
                + bundle.getSourceRevision() + "/onnx/model_quantized.onnx");
        bundle.setArtifacts(List.of(item));
        return bundle;
    }

    @Test
    @SuppressWarnings("unchecked")
    void verifiedBytesAreIngestedAndBundleIsCommittedOnlyAfterAssetsReady() throws Exception {
        byte[] bytes = "kokoro-test-onnx".getBytes(StandardCharsets.UTF_8);
        var bundle = fixture();
        bundle.getArtifacts().getFirst().setSizeBytes(bytes.length);
        bundle.getArtifacts().getFirst().setSha256(
                HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes)));
        var asset = mock(FileAssetEntity.class);
        UUID assetId = UUID.randomUUID();
        when(asset.getId()).thenReturn(assetId);
        when(asset.getKind()).thenReturn(FileAssetKind.TTS_MODEL);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        when(asset.getSizeBytes()).thenReturn((long) bytes.length);
        when(asset.getSha256()).thenReturn(bundle.getArtifacts().getFirst().getSha256());
        when(storage.defaultBucket()).thenReturn("voxprep-assets");
        when(jdbc.queryForList(anyString(), eq(bundle.getModelCode()))).thenReturn(List.of());
        when(assets.findByBucketAndObjectKey(anyString(), anyString())).thenReturn(Optional.empty());
        when(source.fetch(any())).thenReturn(bytes);
        when(ingest.ingest(any())).thenReturn(asset);
        org.mockito.Mockito.doAnswer(inv -> ((Supplier<?>) inv.getArgument(1)).get())
                .when(lock).withLock(anyString(), any());
        when(transaction.execute(any())).thenAnswer(inv -> {
            var callback = (org.springframework.transaction.support.TransactionCallback<UUID>) inv.getArgument(0);
            return callback.doInTransaction(mock(TransactionStatus.class));
        });

        UUID staged = service().provision(bundle);
        assertThat(staged).isNotNull();
        verify(source).fetch(any());
        verify(ingest).ingest(any());
        verify(jdbc, org.mockito.Mockito.times(2)).update(anyString(), any(Object[].class));
    }

    @Test
    void rejectsUnpinnedRevisionBeforeNetworkOrStorage() {
        var bundle = fixture();
        bundle.setSourceRevision("main");
        assertThatThrownBy(() -> service().provision(bundle))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(source, ingest, jdbc);
    }

    @Test
    void rejectsUntrustedUrlBeforeNetworkOrStorage() {
        var bundle = fixture();
        bundle.getArtifacts().getFirst().setUrl("https://other.example/weights.onnx");
        assertThatThrownBy(() -> service().provision(bundle))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(source, ingest, jdbc);
    }

    @Test
    void disabledRunnerPerformsNoNetworkActivity() {
        var props = new KokoroProvisioningProperties();
        var bundles = mock(KokoroBundleProvisioningService.class);
        assertThat(new KokoroBundleProvisioningBootstrap(props, bundles).provisionConfiguredBundles())
                .isZero();
        verifyNoInteractions(bundles);
    }

    @Test
    void enabledRunnerWithoutPinnedBundlesFailsClosed() {
        var props = new KokoroProvisioningProperties();
        props.setEnabled(true);
        var bundles = mock(KokoroBundleProvisioningService.class);
        assertThatThrownBy(() -> new KokoroBundleProvisioningBootstrap(
                props, bundles).provisionConfiguredBundles())
                .isInstanceOf(IllegalStateException.class);
        verifyNoInteractions(bundles);
    }
}
