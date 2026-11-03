package io.github.alimbetov.voxprep.backend.infrastructure.tts;

import io.github.alimbetov.voxprep.backend.tts.application.TtsModelArtifactProvider;
import io.github.alimbetov.voxprep.backend.tts.application.TtsModelArtifactSource;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import org.springframework.stereotype.Component;

@Component
public class HuggingFaceTtsModelArtifactProvider implements TtsModelArtifactProvider {

    private static final int MAX_REDIRECTS = 5;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .followRedirects(HttpClient.Redirect.NEVER)
            .build();

    @Override
    public String providerId() {
        return "huggingface";
    }

    @Override
    public byte[] fetch(TtsModelArtifactSource.ArtifactRequest request) {
        URI uri = URI.create(request.url());
        validateProviderUri(uri);
        validatePinnedIdentity(uri, request.repository(), request.revision());
        return download(uri, 0);
    }

    private byte[] download(URI uri, int redirectCount) {
        if (redirectCount > MAX_REDIRECTS) {
            throw new TtsArtifactDownloadException("Too many Hugging Face redirects");
        }
        validateProviderUri(uri);
        HttpRequest httpRequest = HttpRequest.newBuilder(uri)
                .timeout(Duration.ofMinutes(2))
                .header("User-Agent", "VoxPrep-TTS-Provisioner/1")
                .GET()
                .build();
        try {
            HttpResponse<byte[]> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofByteArray());
            if (isRedirect(response.statusCode())) {
                String location = response.headers().firstValue("location")
                        .orElseThrow(() -> new TtsArtifactDownloadException("Redirect without Location header"));
                URI redirected = uri.resolve(location);
                validateProviderUri(redirected);
                return download(redirected, redirectCount + 1);
            }
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

    private static void validatePinnedIdentity(URI uri, String repository, String revision) {
        String expectedPrefix = "/" + repository + "/resolve/" + revision + "/";
        if (uri.getPath() == null || !uri.getPath().startsWith(expectedPrefix)) {
            throw new IllegalArgumentException("Hugging Face URL does not match pinned repository/revision");
        }
    }

    private static void validateProviderUri(URI uri) {
        String host = uri.getHost();
        if (!"https".equalsIgnoreCase(uri.getScheme()) || host == null || !allowedHost(host)) {
            throw new IllegalArgumentException("Unsupported Hugging Face artifact URL");
        }
    }

    private static boolean allowedHost(String host) {
        String normalized = host.toLowerCase(java.util.Locale.ROOT);
        return normalized.equals("huggingface.co")
                || normalized.endsWith(".huggingface.co")
                || normalized.equals("hf.co")
                || normalized.endsWith(".hf.co");
    }

    private static boolean isRedirect(int status) {
        return status == 301 || status == 302 || status == 303 || status == 307 || status == 308;
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
