package io.github.alimbetov.voxprep.backend.billing;

public class PurchaseEventReplayConflictException extends RuntimeException {
    public PurchaseEventReplayConflictException() {
        super("purchaseEventId cannot be reused with a different provider, product or proof");
    }
}
