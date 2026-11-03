package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class TtsModelProvisioningServiceTest {

    @Test
    void normalizesSelectorAndPrefersExistingModel() {
        TtsVoiceModelRepository repository = mock(TtsVoiceModelRepository.class);
        TtsVoiceModelEntity existing = mock(TtsVoiceModelEntity.class);
        TtsModelSelector selector = new TtsModelSelector("en-US", "Lessac", "HIGH");
        when(repository.findByCode("en_US.lessac.high")).thenReturn(Optional.of(existing));

        TtsModelProvisioningService service = new TtsModelProvisioningService(repository, List.of());

        TtsModelProvisioningService.Resolution resolution = service.resolve(selector);

        assertThat(resolution.state()).isEqualTo(TtsModelProvisioningService.State.PRESENT);
        assertThat(resolution.existingModel()).isSameAs(existing);
        assertThat(resolution.descriptor()).isNull();
    }

    @Test
    void resolvesMissingModelThroughCatalogueGateway() {
        TtsVoiceModelRepository repository = mock(TtsVoiceModelRepository.class);
        TtsModelCatalogGateway gateway = mock(TtsModelCatalogGateway.class);
        TtsModelSelector selector = new TtsModelSelector("de_DE", "thorsten", "high");
        TtsModelCatalogGateway.ModelDescriptor descriptor = new TtsModelCatalogGateway.ModelDescriptor(
                "rev-1",
                "https://example.invalid/model.onnx",
                "https://example.invalid/model.onnx.json",
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                "MIT",
                "https://example.invalid/license");
        when(repository.findByCode(selector.modelCode())).thenReturn(Optional.empty());
        when(gateway.resolve(selector)).thenReturn(Optional.of(descriptor));

        TtsModelProvisioningService service = new TtsModelProvisioningService(repository, List.of(gateway));

        TtsModelProvisioningService.Resolution resolution = service.resolve(selector);

        assertThat(resolution.state()).isEqualTo(TtsModelProvisioningService.State.RESOLVABLE);
        assertThat(resolution.existingModel()).isNull();
        assertThat(resolution.descriptor()).isSameAs(descriptor);
    }

    @Test
    void reportsMissingWhenNoGatewayCanResolveSelector() {
        TtsVoiceModelRepository repository = mock(TtsVoiceModelRepository.class);
        TtsModelSelector selector = new TtsModelSelector("tr_TR", "fahrettin", "medium");
        when(repository.findByCode(selector.modelCode())).thenReturn(Optional.empty());

        TtsModelProvisioningService service = new TtsModelProvisioningService(repository, List.of());

        assertThat(service.resolve(selector).state()).isEqualTo(TtsModelProvisioningService.State.MISSING);
    }
}
