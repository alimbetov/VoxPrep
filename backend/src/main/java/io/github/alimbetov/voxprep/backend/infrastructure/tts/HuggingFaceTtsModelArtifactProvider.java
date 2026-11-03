package io.github.alimbetov.voxprep.backend.infrastructure.tts;

import io.github.alimbetov.voxprep.backend.tts.application.TtsModelArtifactProvider;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Set;
import org.springframework.stereotype.Component;

@Component
public class HuggingFaceTtsModelArtifactProvider implements TtsModelArtifactProvider {

    private static final Set<String> ALLOWED_HOSTS = Set.of("huggingface.co", "cdn-lfs.huggingface.co");

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    @Override
    public String providerId() {
        return "huggingface";
    }

    @Override
    public byte[] fetch(String url) {
        URI uri = URI.create(url);
        validate(uri);
        HttpRequest request = HttpRequest.newBuilder(uri)
                .timeout(Duration.ofMinutes(2))
                .GET()
                .build();
        try {
            HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new TtsArtifactDownloadException("Hugging Face returned HTTP " + response.statusCode());
            }
            if (response.body() == null || response.body().length == 0) {
                throw new TtsArtifactDownloadException("Hugging Face returned an empty artifact");
            }
            return response.body();
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new TtsArtifactDownloadException("Interrupted while downloading TTS artifact", exception);
        } catch (IOException exception) {
            throw new TtsArtifactDownloadException("Failed to download TTS artifact", exception);
        }
    }

    private static void validate(URI uri) {
        if (!"https".equalsIgnoreCase(uri.getScheme()) || !ALLOWED_HOSTS.contains(uri.getHost())) {
            throw new IllegalArgumentException("Unsupported Hugging Face artifact URL");
        }
    }

    public static class TtsArtifactDownloadException extends RuntimeException {
        public TtsArtifactDownloadException(String message) {
            super(message);
        }

        public TtsArtifactDownloadException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
