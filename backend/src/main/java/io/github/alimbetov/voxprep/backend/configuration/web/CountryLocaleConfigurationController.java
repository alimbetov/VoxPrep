package io.github.alimbetov.voxprep.backend.configuration.web;

import io.github.alimbetov.voxprep.backend.configuration.application.CountryLocaleConfigurationService;
import io.github.alimbetov.voxprep.backend.configuration.application.CountryLocaleConfigurationService.CountryLocaleConfiguration;
import java.time.Duration;
import java.util.Map;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Exact anonymous Flutter locale-configuration contract. */
@RestController
public class CountryLocaleConfigurationController {

    private final CountryLocaleConfigurationService service;

    public CountryLocaleConfigurationController(CountryLocaleConfigurationService service) {
        this.service = service;
    }

    @GetMapping("/api/v1/configuration/locales")
    public ResponseEntity<CountryLocaleConfiguration> get(
            @RequestParam String countryCode) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.maxAge(Duration.ofHours(1)).cachePublic())
                .body(service.forCountry(countryCode));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> invalidCountry(IllegalArgumentException exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of(
                        "code", "COUNTRY_CODE_INVALID",
                        "message", "countryCode must be an ISO-3166 alpha-2 country code"));
    }
}
