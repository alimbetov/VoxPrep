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
    public byte[] fetch(String provider, String url) {
        TtsModelArtifactProvider adapter = providers.get(normalize(provider));
        if (adapter == null) {
            throw new UnsupportedTtsArtifactProviderException(provider);
        }
        return Objects.requireNonNull(adapter.fetch(required(url, "url")), "provider returned null bytes").clone();
    }

    private static String normalize(String value) {
        return required(value, "provider").toLowerCase(Locale.ROOT);
    }

    private static String required(String value, String field) {
        Objects.requireNonNull(value, field);
        String normalized = value.strip();
        if (normalized.isEmpty() || !normalized.equals(value)) {
            throw new IllegalArgumentException("Invalid " + field);
        }
        return normalized;
    }

    public static class UnsupportedTtsArtifactProviderException extends RuntimeException {
        public UnsupportedTtsArtifactProviderException(String provider) {
            super("Unsupported TTS artifact provider: " + provider);
        }
    }
}
