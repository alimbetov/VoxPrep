package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

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
