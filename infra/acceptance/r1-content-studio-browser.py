#!/usr/bin/env python3
"""R1 real-browser evidence against the live Spring Boot MVC application.

Uses Chromium + Playwright and authenticates through /login. Credentials are
provided only through environment variables; screenshots are taken after login
and never show the login page or expose session cookies.
"""
import os
from pathlib import Path

from playwright.sync_api import sync_playwright


def required(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        raise RuntimeError(f"R1 browser evidence needs {name}")
    return value


base = required("VOXPREP_R1_BASE_URL").rstrip("/")
username = required("VOXPREP_R1_ADMIN_USERNAME")
password = required("VOXPREP_R1_ADMIN_PASSWORD")
revision = required("VOXPREP_R1_REVISION_ID")
stage = required("VOXPREP_R1_STAGE")
output = Path(required("VOXPREP_R1_OUTPUT_DIR"))
output.mkdir(parents=True, exist_ok=True)

with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True, args=["--no-sandbox"])
    context = browser.new_context(viewport={"width": 1440, "height": 1000},
                                  device_scale_factor=1)
    page = context.new_page()
    page.goto(f"{base}/login", wait_until="domcontentloaded")
    page.locator('input[name="username"]').fill(username)
    page.locator('input[name="password"]').fill(password)
    page.locator('input[name="password"]').press("Enter")
    page.wait_for_load_state("domcontentloaded")

    page.goto(f"{base}/admin/content/revisions/{revision}/edit",
              wait_until="domcontentloaded")
    if stage == "draft":
        assert "DRAFT" in page.locator("body").inner_text(), "Draft MVC status missing"
        page.screenshot(path=str(output / "01-content-draft.png"), full_page=True)
    elif stage == "approved":
        assert "APPROVED" in page.locator("body").inner_text(), "Approved MVC status missing"
        page.screenshot(path=str(output / "02-content-approved.png"), full_page=True)
    elif stage == "current":
        page.goto(f"{base}/admin/publication", wait_until="domcontentloaded")
        assert "Current learner release" in page.locator("body").inner_text(), "CURRENT missing"
        page.screenshot(path=str(output / "03-publication-current.png"), full_page=True)
    else:
        raise RuntimeError(f"Unexpected R1 screenshot stage: {stage}")
    context.close()
    browser.close()
