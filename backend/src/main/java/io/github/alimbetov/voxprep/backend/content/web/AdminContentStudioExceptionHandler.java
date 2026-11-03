package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringNotFoundException;
import jakarta.persistence.OptimisticLockException;
import java.util.NoSuchElementException;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.ModelAndView;

@ControllerAdvice(annotations = AdminContentStudioMvc.class)
public class AdminContentStudioExceptionHandler {

    @ExceptionHandler({NoSuchElementException.class, CatalogueAuthoringNotFoundException.class})
    ModelAndView notFound(RuntimeException exception) {
        return error(HttpStatus.NOT_FOUND, "Not found", "The requested Content Studio resource does not exist.");
    }

    @ExceptionHandler({
            OptimisticLockingFailureException.class,
            OptimisticLockException.class,
            CatalogueAuthoringConflictException.class
    })
    ModelAndView conflict(RuntimeException exception) {
        return error(HttpStatus.CONFLICT, "Update conflict", "This item was changed by another operation. Reload and try again.");
    }

    private static ModelAndView error(HttpStatus status, String title, String message) {
        var modelAndView = new ModelAndView("admin/error");
        modelAndView.setStatus(status);
        modelAndView.addObject("activeSection", "");
        modelAndView.addObject("errorStatus", status.value());
        modelAndView.addObject("errorTitle", title);
        modelAndView.addObject("errorMessage", message);
        return modelAndView;
    }
}
