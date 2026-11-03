package io.github.alimbetov.voxprep.backend.configuration.application;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;

/**
 * Public, non-identifying locale configuration for Flutter onboarding.
 *
 * <p>Country code is a user-selected preference, never inferred from an IP or
 * associated with an installation identifier. UI language and learning
 * content-language remain independent choices.
 */
@Service
public class CountryLocaleConfigurationService {

    private static final Set<String> ISO_COUNTRIES = Set.copyOf(Arrays.asList(Locale.getISOCountries()));

    /** Contractually supported translation locales; one canonical code per language. */
    private static final List<LocaleOption> LOCALES = List.of(
            new LocaleOption("en", "English"),
            new LocaleOption("ru", "Русский"),
            new LocaleOption("kk", "Қазақша"),
            new LocaleOption("es", "Español"),
            new LocaleOption("fr", "Français"),
            new LocaleOption("de", "Deutsch"),
            new LocaleOption("pt-BR", "Português (Brasil)"),
            new LocaleOption("zh-Hans", "简体中文"),
            new LocaleOption("ar", "العربية"),
            new LocaleOption("hi", "हिन्दी"),
            new LocaleOption("tr", "Türkçe"),
            new LocaleOption("ja", "日本語"));

    private static final Map<String, String> COUNTRY_DEFAULTS = Map.ofEntries(
            Map.entry("KZ", "kk"),
            Map.entry("RU", "ru"),
            Map.entry("ES", "es"),
            Map.entry("FR", "fr"),
            Map.entry("DE", "de"),
            Map.entry("BR", "pt-BR"),
            Map.entry("CN", "zh-Hans"),
            Map.entry("SA", "ar"),
            Map.entry("IN", "hi"),
            Map.entry("TR", "tr"),
            Map.entry("JP", "ja"));

    public CountryLocaleConfiguration forCountry(String countryCode) {
        if (countryCode == null
                || !countryCode.matches("[A-Z]{2}")
                || !ISO_COUNTRIES.contains(countryCode)) {
            throw new IllegalArgumentException("countryCode must be an ISO-3166 alpha-2 country code");
        }
        return new CountryLocaleConfiguration(
                countryCode, COUNTRY_DEFAULTS.getOrDefault(countryCode, "en"), LOCALES);
    }

    public record CountryLocaleConfiguration(
            String countryCode, String defaultLocale, List<LocaleOption> locales) {
        public CountryLocaleConfiguration {
            locales = List.copyOf(locales);
            if (locales.stream().noneMatch(option -> option.code().equals(defaultLocale))) {
                throw new IllegalArgumentException("default locale must be supported");
            }
        }
    }

    public record LocaleOption(String code, String label) {
    }
}
