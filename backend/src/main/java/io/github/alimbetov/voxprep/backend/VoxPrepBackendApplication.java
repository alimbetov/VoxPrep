package io.github.alimbetov.voxprep.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class VoxPrepBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(VoxPrepBackendApplication.class, args);
    }
}
