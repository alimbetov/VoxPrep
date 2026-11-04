package io.github.alimbetov.voxprep.backend.catalogue.web.mvc;

import io.github.alimbetov.voxprep.backend.catalogue.application.CollectionMembershipRevisionService;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionRepository;
import io.github.alimbetov.voxprep.backend.content.web.AdminContentStudioMvc;
import io.github.alimbetov.voxprep.backend.content.application.ContentAdminQueryService;
import java.util.UUID;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/** Operator action; no JSON API bypasses session authentication or CSRF. */
@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/catalogue/collections/{collectionId}/members")
public class CollectionMembershipMvcController {
    private final LearningCollectionRepository collections;
    private final CollectionContentMemberRepository members;
    private final CollectionMembershipRevisionService membership;
    private final ContentAdminQueryService contentQuery;

    public CollectionMembershipMvcController(LearningCollectionRepository collections,
            CollectionContentMemberRepository members, CollectionMembershipRevisionService membership,
            ContentAdminQueryService contentQuery) {
        this.collections = collections;
        this.members = members;
        this.membership = membership;
        this.contentQuery = contentQuery;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public String index(@PathVariable UUID collectionId,
            @RequestParam(defaultValue = "") String q,
            @RequestParam(defaultValue = "0") int page, Model model) {
        var collection = collections.findById(collectionId)
                .orElseThrow(() -> new IllegalArgumentException("Collection not found"));
        model.addAttribute("activeSection", "catalogue");
        model.addAttribute("collectionCode", collection.getCode().value());
        model.addAttribute("collectionId", collectionId);
        model.addAttribute("approvedCandidates", contentQuery.approvedCandidates(q, page));
        model.addAttribute("candidateQuery", q);
        model.addAttribute("members", members.findAllByCollectionIdOrderByPositionAsc(collectionId).stream()
                .map(member -> new MemberView(member.getId(), member.getPosition(),
                        member.getContentRevision().getContentCode().value(),
                        member.getContentRevision().getRevisionNumber().value()))
                .toList());
        return "admin/catalogue/members";
    }

    @PostMapping
    public String append(@PathVariable UUID collectionId,
            @RequestParam UUID revisionId, RedirectAttributes redirect) {
        membership.append(collectionId, revisionId);
        redirect.addFlashAttribute("flashSuccess", "Approved content added to collection.");
        return "redirect:/admin/catalogue/collections/" + collectionId + "/members";
    }

    @PostMapping("/{memberId}/replace")
    public String replace(@PathVariable UUID collectionId, @PathVariable UUID memberId,
            @RequestParam UUID newRevisionId, RedirectAttributes redirect) {
        membership.replace(collectionId, memberId, newRevisionId);
        redirect.addFlashAttribute("flashSuccess", "Collection member now references new approved revision.");
        return "redirect:/admin/catalogue/collections/" + collectionId + "/members";
    }

    public record MemberView(UUID id, int position, String code, int revision) {}
}
