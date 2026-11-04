package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PublicationCandidateValidator {

    private final PublicationExactContentResolver resolver;
    private final PublicationMediaValidator mediaValidator;

    public PublicationCandidateValidator(PublicationExactContentResolver resolver) {
        this(resolver, PublicationMediaValidator.noOp());
    }

    @Autowired
    public PublicationCandidateValidator(
            PublicationExactContentResolver resolver,
            PublicationMediaValidator mediaValidator) {
        this.resolver = Objects.requireNonNull(resolver, "resolver");
        this.mediaValidator = Objects.requireNonNull(mediaValidator, "mediaValidator");
    }

    public PublicationValidationResult validate(List<PublicationExactContentRef> refs) {
        Objects.requireNonNull(refs, "refs");
        List<PublicationExactContentRef> ordered = refs.stream().sorted().toList();
        List<String> canonicalRefs = ordered.stream().map(PublicationExactContentRef::canonicalKey).toList();
        List<PublicationValidationIssue> issues = new ArrayList<>();

        if (ordered.isEmpty()) {
            issues.add(new PublicationValidationIssue(
                    PublicationValidationCode.EMPTY_CANDIDATE, "", "candidate contains no content refs"));
        }

        Map<String, Integer> identityCounts = new HashMap<>();
        ordered.forEach(ref -> identityCounts.merge(ref.identityKey(), 1, Integer::sum));
        identityCounts.entrySet().stream()
                .filter(entry -> entry.getValue() > 1)
                .sorted(Map.Entry.comparingByKey())
                .forEach(entry -> issues.add(new PublicationValidationIssue(
                        PublicationValidationCode.DUPLICATE_REF,
                        entry.getKey(),
                        "exact content identity occurs " + entry.getValue() + " times")));

        for (PublicationExactContentRef ref : ordered) {
            if (identityCounts.get(ref.identityKey()) > 1) {
                continue;
            }
            resolver.resolveExact(ref.identity()).ifPresentOrElse(resolved -> {
                if (!resolved.identity().equals(ref.identity())) {
                    throw new IllegalStateException("exact resolver returned a different identity");
                }
                if (!resolved.checksum().equals(ref.checksum())) {
                    issues.add(new PublicationValidationIssue(
                            PublicationValidationCode.CHECKSUM_MISMATCH,
                            ref.identityKey(),
                            "expected=" + ref.checksum().value() + ", actual=" + resolved.checksum().value()));
                }
                if (resolved.lifecycle() != ContentLifecycleStatus.APPROVED
                        && resolved.lifecycle() != ContentLifecycleStatus.PUBLISHED) {
                    issues.add(new PublicationValidationIssue(
                            PublicationValidationCode.NOT_PUBLISHABLE,
                            ref.identityKey(),
                            "lifecycle=" + resolved.lifecycle().name()));
                }
                if (resolved.checksum().equals(ref.checksum())
                        && (resolved.lifecycle() == ContentLifecycleStatus.APPROVED
                        || resolved.lifecycle() == ContentLifecycleStatus.PUBLISHED)) {
                    issues.addAll(mediaValidator.validate(ref));
                }
            }, () -> issues.add(new PublicationValidationIssue(
                    PublicationValidationCode.MISSING_REVISION,
                    ref.identityKey(),
                    "exact revision does not exist")));
        }

        issues.sort(PublicationValidationIssue::compareTo);
        boolean hasErrors = issues.stream()
                .anyMatch(issue -> issue.severity() == PublicationValidationSeverity.ERROR);
        return new PublicationValidationResult(
                canonicalRefs,
                issues,
                hasErrors ? null : digest(canonicalRefs));
    }

    private static String digest(List<String> canonicalRefs) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            canonicalRefs.forEach(ref -> {
                digest.update(ref.getBytes(StandardCharsets.UTF_8));
                digest.update((byte) '\n');
            });
            return HexFormat.of().formatHex(digest.digest());
        } catch (NoSuchAlgorithmException impossible) {
            throw new IllegalStateException("SHA-256 is unavailable", impossible);
        }
    }
}
