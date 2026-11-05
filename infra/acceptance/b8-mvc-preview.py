#!/usr/bin/env python3
"""B8 A12: validate actual RustFS-backed Piper MP3 through admin MVC HTTP.

No fixture audio, storage shortcuts, or mocked auth. Only stdlib modules.
"""
import hashlib
import http.cookiejar
import os
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser


class CsrfParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.token = None

    def handle_starttag(self, tag, attrs):
        if tag != "input":
            return
        attrs = dict(attrs)
        if attrs.get("name") == "_csrf":
            self.token = attrs.get("value")


def main():
    base = os.environ["B8_BACKEND_URL"]
    revision = os.environ["B8_CONTENT_REVISION"]
    job_id = os.environ["B8_JOB_ID"]
    expected_hash = os.environ["B8_EXPECTED_SHA"]
    expected_size = int(os.environ["B8_EXPECTED_SIZE"])

    jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(jar)
    )
    preview = f"{base}/admin/content/revisions/{revision}/tts/jobs/{job_id}/preview"

    # Must deny unauthenticated media rather than leaking storage objects.
    request = urllib.request.Request(preview, headers={"Accept": "audio/mpeg"})
    with opener.open(request, timeout=15) as response:
        assert response.geturl().endswith("/login"), "anonymous preview must redirect to login"

    with opener.open(f"{base}/login", timeout=15) as response:
        parser = CsrfParser()
        parser.feed(response.read().decode("utf-8"))
    assert parser.token, "MVC login page did not provide CSRF token"

    credentials = urllib.parse.urlencode(
        {
            "username": os.environ["B8_ADMIN_USERNAME"],
            "password": os.environ["B8_ADMIN_PASSWORD"],
            "_csrf": parser.token,
        }
    ).encode("utf-8")
    with opener.open(
        urllib.request.Request(
            f"{base}/login",
            data=credentials,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        ),
        timeout=15,
    ) as response:
        assert not response.geturl().endswith("/login?error"), "admin login failed"

    with opener.open(request, timeout=30) as response:
        assert response.status == 200, f"MVC preview returned {response.status}"
        assert response.headers.get_content_type() == "audio/mpeg"
        assert "no-store" in response.headers.get("Cache-Control", "")
        actual = response.read()
    assert len(actual) == expected_size, "MVC MP3 size mismatch"
    assert hashlib.sha256(actual).hexdigest() == expected_hash, "MVC MP3 hash mismatch"

    wrong_revision = f"{base}/admin/content/revisions/00000000-0000-0000-0000-000000000000/tts/jobs/{job_id}/preview"
    try:
        opener.open(wrong_revision, timeout=15)
    except urllib.error.HTTPError as error:
        assert error.code == 404, f"cross-revision preview: HTTP {error.code}"
    else:
        raise AssertionError("cross-revision MP3 preview must be denied")

    print(f"A12 authenticated MVC audio verified: {len(actual)} bytes, exact sha256, denied cross-revision")


if __name__ == "__main__":
    main()
