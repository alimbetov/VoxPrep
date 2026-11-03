package io.github.alimbetov.voxprep.backend.installation.web;

import io.github.alimbetov.voxprep.backend.installation.application.InstallationRegistrationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/installations")
public class InstallationRegistrationController {

    private final InstallationRegistrationService registrationService;

    public InstallationRegistrationController(InstallationRegistrationService registrationService) {
        this.registrationService = registrationService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.OK)
    public RegistrationResponse register(@Valid @RequestBody RegistrationRequest request) {
        var result = registrationService.register(request.installationId());
        return new RegistrationResponse(
                result.installationId(),
                result.installationToken(),
                result.issuedAt());
    }

    public record RegistrationRequest(@NotNull UUID installationId) {
    }

    public record RegistrationResponse(
            UUID installationId,
            String installationToken,
            Instant issuedAt) {
    }
}
