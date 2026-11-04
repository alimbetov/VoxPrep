package io.github.alimbetov.voxprep.backend.learner.web;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

class LearnerHttpCacheTest {

    @Test
    void etagIsDeterministicAndVersionSensitive() {
        String first = LearnerHttpCache.weakEtag("content", 7L, "root", "QUESTION", "q-1", 3, "checksum");
        String same = LearnerHttpCache.weakEtag("content", 7L, "root", "QUESTION", "q-1", 3, "checksum");
        String nextVersion = LearnerHttpCache.weakEtag("content", 8L, "root", "QUESTION", "q-1", 3, "checksum");
        String nextRoot = LearnerHttpCache.weakEtag("content", 7L, "other-root", "QUESTION", "q-1", 3, "checksum");
        String nextChecksum = LearnerHttpCache.weakEtag("content", 7L, "root", "QUESTION", "q-1", 3, "other-checksum");

        assertThat(first).isEqualTo(same).startsWith("W/\"").endsWith("\"");
        assertThat(nextVersion).isNotEqualTo(first);
        assertThat(nextRoot).isNotEqualTo(first);
        assertThat(nextChecksum).isNotEqualTo(first);
    }

    @Test
    void revalidateReturns304WithSameCacheContractForMatchingTag() {
        String etag = LearnerHttpCache.weakEtag("catalogue", 11L, "root");

        ResponseEntity<String> response = LearnerHttpCache.revalidate("body", etag, etag);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_MODIFIED);
        assertThat(response.getBody()).isNull();
        assertThat(response.getHeaders().getFirst(HttpHeaders.ETAG)).isEqualTo(etag);
        assertThat(response.getHeaders().getFirst(HttpHeaders.CACHE_CONTROL))
                .isEqualTo(LearnerHttpCache.CACHE_CONTROL)
                .doesNotContain("immutable");
    }

    @Test
    void revalidateReturns200ForMismatchedTagAndSupportsWeakComparison() {
        String etag = LearnerHttpCache.weakEtag("catalogue", 11L, "root");

        ResponseEntity<String> miss = LearnerHttpCache.revalidate("body", etag, "\"different\"");
        ResponseEntity<String> weakMatch = LearnerHttpCache.revalidate(
                "body", etag, etag.substring(2));

        assertThat(miss.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(miss.getBody()).isEqualTo("body");
        assertThat(miss.getHeaders().getFirst(HttpHeaders.CACHE_CONTROL))
                .isEqualTo(LearnerHttpCache.CACHE_CONTROL);
        assertThat(weakMatch.getStatusCode()).isEqualTo(HttpStatus.NOT_MODIFIED);
        assertThat(LearnerHttpCache.matches("*", etag)).isTrue();
    }
}
