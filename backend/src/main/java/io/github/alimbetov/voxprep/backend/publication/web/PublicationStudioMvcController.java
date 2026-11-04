package io.github.alimbetov.voxprep.backend.publication.web;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.web.AdminContentStudioMvc;
import io.github.alimbetov.voxprep.backend.publication.application.PublicationCandidateManifestService;
import io.github.alimbetov.voxprep.backend.publication.application.PublicationPublisher;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/**
 * Deliberately thin operator UI. Application publication validator and publisher
 * remain the sole authority for frozen manifests and CURRENT.
 */
@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/publication")
public class PublicationStudioMvcController {
    private final PublicationCandidateRepository candidates;
    private final PublicationCurrentRepository current;
    private final PublicationCandidateManifestService manifests;
    private final PublicationPublisher publisher;
    private final Clock clock = Clock.systemUTC();

    public PublicationStudioMvcController(PublicationCandidateRepository candidates,
            PublicationCurrentRepository current,
            PublicationCandidateManifestService manifests, PublicationPublisher publisher) {
        this.candidates = candidates;
        this.current = current;
        this.manifests = manifests;
        this.publisher = publisher;
    }

    @GetMapping
    public String index(Model model) {
        model.addAttribute("activeSection", "publication");
        model.addAttribute("candidates", candidates.findAll(
                PageRequest.of(0, 100, Sort.by(Sort.Direction.DESC, "createdAt"))).getContent());
        model.addAttribute("currentRelease", current.findById(PublicationCurrentEntity.SINGLETON_ID)
                .map(PublicationCurrentEntity::getRelease).orElse(null));
        return "admin/publication/index";
    }

    @PostMapping("/candidates")
    public String create(RedirectAttributes redirect) {
        var candidate = candidates.save(new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT));
        redirect.addFlashAttribute("flashSuccess", "Draft publication candidate created.");
        return "redirect:/admin/publication/candidates/" + candidate.getId();
    }

    @GetMapping("/candidates/{id}")
    public String candidate(@PathVariable UUID id, Model model) {
        var value = candidates.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Publication candidate not found"));
        model.addAttribute("activeSection", "publication");
        model.addAttribute("candidate", value);
        model.addAttribute("refs", manifests.loadFrozenManifest(id));
        return "admin/publication/candidate";
    }

    /**
     * One exact revision per line:
     * businessCode|contentTypeWireName|revisionNumber|sha256
     * No mutation occurs on invalid manifests; the existing validator is authoritative.
     */
    @PostMapping("/candidates/{id}/validate")
    public String validate(@PathVariable UUID id, @RequestParam String exactRefs,
            RedirectAttributes redirect) {
        if (exactRefs == null || exactRefs.length() > 65536) {
            throw new IllegalArgumentException("Publication manifest too large");
        }
        var refs = parseRefs(exactRefs);
        var result = manifests.validateAndFreeze(id, refs, clock.instant());
        if (!result.valid()) {
            redirect.addFlashAttribute("flashError", "Publication validation failed: "
                    + result.issues().stream().limit(5)
                            .map(issue -> issue.code().name() + " " + issue.refKey()).toList());
        } else {
            redirect.addFlashAttribute("flashSuccess", "Validated immutable candidate root: " + result.rootSha256());
        }
        return "redirect:/admin/publication/candidates/" + id;
    }

    @PostMapping("/candidates/{id}/publish")
    public String publish(@PathVariable UUID id, RedirectAttributes redirect) {
        var result = publisher.publish(id, clock.instant());
        redirect.addFlashAttribute("flashSuccess",
                "CURRENT publication v" + result.contentVersion() + ", SHA-256 " + result.rootSha256());
        return "redirect:/admin/publication";
    }

    static List<PublicationExactContentRef> parseRefs(String source) {
        List<PublicationExactContentRef> refs = new ArrayList<>();
        for (String raw : source.split("\\R", -1)) {
            String line = raw.strip();
            if (line.isEmpty()) continue;
            if (refs.size() >= 500) throw new IllegalArgumentException("Too many publication references");
            String[] fields = line.split("\\|", -1);
            if (fields.length != 4) throw new IllegalArgumentException("Expected 4 fields per manifest line");
            refs.add(new PublicationExactContentRef(
                    new ContentRevisionIdentity(new BusinessCode(fields[0].strip()),
                            ContentType.fromWireName(fields[1].strip()),
                            new RevisionNumber(Integer.parseInt(fields[2].strip()))),
                    new Sha256Digest(fields[3].strip())));
        }
        return List.copyOf(refs);
    }
}
