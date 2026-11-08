package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

class ExternalLearningVideoServiceTest {

    @Test
    void canonicalYoutubeAndShortUrlsHaveSameVideoIdentity() {
        assertThat(ExternalLearningVideoService.parseYouTubeId(
                "https://www.youtube.com/watch?v=AbCdEfGh123")).isEqualTo("AbCdEfGh123");
        assertThat(ExternalLearningVideoService.parseYouTubeId(
                "https://youtu.be/AbCdEfGh123")).isEqualTo("AbCdEfGh123");
        assertThat(ExternalLearningVideoService.parseYouTubeId(
                "https://youtube.com/watch?v=AbCdEfGh123")).isEqualTo("AbCdEfGh123");
    }

    static Stream<String> maliciousOrUnsupported() {
        return Stream.of(
                "", " https://youtu.be/AbCdEfGh123",
                "http://youtu.be/AbCdEfGh123",
                "javascript:alert(1)",
                "file:///etc/passwd",
                "https://youtube.com.evil.example/watch?v=AbCdEfGh123",
                "https://evil.example@youtube.com/watch?v=AbCdEfGh123",
                "https://www.youtube.com:8443/watch?v=AbCdEfGh123",
                "https://www.youtube.com/watch?v=AbCdEfGh123&list=PL123",
                "https://www.youtube.com/watch?v=AbCdEfGh123&v=AbCdEfGh123",
                "https://www.youtube.com/watch?v=short",
                "https://www.youtube.com/watch?v=AbCdEfGh123#t=120",
                "https://youtu.be/AbCdEfGh123?feature=share",
                "https://youtu.be/AbCdEfGh123/extra",
                "https://www.youtube.com/playlist?list=AbCdEfGh123",
                "https://www.yоutube.com/watch?v=AbCdEfGh123"
        );
    }

    @ParameterizedTest
    @MethodSource("maliciousOrUnsupported")
    void rejectsUntrustedLinksWithoutResolvingOrContactingTheRemoteHost(String input) {
        assertThatThrownBy(() -> ExternalLearningVideoService.parseYouTubeId(input))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
