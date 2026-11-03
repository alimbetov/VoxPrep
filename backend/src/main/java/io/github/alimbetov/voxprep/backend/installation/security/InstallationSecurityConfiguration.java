package io.github.alimbetov.voxprep.backend.installation.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AnonymousAuthenticationFilter;

@Configuration
public class InstallationSecurityConfiguration {

    @Bean
    UserDetailsService adminUserDetailsService(
            @Value("${voxprep.security.admin.username:admin}") String username,
            @Value("${voxprep.security.admin.password:}") String password) {
        var admin = User.withUsername(username)
                .password("{noop}" + password)
                .roles("ADMIN")
                .disabled(password == null || password.isBlank())
                .build();
        return new InMemoryUserDetailsManager(admin);
    }

    @Bean
    SecurityFilterChain installationSecurityFilterChain(
            HttpSecurity http,
            InstallationAuthenticationFilter installationAuthenticationFilter) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .httpBasic(Customizer.withDefaults())
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers("/admin/**").hasRole("ADMIN")
                        .anyRequest().permitAll())
                .addFilterBefore(installationAuthenticationFilter, AnonymousAuthenticationFilter.class);
        return http.build();
    }
}
