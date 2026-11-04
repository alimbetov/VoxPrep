package io.github.alimbetov.voxprep.backend.catalogue.web.mvc;

import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAdminQueryService;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringService;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueSnapshot;
import io.github.alimbetov.voxprep.backend.content.web.AdminContentStudioMvc;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/catalogue")
public class CatalogueMvcController {

    private final CatalogueAuthoringService authoring;
    private final CatalogueAdminQueryService query;
    private final CatalogueMvcMapper mapper;

    public CatalogueMvcController(
            CatalogueAuthoringService authoring,
            CatalogueAdminQueryService query,
            CatalogueMvcMapper mapper) {
        this.authoring = authoring;
        this.query = query;
        this.mapper = mapper;
    }

    @GetMapping
    public String index(
            @RequestParam(required = false) UUID verticalId,
            @RequestParam(required = false) UUID goalId,
            @RequestParam(required = false) UUID trackId,
            Model model) {
        var selection = canonicalSelection(verticalId, goalId, trackId);
        model.addAttribute("activeSection", "catalogue");
        model.addAttribute("verticals", query.listVerticals());
        model.addAttribute("selectedVerticalId", selection.verticalId());
        model.addAttribute("selectedGoalId", selection.goalId());
        model.addAttribute("selectedTrackId", selection.trackId());

        List<CatalogueSnapshot> goals = selection.verticalId() == null
                ? List.of()
                : query.listGoals(selection.verticalId());
        List<CatalogueSnapshot> tracks = selection.goalId() == null
                ? List.of()
                : query.listTracks(selection.goalId());
        List<CatalogueSnapshot> collections = selection.trackId() == null
                ? List.of()
                : query.listCollections(selection.trackId());
        model.addAttribute("goals", goals);
        model.addAttribute("tracks", tracks);
        model.addAttribute("collections", collections);
        return "admin/catalogue/index";
    }

    @GetMapping("/verticals/new")
    public String newVertical(Model model) {
        return form(model, "VERTICAL", "Create vertical", "/admin/catalogue/verticals", new CatalogueMvcForms.VerticalForm(), false, null);
    }

    @PostMapping("/verticals")
    public String createVertical(
            @Valid @ModelAttribute("form") CatalogueMvcForms.VerticalForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        if (binding.hasErrors()) {
            return form(model, "VERTICAL", "Create vertical", "/admin/catalogue/verticals", form, false, null);
        }
        var created = authoring.createVertical(
                mapper.code(form.getCode()), mapper.code(form.getSectionCode()), form.getTitle(), form.getDescription(),
                form.getIconAssetId(), form.getSortOrder(), mapper.availability(form.getAvailability()));
        redirect.addFlashAttribute("flashSuccess", "Vertical created.");
        return catalogueRedirect(created.getId(), null, null);
    }

    @GetMapping("/verticals/{id}/edit")
    public String editVertical(@PathVariable UUID id, Model model) {
        return form(model, "VERTICAL", "Edit vertical", "/admin/catalogue/verticals/" + id,
                mapper.toVerticalForm(query.getVertical(id)), true, null);
    }

    @PostMapping("/verticals/{id}")
    public String updateVertical(
            @PathVariable UUID id,
            @Valid @ModelAttribute("form") CatalogueMvcForms.VerticalForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        if (binding.hasErrors()) {
            return form(model, "VERTICAL", "Edit vertical", "/admin/catalogue/verticals/" + id, form, true, null);
        }
        authoring.updateVertical(id, form.getExpectedVersion(), mapper.code(form.getSectionCode()), form.getTitle(),
                form.getDescription(), form.getIconAssetId(), form.getSortOrder(), mapper.availability(form.getAvailability()));
        redirect.addFlashAttribute("flashSuccess", "Vertical updated.");
        return catalogueRedirect(id, null, null);
    }

    @GetMapping("/goals/new")
    public String newGoal(@RequestParam UUID verticalId, Model model) {
        var parent = query.getVertical(verticalId);
        var form = new CatalogueMvcForms.GoalForm();
        form.setVerticalId(verticalId);
        return form(model, "GOAL", "Create goal", "/admin/catalogue/goals", form, false, parent);
    }

