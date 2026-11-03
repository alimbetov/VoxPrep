package io.github.alimbetov.voxprep.backend.installation.security;

public class InstallationAuthenticationException extends RuntimeException {

    private final String code;

    public InstallationAuthenticationException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
