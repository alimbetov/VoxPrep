package io.github.alimbetov.voxprep.backend.installation.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.security.web.csrf.CsrfException;

/** Keep the security rejection, but give expired browser forms a recovery path. */
final class StudioAccessDeniedHandler implements AccessDeniedHandler {
    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
            AccessDeniedException exception) throws IOException {
        boolean expiredForm = exception instanceof CsrfException;
        String title = expiredForm ? "This form has expired" : "Access denied";
        String message = expiredForm
                ? "Your changes were not saved. Open Content Studio, sign in if needed, and reopen the form before submitting."
                : "Your account does not have permission for this action. Sign in with an authorized account.";
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("text/html");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setHeader("Cache-Control", "no-store");
        response.setHeader("X-Content-Type-Options", "nosniff");
        // Only fixed messages/paths, no request, credential or exception reflection.
        response.getWriter().write("""
                <!doctype html><html lang="en"><head><meta charset="utf-8">
                <meta name="viewport" content="width=device-width,initial-scale=1">
                <title>%s · VoxPrep Content Studio</title>
                <style>body{font:17px system-ui,sans-serif;margin:8vh auto;padding:24px;max-width:640px;color:#20242b}
                a{display:inline-block;margin:12px 18px 0 0;color:#175ac6}p{line-height:1.6}</style></head>
                <body><main><p>VoxPrep Content Studio · 403</p><h1>%s</h1><p>%s</p>
                <a href="/admin">Open Content Studio</a><a href="/login">Sign in again</a>
                </main></body></html>
                """.formatted(title, title, message));
    }
}
