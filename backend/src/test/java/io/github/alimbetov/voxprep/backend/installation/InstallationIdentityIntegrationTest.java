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

        var first = registrationService.register(installationId, null);
        var second = registrationService.register(installationId, "Bearer " + first.installationToken());

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
        var blockedRegistration = registrationService.register(blockedId, null);
        var blocked = repository.findByInstallationId(blockedId).orElseThrow();
        blocked.block();
        repository.saveAndFlush(blocked);

        assertThatThrownBy(() -> authenticationService.authenticate(blockedRegistration.installationToken()))
                .isInstanceOfSatisfying(InstallationAuthenticationException.class,
                        exception -> assertThat(exception.getCode()).isEqualTo("INSTALLATION_BLOCKED"));

        UUID revokedId = UUID.randomUUID();
        var revokedRegistration = registrationService.register(revokedId, null);
        var revoked = repository.findByInstallationId(revokedId).orElseThrow();
        revoked.revoke();
        repository.saveAndFlush(revoked);

        assertThatThrownBy(() -> authenticationService.authenticate(revokedRegistration.installationToken()))
                .isInstanceOfSatisfying(InstallationAuthenticationException.class,
                        exception -> assertThat(exception.getCode()).isEqualTo("INSTALLATION_REVOKED"));
    }

    @Test
    void existingInstallationCannotBeRotatedWithoutCorrectPreviousToken() {
        UUID installationId = UUID.randomUUID();
        var first = registrationService.register(installationId, null);
        UUID anotherId = UUID.randomUUID();
        var another = registrationService.register(anotherId, null);

        assertThatThrownBy(() -> registrationService.register(installationId, null))
                .isInstanceOf(InstallationAuthenticationException.class);
        assertThatThrownBy(() -> registrationService.register(installationId, "Bearer invalid"))
                .isInstanceOf(InstallationAuthenticationException.class);
        assertThatThrownBy(() -> registrationService.register(
                        installationId, "Bearer " + another.installationToken()))
                .isInstanceOf(InstallationAuthenticationException.class);

        assertThat(authenticationService.authenticate(first.installationToken()).installationId())
                .isEqualTo(installationId);
        var rotated = registrationService.register(installationId, "Bearer " + first.installationToken());
        assertThatThrownBy(() -> registrationService.register(
                        installationId, "Bearer " + first.installationToken()))
                .isInstanceOf(InstallationAuthenticationException.class);
        assertThat(authenticationService.authenticate(rotated.installationToken()).installationId())
                .isEqualTo(installationId);
    }

    @Test
    void blockedAndRevokedInstallationsCannotRotateEvenWithPreviousToken() {
        UUID blockedId = UUID.randomUUID();
        var blockedToken = registrationService.register(blockedId, null);
        var blocked = repository.findByInstallationId(blockedId).orElseThrow();
        blocked.block();
        repository.saveAndFlush(blocked);
        assertThatThrownBy(() -> registrationService.register(
                        blockedId, "Bearer " + blockedToken.installationToken()))
                .isInstanceOf(InstallationAuthenticationException.class);

        UUID revokedId = UUID.randomUUID();
        var revokedToken = registrationService.register(revokedId, null);
        var revoked = repository.findByInstallationId(revokedId).orElseThrow();
        revoked.revoke();
        repository.saveAndFlush(revoked);
        assertThatThrownBy(() -> registrationService.register(
                        revokedId, "Bearer " + revokedToken.installationToken()))
                .isInstanceOf(InstallationAuthenticationException.class);
    }

    @Test
    void concurrentAnonymousRegistrationOfSameUuidGrantsOnlyFirstClaim() throws Exception {
        UUID installationId = UUID.randomUUID();
        var start = new CountDownLatch(1);

        try (var executor = Executors.newFixedThreadPool(2)) {
            java.util.concurrent.Callable<Object> attempt = () -> {
                start.await();
                try {
                    return registrationService.register(installationId, null);
                } catch (InstallationAuthenticationException rejected) {
                    return rejected;
                }
            };
            var firstFuture = executor.submit(attempt);
            var secondFuture = executor.submit(attempt);

            start.countDown();
            var results = List.of(firstFuture.get(), secondFuture.get());
            assertThat(results.stream().filter(
                    InstallationRegistrationService.RegistrationResult.class::isInstance)).hasSize(1);
            assertThat(results.stream().filter(InstallationAuthenticationException.class::isInstance)).hasSize(1);
            assertThat(repository.count()).isEqualTo(1);
            var first = results.stream()
                    .filter(InstallationRegistrationService.RegistrationResult.class::isInstance)
                    .map(InstallationRegistrationService.RegistrationResult.class::cast)
                    .findFirst().orElseThrow();
            assertThat(authenticates(first.installationToken())).isTrue();
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
