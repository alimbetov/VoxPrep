package io.github.alimbetov.voxprep.backend.billing;

import com.apple.itunes.storekit.client.AppStoreServerAPIClient;
import com.apple.itunes.storekit.model.Environment;
import com.apple.itunes.storekit.model.Type;
import com.apple.itunes.storekit.verification.SignedDataVerifier;
import com.apple.itunes.storekit.verification.VerificationException;
import java.io.IOException;
import java.time.Instant;
import java.util.Objects;

/** Apple official Store Server API + verified signed JWS (not decoded unsigned JSON). */
public class AppleStoreVerifier {
    private final AppStoreServerAPIClient client;
    private final SignedDataVerifier signed;
    private final String productId;

    public AppleStoreVerifier(AppStoreServerAPIClient client,
                              SignedDataVerifier signed, String productId) {
        this.client=Objects.requireNonNull(client);
        this.signed=Objects.requireNonNull(signed);
        this.productId=Objects.requireNonNull(productId);
    }

    public StorePurchaseVerifier.StoreDecision verify(String transactionId) {
        if (transactionId == null || !transactionId.matches("[0-9]{1,40}")) {
            throw new IllegalArgumentException("Apple verificationData must be a StoreKit transaction ID");
        }
        try {
            return verifiedTransaction(
                    client.getTransactionInfo(transactionId).getSignedTransactionInfo(), transactionId);
        } catch (VerificationException ex) {
            throw new IllegalArgumentException("Invalid Apple signed Store transaction");
        } catch (IllegalArgumentException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new PurchaseVerificationUnavailableException();
        }
    }

    public StorePurchaseVerifier.StoreDecision verifiedTransaction(
            String signedTransaction, String expectedTransactionId) throws VerificationException {
        var purchase = signed.verifyAndDecodeTransaction(signedTransaction);
        if (!productId.equals(purchase.getProductId())
                || purchase.getType() != Type.NON_CONSUMABLE
                || purchase.getTransactionId() == null
                || (expectedTransactionId != null && !expectedTransactionId.equals(purchase.getTransactionId()))
                || purchase.getOriginalTransactionId() == null
                || purchase.getPurchaseDate() == null) {
            throw new IllegalArgumentException("Apple Store purchase identity invalid");
        }
        boolean revoked = purchase.getRevocationDate() != null;
        return new StorePurchaseVerifier.StoreDecision(
                "APP_STORE", productId,
                PurchaseDigest.sha256(purchase.getOriginalTransactionId()),
                revoked ? StorePurchaseVerifier.State.REVOKED : StorePurchaseVerifier.State.GRANTED,
                purchase.getEnvironment() == Environment.SANDBOX
                        ? StorePurchaseVerifier.Environment.SANDBOX
                        : StorePurchaseVerifier.Environment.PRODUCTION,
                revoked ? null : Instant.ofEpochMilli(purchase.getPurchaseDate()));
    }
}
