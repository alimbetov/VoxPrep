package io.github.alimbetov.voxprep.backend.installation.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AnonymousAuthenticationFilter;

@Configuration
public class InstallationSecurityConfiguration {

    @Bean
    SecurityFilterChain installationSecurityFilterChain(
            HttpSecurity http,
            InstallationAuthenticationFilter installationAuthenticationFilter) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(authorize -> authorize.anyRequest().permitAll())
                .addFilterBefore(installationAuthenticationFilter, AnonymousAuthenticationFilter.class);
        return http.build();
    }
}