    @PostMapping("/goals")
    public String createGoal(
            @Valid @ModelAttribute("form") CatalogueMvcForms.GoalForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var parent = form.getVerticalId() == null ? null : query.getVertical(form.getVerticalId());
        if (binding.hasErrors()) {
            return form(model, "GOAL", "Create goal", "/admin/catalogue/goals", form, false, parent);
        }
        var created = authoring.createGoal(mapper.code(form.getCode()), form.getVerticalId(), form.getTitle(),
                form.getDescription(), form.getSortOrder(), mapper.availability(form.getAvailability()));
        redirect.addFlashAttribute("flashSuccess", "Goal created.");
        return catalogueRedirect(form.getVerticalId(), created.getId(), null);
    }

    @GetMapping("/goals/{id}/edit")
    public String editGoal(@PathVariable UUID id, Model model) {
        var snapshot = query.getGoal(id);
        return form(model, "GOAL", "Edit goal", "/admin/catalogue/goals/" + id,
                mapper.toGoalForm(snapshot), true, query.getVertical(snapshot.parentId()));
    }

    @PostMapping("/goals/{id}")
    public String updateGoal(
            @PathVariable UUID id,
            @Valid @ModelAttribute("form") CatalogueMvcForms.GoalForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var snapshot = query.getGoal(id);
        var parent = query.getVertical(snapshot.parentId());
        if (binding.hasErrors()) {
            return form(model, "GOAL", "Edit goal", "/admin/catalogue/goals/" + id, form, true, parent);
        }
        authoring.updateGoal(id, form.getExpectedVersion(), form.getVerticalId(), form.getTitle(), form.getDescription(),
                form.getSortOrder(), mapper.availability(form.getAvailability()));
        redirect.addFlashAttribute("flashSuccess", "Goal updated.");
        return catalogueRedirect(snapshot.parentId(), id, null);
    }

    @GetMapping("/tracks/new")
    public String newTrack(@RequestParam UUID goalId, Model model) {
        var parent = query.getGoal(goalId);
        var form = new CatalogueMvcForms.TrackForm();
        form.setGoalId(goalId);
        return form(model, "TRACK", "Create track", "/admin/catalogue/tracks", form, false, parent);
    }

    @PostMapping("/tracks")
    public String createTrack(
            @Valid @ModelAttribute("form") CatalogueMvcForms.TrackForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var parent = form.getGoalId() == null ? null : query.getGoal(form.getGoalId());
        if (binding.hasErrors()) {
            return form(model, "TRACK", "Create track", "/admin/catalogue/tracks", form, false, parent);
        }
        var created = authoring.createTrack(mapper.code(form.getCode()), form.getGoalId(), form.getTitle(),
                form.getDescription(), mapper.code(form.getLevelCode()), mapper.optionalCode(form.getCareerTrackCode()),
                form.getSortOrder(), mapper.availability(form.getAvailability()));
        redirect.addFlashAttribute("flashSuccess", "Track created.");
        return catalogueRedirect(parent.parentId(), form.getGoalId(), created.getId());
    }

    @GetMapping("/tracks/{id}/edit")
    public String editTrack(@PathVariable UUID id, Model model) {
        var snapshot = query.getTrack(id);
        return form(model, "TRACK", "Edit track", "/admin/catalogue/tracks/" + id,
                mapper.toTrackForm(snapshot), true, query.getGoal(snapshot.parentId()));
    }

    @PostMapping("/tracks/{id}")
    public String updateTrack(
            @PathVariable UUID id,
            @Valid @ModelAttribute("form") CatalogueMvcForms.TrackForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var snapshot = query.getTrack(id);
        var parent = query.getGoal(snapshot.parentId());
        if (binding.hasErrors()) {
            return form(model, "TRACK", "Edit track", "/admin/catalogue/tracks/" + id, form, true, parent);
        }
        authoring.updateTrack(id, form.getExpectedVersion(), form.getGoalId(), form.getTitle(), form.getDescription(),
                mapper.code(form.getLevelCode()), mapper.optionalCode(form.getCareerTrackCode()), form.getSortOrder(),
                mapper.availability(form.getAvailability()));
        redirect.addFlashAttribute("flashSuccess", "Track updated.");
        return catalogueRedirect(parent.parentId(), snapshot.parentId(), id);
    }

