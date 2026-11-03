package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import org.junit.jupiter.api.Test;

class TtsProvisioningBootstrapCoordinatorTest {

    @Test
    void disabledModeDoesNothing() {
        TtsProvisioningProperties properties = properties(TtsProvisioningMode.DISABLED, seed("en_US", "lessac", "high"));
        TtsModelProvisioningService provisioningService = mock(TtsModelProvisioningService.class);
        TtsModelMaterializationService materializationService = mock(TtsModelMaterializationService.class);
        TtsProvisioningBootstrapCoordinator coordinator = new TtsProvisioningBootstrapCoordinator(
                properties, provisioningService, materializationService);

        var report = coordinator.provisionConfiguredSeeds();

        assertThat(report.present()).isZero();
        assertThat(report.materialized()).isZero();
        assertThat(report.missing()).isEmpty();
        verify(provisioningService, never()).resolve(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void ensurePresentMaterializesResolvableAndReportsMissing() {
        TtsProvisioningProperties.Seed resolvableSeed = seed("en_US", "lessac", "high");
        TtsProvisioningProperties.Seed missingSeed = seed("tr_TR", "fahrettin", "medium");
        TtsProvisioningProperties properties = properties(
                TtsProvisioningMode.ENSURE_PRESENT, resolvableSeed, missingSeed);
        TtsModelProvisioningService provisioningService = mock(TtsModelProvisioningService.class);
        TtsModelMaterializationService materializationService = mock(TtsModelMaterializationService.class);
        TtsModelCatalogGateway.ModelDescriptor descriptor = mock(TtsModelCatalogGateway.ModelDescriptor.class);
        TtsModelSelector resolvable = resolvableSeed.selector();
        TtsModelSelector missing = missingSeed.selector();
        when(provisioningService.resolve(resolvable)).thenReturn(new TtsModelProvisioningService.Resolution(
                resolvable, TtsModelProvisioningService.State.RESOLVABLE, null, descriptor));
        when(provisioningService.resolve(missing)).thenReturn(new TtsModelProvisioningService.Resolution(
                missing, TtsModelProvisioningService.State.MISSING, null, null));

        TtsProvisioningBootstrapCoordinator coordinator = new TtsProvisioningBootstrapCoordinator(
                properties, provisioningService, materializationService);
        var report = coordinator.provisionConfiguredSeeds();

        assertThat(report.materialized()).isEqualTo(1);
        assertThat(report.missing()).containsExactly("tr_TR.fahrettin.medium");
        verify(materializationService).materialize(resolvable, descriptor);
    }

    @Test
    void strictModeFailsWhenAnySeedIsMissing() {
        TtsProvisioningProperties.Seed missingSeed = seed("es_ES", "davefx", "medium");
        TtsProvisioningProperties properties = properties(TtsProvisioningMode.STRICT, missingSeed);
        TtsModelProvisioningService provisioningService = mock(TtsModelProvisioningService.class);
        TtsModelMaterializationService materializationService = mock(TtsModelMaterializationService.class);
        TtsModelSelector missing = missingSeed.selector();
        when(provisioningService.resolve(missing)).thenReturn(new TtsModelProvisioningService.Resolution(
                missing, TtsModelProvisioningService.State.MISSING, null, null));

        TtsProvisioningBootstrapCoordinator coordinator = new TtsProvisioningBootstrapCoordinator(
                properties, provisioningService, materializationService);

        assertThatThrownBy(coordinator::provisionConfiguredSeeds)
                .isInstanceOf(TtsProvisioningBootstrapCoordinator.TtsProvisioningException.class)
                .hasMessageContaining("es_ES.davefx.medium");
    }

    private static TtsProvisioningProperties properties(
            TtsProvisioningMode mode,
            TtsProvisioningProperties.Seed... seeds) {
        TtsProvisioningProperties properties = new TtsProvisioningProperties();
        properties.setMode(mode);
        properties.setSeeds(List.of(seeds));
        return properties;
    }

    private static TtsProvisioningProperties.Seed seed(String locale, String voice, String quality) {
        TtsProvisioningProperties.Seed seed = new TtsProvisioningProperties.Seed();
        seed.setLocale(locale);
        seed.setVoice(voice);
        seed.setQuality(quality);
        return seed;
    }
}
