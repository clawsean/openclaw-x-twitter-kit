# Changelog

## Unreleased

- Prefer OpenClaw/xAI `x_search` through signed-in Grok OAuth auth profiles for ordinary X/Twitter search and research.
- Narrow xurl/direct bearer guidance to exact/account/structured X API work.
- Update the doctor to inspect xAI auth profiles and treat `XAI_API_KEY` as fallback auth.
- Add offline doctor capability tests for OAuth-primary routing, expired-token refresh smoke behavior, API-key fallback, xurl read/search/bookmark checks, direct bearer fallback, user mismatch failures, and non-mutating validation guardrails.
- Extend the offline matrix to cover malformed xAI auth JSON, missing OpenClaw config, partial OpenClaw config surfaces, xurl live read failure, direct bearer HTTP failure, and an API-key fallback secret-leak guard.

## v0.1.0 - 2026-05-23

Initial community-ready technical kit:

- OpenClaw skill for layered X/Twitter backend selection.
- Non-secret smoke doctor for xurl, direct bearer, and xAI auth checks.
- Headless OAuth2 helper for VPS/public-callback flows.
- Caddy callback, OpenClaw xAI config, and OAuth privacy-policy templates.
- Security, contribution, support, issue, PR, and CI scaffolding.
