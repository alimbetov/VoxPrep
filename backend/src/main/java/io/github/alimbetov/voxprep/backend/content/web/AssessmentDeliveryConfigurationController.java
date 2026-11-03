package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.content.application.AssessmentDeliveryConfigurationService;
import io.github.alimbetov.voxprep.backend.content.application.AssessmentDeliveryConfigurationService.DeliveryConfiguration;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Admin-authenticated producer configuration required before publishing
 * practice-test revisions. No implicit mode/points defaults.
 */
@RestController
@RequestMapping("/admin/api/assessment/practice-tests")
public class AssessmentDeliveryConfigurationController {

    private final AssessmentDeliveryConfigurationService service;

    public AssessmentDeliveryConfigurationController(AssessmentDeliveryConfigurationService service) {
        this.service = service;
    }

    @PostMapping("/{revisionId}/delivery-config")
    public DeliveryConfiguration configure(
            @PathVariable UUID revisionId,
            @Valid @RequestBody Request request) {
        return service.configure(revisionId, request.mode(), request.points());
    }

    public record Request(@NotBlank String mode, @NotEmpty List<Integer> points) {
    }
}
