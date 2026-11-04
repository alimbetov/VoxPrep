package io.github.alimbetov.voxprep.backend.installation.web;

import io.github.alimbetov.voxprep.backend.installation.application.InstallationRegistrationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/installations")
public class InstallationRegistrationController {

    private final InstallationRegistrationService registrationService;

    public InstallationRegistrationController(InstallationRegistrationService registrationService) {
        this.registrationService = registrationService;
    }

    @PostMapping
    public ResponseEntity<RegistrationResponse> register(
            @Valid @RequestBody RegistrationRequest request,
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authorization) {
        var result = registrationService.register(request.installationId(), authorization);
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(new RegistrationResponse(
                        result.installationId(),
                        result.installationToken(),
                        result.issuedAt()));
    }

    public record RegistrationRequest(@NotNull UUID installationId) {
    }

    public record RegistrationResponse(
            UUID installationId,
            String installationToken,
            Instant issuedAt) {
    }
}
