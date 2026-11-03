package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import org.junit.jupiter.api.Test;

class ConfiguredTtsModelCatalogGatewayTest {

    @Test
    void resolvesPinnedDescriptorFromConfiguredSeed() {
        TtsProvisioningProperties properties = new TtsProvisioningProperties();
        TtsProvisioningProperties.Seed seed = seed("huggingface");
        properties.setSeeds(List.of(seed));

        ConfiguredTtsModelCatalogGateway gateway = new ConfiguredTtsModelCatalogGateway(properties);

        var descriptor = gateway.resolve(seed.selector()).orElseThrow();
        assertThat(descriptor.sourceProvider()).isEqualTo("huggingface");
        assertThat(descriptor.sourceRepository()).isEqualTo("rhasspy/piper-voices");
        assertThat(descriptor.sourceRevision()).isEqualTo("rev-1");
    }

    @Test
    void rejectsDuplicateSelectorConfiguration() {
        TtsProvisioningProperties properties = new TtsProvisioningProperties();
        properties.setSeeds(List.of(seed("huggingface"), seed("mirror")));

        assertThatThrownBy(() -> new ConfiguredTtsModelCatalogGateway(properties))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Duplicate configured TTS seed");
    }

    private static TtsProvisioningProperties.Seed seed(String provider) {
        TtsProvisioningProperties.Seed seed = new TtsProvisioningProperties.Seed();
        seed.setLocale("en_US");
        seed.setVoice("lessac");
        seed.setQuality("high");
        seed.setSourceProvider(provider);
        seed.setSourceRepository("rhasspy/piper-voices");
        seed.setSourceRevision("rev-1");
        seed.setEngineVersion("1.2.0");
        seed.setModelVersion("en_US-lessac-high");
        seed.setModelUrl("https://huggingface.co/rhasspy/piper-voices/resolve/rev-1/model.onnx");
        seed.setConfigUrl("https://huggingface.co/rhasspy/piper-voices/resolve/rev-1/model.onnx.json");
        seed.setModelSha256("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        seed.setConfigSha256("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
        seed.setLicenseName("MIT");
        seed.setLicenseReference("https://example.invalid/license");
        return seed;
    }
}
