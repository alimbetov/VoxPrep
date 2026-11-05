package io.github.alimbetov.voxprep.backend.installation.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AnonymousAuthenticationFilter;

@Configuration
public class InstallationSecurityConfiguration {

    @Bean
    PasswordEncoder adminPasswordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    UserDetailsService adminUserDetailsService(
            @Value("${voxprep.security.admin.username:admin}") String username,
            @Value("${voxprep.security.admin.password:}") String password,
            PasswordEncoder adminPasswordEncoder) {
        var admin = User.withUsername(username)
                .password(adminPasswordEncoder.encode(password == null ? "" : password))
                .roles("ADMIN")
                .disabled(password == null || password.isBlank())
                .build();
        return new InMemoryUserDetailsManager(admin);
    }

    @Bean
    @Order(1)
    SecurityFilterChain adminApiSecurityFilterChain(HttpSecurity http) throws Exception {
        http
                .securityMatcher("/admin/api/**")
                .csrf(AbstractHttpConfigurer::disable)
                .httpBasic(Customizer.withDefaults())
                .authorizeHttpRequests(authorize -> authorize.anyRequest().hasRole("ADMIN"));
        return http.build();
    }

    @Bean
    @Order(2)
    SecurityFilterChain adminMvcSecurityFilterChain(HttpSecurity http) throws Exception {
        http
                .securityMatcher("/admin/**", "/login", "/logout")
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers("/login").permitAll()
                        .anyRequest().hasRole("ADMIN"))
                .formLogin(login -> login.defaultSuccessUrl("/admin", false))
                .exceptionHandling(errors -> errors.accessDeniedHandler(new StudioAccessDeniedHandler()))
                .logout(Customizer.withDefaults());
        return http.build();
    }

    @Bean
    @Order(3)
    SecurityFilterChain installationSecurityFilterChain(
            HttpSecurity http,
            InstallationAuthenticationFilter installationAuthenticationFilter) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers(LearnerApiRoutePolicy::isProtected).authenticated()
                        .anyRequest().permitAll())
                .addFilterBefore(installationAuthenticationFilter, AnonymousAuthenticationFilter.class);
        return http.build();
    }
}
