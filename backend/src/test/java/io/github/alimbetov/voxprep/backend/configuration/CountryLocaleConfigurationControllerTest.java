package io.github.alimbetov.voxprep.backend.configuration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import io.github.alimbetov.voxprep.backend.configuration.application.CountryLocaleConfigurationService;
import io.github.alimbetov.voxprep.backend.configuration.web.CountryLocaleConfigurationController;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class CountryLocaleConfigurationControllerTest {

    private final CountryLocaleConfigurationService service = new CountryLocaleConfigurationService();

    @Test
    void kazakhstanOffersAllTwelveSupportedLocalesAndUsesKazakhDefault() throws Exception {
        var value = service.forCountry("KZ");
        assertThat(value.countryCode()).isEqualTo("KZ");
        assertThat(value.defaultLocale()).isEqualTo("kk");
        assertThat(value.locales()).hasSize(12);
        assertThat(value.locales().stream().map(CountryLocaleConfigurationService.LocaleOption::code))
                .containsExactly("en", "ru", "kk", "es", "fr", "de", "pt-BR",
                        "zh-Hans", "ar", "hi", "tr", "ja");

        var mvc = MockMvcBuilders.standaloneSetup(
                new CountryLocaleConfigurationController(service)).build();
        mvc.perform(get("/api/v1/configuration/locales").param("countryCode", "KZ"))
                .andExpect(status().isOk())
                .andExpect(header().exists("Cache-Control"))
                .andExpect(jsonPath("$.countryCode").value("KZ"))
                .andExpect(jsonPath("$.defaultLocale").value("kk"))
                .andExpect(jsonPath("$.locales.length()").value(12))
                .andExpect(jsonPath("$.locales[6].code").value("pt-BR"))
                .andExpect(jsonPath("$.locales[7].code").value("zh-Hans"))
                .andExpect(jsonPath("$.locales[11].label").value("日本語"))
                .andExpect(jsonPath("$.locales[0].code").value("en"));
    }

    @Test
    void countryPreferenceDoesNotRemoveOtherLocales() {
        assertThat(service.forCountry("BR").defaultLocale()).isEqualTo("pt-BR");
        assertThat(service.forCountry("CN").defaultLocale()).isEqualTo("zh-Hans");
        assertThat(service.forCountry("JP").defaultLocale()).isEqualTo("ja");
        assertThat(service.forCountry("US").defaultLocale()).isEqualTo("en");
        assertThat(service.forCountry("US").locales()).hasSize(12);
    }

    @Test
    void invalidAndUnknownCountriesFailWithTypedHttp400() throws Exception {
        var mvc = MockMvcBuilders.standaloneSetup(
                new CountryLocaleConfigurationController(service)).build();
        for (String country : List.of("KAZ", "ZZ", "kz", "00")) {
            mvc.perform(get("/api/v1/configuration/locales").param("countryCode", country))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("COUNTRY_CODE_INVALID"));
        }
        mvc.perform(get("/api/v1/configuration/locales"))
                .andExpect(status().isBadRequest());
        assertThatThrownBy(() -> service.forCountry(null))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
