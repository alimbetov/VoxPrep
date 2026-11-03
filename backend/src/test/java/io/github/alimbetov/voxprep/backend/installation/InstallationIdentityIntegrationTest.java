package io.github.alimbetov.voxprep.backend.installation;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.installation.application.InstallationRegistrationService;
import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationRepository;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationAuthenticationException;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationAuthenticationService;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest
class InstallationIdentityIntegrationTest {

    @Autowired
    private InstallationRegistrationService registrationService;

    @Autowired
    private InstallationAuthenticationService authenticationService;

    @Autowired
    private InstallationRepository repository;

    @AfterEach
    void cleanup() {
        repository.deleteAll();
    }

    @Test
    void repeatRegistrationRotatesTokenAndInvalidatesPreviousToken() {
        UUID installationId = UUID.randomUUID();

        var first = registrationService.register(installationId);
        var second = registrationService.register(installationId);

        assertThat(second.installationId()).isEqualTo(installationId);
        assertThat(second.installationToken()).isNotEqualTo(first.installationToken());
        assertThat(repository.findByInstallationId(installationId)).isPresent();
        assertThat(repository.count()).isEqualTo(1);

        assertThatThrownBy(() -> authenticationService.authenticate(first.installationToken()))
                .isInstanceOfSatisfying(InstallationAuthenticationException.class,
                        exception -> assertThat(exception.getCode()).isEqualTo("INSTALLATION_TOKEN_INVALID"));

        assertThat(authenticationService.authenticate(second.installationToken()).installationId())
                .isEqualTo(installationId);
    }

    @Test
    void blockedAndRevokedInstallationsAreRejectedFailClosed() {
        UUID blockedId = UUID.randomUUID();
        var blockedRegistration = registrationService.register(blockedId);
        var blocked = repository.findByInstallationId(blockedId).orElseThrow();
        blocked.block();
        repository.saveAndFlush(blocked);

        assertThatThrownBy(() -> authenticationService.authenticate(blockedRegistration.installationToken()))
                .isInstanceOfSatisfying(InstallationAuthenticationException.class,
                        exception -> assertThat(exception.getCode()).isEqualTo("INSTALLATION_BLOCKED"));

        UUID revokedId = UUID.randomUUID();
        var revokedRegistration = registrationService.register(revokedId);
        var revoked = repository.findByInstallationId(revokedId).orElseThrow();
        revoked.revoke();
        repository.saveAndFlush(revoked);

        assertThatThrownBy(() -> authenticationService.authenticate(revokedRegistration.installationToken()))
                .isInstanceOfSatisfying(InstallationAuthenticationException.class,
                        exception -> assertThat(exception.getCode()).isEqualTo("INSTALLATION_REVOKED"));
    }

    @Test
    void concurrentFirstRegistrationCreatesSingleIdentityAndOnlyLatestTokenRemainsValid() throws Exception {
        UUID installationId = UUID.randomUUID();
        var start = new CountDownLatch(1);

        try (var executor = Executors.newFixedThreadPool(2)) {
            var firstFuture = executor.submit(() -> {
                start.await();
                return registrationService.register(installationId);
            });
            var secondFuture = executor.submit(() -> {
                start.await();
                return registrationService.register(installationId);
            });

            start.countDown();
            var registrations = List.of(firstFuture.get(), secondFuture.get());

            assertThat(repository.count()).isEqualTo(1);
            assertThat(registrations)
                    .extracting(InstallationRegistrationService.RegistrationResult::installationId)
                    .containsOnly(installationId);
            assertThat(registrations)
                    .extracting(InstallationRegistrationService.RegistrationResult::installationToken)
                    .doesNotHaveDuplicates();

            long acceptedTokens = registrations.stream()
                    .filter(registration -> authenticates(registration.installationToken()))
                    .count();
            assertThat(acceptedTokens).isEqualTo(1);
        }
    }

    private boolean authenticates(String token) {
        try {
            authenticationService.authenticate(token);
            return true;
        } catch (InstallationAuthenticationException exception) {
            return false;
        }
    }
}
