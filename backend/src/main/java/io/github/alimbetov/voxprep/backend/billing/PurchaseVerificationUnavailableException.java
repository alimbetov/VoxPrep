package io.github.alimbetov.voxprep.backend.billing;

public class PurchaseVerificationUnavailableException extends RuntimeException {
    public PurchaseVerificationUnavailableException() {
        super("Store verification is temporarily unavailable");
    }
}