    @GetMapping("/collections/new")
    public String newCollection(@RequestParam UUID trackId, Model model) {
        var parent = query.getTrack(trackId);
        var form = new CatalogueMvcForms.CollectionForm();
        form.setTrackId(trackId);
        return form(model, "COLLECTION", "Create collection", "/admin/catalogue/collections", form, false, parent);
    }

    @PostMapping("/collections")
    public String createCollection(
            @Valid @ModelAttribute("form") CatalogueMvcForms.CollectionForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var parent = form.getTrackId() == null ? null : query.getTrack(form.getTrackId());
        if (binding.hasErrors()) {
            return form(model, "COLLECTION", "Create collection", "/admin/catalogue/collections", form, false, parent);
        }
        var created = authoring.createCollection(mapper.code(form.getCode()), form.getTrackId(), form.getTitle(),
                form.getDescription(), mapper.accessLevel(form.getAccessLevel()), form.getSortOrder(),
                mapper.availability(form.getAvailability()));
        redirect.addFlashAttribute("flashSuccess", "Collection created.");
        return redirectToTrack(form.getTrackId());
    }

    @GetMapping("/collections/{id}/edit")
    public String editCollection(@PathVariable UUID id, Model model) {
        var snapshot = query.getCollection(id);
        model.addAttribute("collectionMembersUrl", "/admin/catalogue/collections/" + id + "/members");
        return form(model, "COLLECTION", "Edit collection", "/admin/catalogue/collections/" + id,
                mapper.toCollectionForm(snapshot), true, query.getTrack(snapshot.parentId()));
    }

    @PostMapping("/collections/{id}")
    public String updateCollection(
            @PathVariable UUID id,
            @Valid @ModelAttribute("form") CatalogueMvcForms.CollectionForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var snapshot = query.getCollection(id);
        var parent = query.getTrack(snapshot.parentId());
        if (binding.hasErrors()) {
            return form(model, "COLLECTION", "Edit collection", "/admin/catalogue/collections/" + id, form, true, parent);
        }
        authoring.updateCollection(id, form.getExpectedVersion(), form.getTrackId(), form.getTitle(), form.getDescription(),
                mapper.accessLevel(form.getAccessLevel()), form.getSortOrder(), mapper.availability(form.getAvailability()));
        redirect.addFlashAttribute("flashSuccess", "Collection updated.");
        return redirectToTrack(snapshot.parentId());
    }

    private CatalogueSelection canonicalSelection(UUID verticalId, UUID goalId, UUID trackId) {
        if (trackId != null) {
            var track = query.getTrack(trackId);
            var goal = query.getGoal(track.parentId());
            return new CatalogueSelection(goal.parentId(), goal.id(), track.id());
        }
        if (goalId != null) {
            var goal = query.getGoal(goalId);
            return new CatalogueSelection(goal.parentId(), goal.id(), null);
        }
        if (verticalId != null) {
            var vertical = query.getVertical(verticalId);
            return new CatalogueSelection(vertical.id(), null, null);
        }
        return new CatalogueSelection(null, null, null);
    }

    private String redirectToTrack(UUID trackId) {
        var track = query.getTrack(trackId);
        var goal = query.getGoal(track.parentId());
        return catalogueRedirect(goal.parentId(), goal.id(), track.id());
    }

    private static String catalogueRedirect(UUID verticalId, UUID goalId, UUID trackId) {
        var redirect = new StringBuilder("redirect:/admin/catalogue");
        String separator = "?";
        if (verticalId != null) {
            redirect.append(separator).append("verticalId=").append(verticalId);
            separator = "&";
        }
        if (goalId != null) {
            redirect.append(separator).append("goalId=").append(goalId);
            separator = "&";
        }
        if (trackId != null) {
            redirect.append(separator).append("trackId=").append(trackId);
        }
        return redirect.toString();
    }

    private static String form(
            Model model,
            String formType,
            String title,
            String action,
            Object form,
            boolean editing,
            CatalogueSnapshot parent) {
        model.addAttribute("activeSection", "catalogue");
        model.addAttribute("formType", formType);
        model.addAttribute("formTitle", title);
        model.addAttribute("formAction", action);
        model.addAttribute("form", form);
        model.addAttribute("editing", editing);
        model.addAttribute("parent", parent);
        return "admin/catalogue/form";
    }

    private record CatalogueSelection(UUID verticalId, UUID goalId, UUID trackId) {}
}
