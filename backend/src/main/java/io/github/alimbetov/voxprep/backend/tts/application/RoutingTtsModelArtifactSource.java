package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;

@Service
public class RoutingTtsModelArtifactSource implements TtsModelArtifactSource {

    private final Map<String, TtsModelArtifactProvider> providers;

    public RoutingTtsModelArtifactSource(List<TtsModelArtifactProvider> providers) {
        Objects.requireNonNull(providers, "providers");
        Map<String, TtsModelArtifactProvider> indexed = new LinkedHashMap<>();
        for (TtsModelArtifactProvider provider : providers) {
            Objects.requireNonNull(provider, "provider");
            String providerId = normalize(provider.providerId());
            TtsModelArtifactProvider previous = indexed.putIfAbsent(providerId, provider);
            if (previous != null) {
                throw new IllegalStateException("Duplicate TTS artifact provider: " + providerId);
            }
        }
        this.providers = Map.copyOf(indexed);
    }

    @Override
    public byte[] fetch(ArtifactRequest request) {
        Objects.requireNonNull(request, "request");
        TtsModelArtifactProvider adapter = providers.get(normalize(request.provider()));
        if (adapter == null) {
            throw new UnsupportedTtsArtifactProviderException(request.provider());
        }
        return Objects.requireNonNull(adapter.fetch(request), "provider returned null bytes").clone();
    }

    private static String normalize(String value) {
        Objects.requireNonNull(value, "provider");
        return value.toLowerCase(Locale.ROOT);
    }

    public static class UnsupportedTtsArtifactProviderException extends RuntimeException {
        public UnsupportedTtsArtifactProviderException(String provider) {
            super("Unsupported TTS artifact provider: " + provider);
        }
    }
}
