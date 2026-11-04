package io.github.alimbetov.voxprep.backend.billing;

import com.apple.itunes.storekit.client.AppStoreServerAPIClient;
import com.apple.itunes.storekit.model.Environment;
import com.apple.itunes.storekit.verification.SignedDataVerifier;
import com.google.auth.oauth2.GoogleCredentials;
import java.io.ByteArrayInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import tools.jackson.databind.ObjectMapper;

/**
 * Production starts ONLY when all Store credentials are mounted.
 * No simulations or local data can grant an entitlement in this mode.
 */
@Configuration
@EnableScheduling
@ConditionalOnProperty(prefix="voxprep.billing",name="mode",havingValue="production")
public class ProductionStorePurchaseConfiguration {

    @Bean
    GooglePlayStoreVerifier googlePlayStoreVerifier(
            @Value("${voxprep.billing.google.package-name:}") String packageName,
            ObjectMapper json) {
        try {
            var credentials = GoogleCredentials.getApplicationDefault().createScoped(
                    List.of("https://www.googleapis.com/auth/androidpublisher"));
            return new GooglePlayStoreVerifier(packageName, credentials, json);
        } catch (Exception ex) {
            throw new IllegalStateException("Google Play service account credentials are missing", ex);
        }
    }

    @Bean
    AppleStoreVerifier appleStoreVerifier(
            @Value("${voxprep.billing.apple.bundle-id:}") String bundle,
            @Value("${voxprep.billing.apple.app-apple-id:0}") long appAppleId,
            @Value("${voxprep.billing.apple.issuer-id:}") String issuer,
            @Value("${voxprep.billing.apple.key-id:}") String keyId,
            @Value("${voxprep.billing.apple.key-file:}") String keyFile,
            @Value("${voxprep.billing.apple.roots-dir:}") String rootsDir) {
        if (bundle.isBlank() || issuer.isBlank() || keyId.isBlank()
                || keyFile.isBlank() || rootsDir.isBlank() || appAppleId <= 0) {
            throw new IllegalStateException("Apple App Store production credentials are incomplete");
        }
        try {
            var rootPaths = Files.list(Path.of(rootsDir))
                    .filter(p -> p.getFileName().toString().endsWith(".cer"))
                    .sorted().toList();
            if (rootPaths.isEmpty()) throw new IllegalStateException("Apple root CA certificates missing");
            var certs = new java.util.HashSet<java.io.InputStream>();
            for (Path path : rootPaths) certs.add(new ByteArrayInputStream(Files.readAllBytes(path)));
            var client = new AppStoreServerAPIClient(
                    Files.readString(Path.of(keyFile)), keyId, issuer, bundle, Environment.PRODUCTION);
            var verifier = new SignedDataVerifier(certs, bundle, appAppleId,
                    Environment.PRODUCTION, true);
            return new AppleStoreVerifier(client, verifier, LifetimePurchaseService.PRODUCT_ID);
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot initialize verified App Store API", ex);
        }
    }

    @Bean
    StorePurchaseVerifier productionStorePurchaseVerifier(
            GooglePlayStoreVerifier google, AppleStoreVerifier apple) {
        return (provider,product,proof) -> switch (provider) {
            case "GOOGLE_PLAY" -> google.verify(product, proof);
            case "APP_STORE" -> apple.verify(proof);
            default -> throw new IllegalArgumentException("Unsupported store provider");
        };
    }
}
