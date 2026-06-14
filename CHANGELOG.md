# Changelog

## Unreleased

- Rename the public-facing docs title to "X/Twitter Kit" while keeping the
  searchable repository slug.
- Bundle Peeper as the no-credit known-account monitoring transport, including
  `scripts/peeper.mjs`, a cache fixture, doctor smoke coverage, and offline CI
  coverage that proves no X API, X OAuth, or xAI path is used.
- Add job-based routing guidance for known-account monitoring, broad X search,
  exact/account-aware reads, approved actions, and company/brand account
  separation.
- Prefer OpenClaw/xAI `x_search` through signed-in Grok OAuth auth profiles for ordinary X/Twitter search and research.
- Narrow xurl/direct bearer guidance to exact/account/structured X API work.
- Update the doctor to inspect xAI auth profiles and treat `XAI_API_KEY` as fallback auth.
- Add offline doctor capability tests for OAuth-primary routing, expired-token refresh smoke behavior, API-key fallback, xurl read/search/bookmark checks, direct bearer fallback, user mismatch failures, and non-mutating validation guardrails.
- Extend the offline matrix to cover malformed xAI auth JSON, missing OpenClaw config, partial OpenClaw config surfaces, xurl live read failure, direct bearer HTTP failure, and an API-key fallback secret-leak guard.
- Add an opt-in online non-mutating test runner for live xAI OAuth `x_search`, xurl read/search, optional bookmark listing, and optional direct bearer reads.
- Collapse the documented agent-facing model to one `x-twitter-kit` skill,
  with optional local `LOCAL_DEFAULTS.md` for host-specific profile names,
  secret refs, and standing policies. The bundled `xurl` skill remains a raw
  CLI mechanics dependency only.
- Add `VISION.md` and a local routing guide so operators can adapt the
  capability-first, spend-aware transport ladder without copying private
  workspace defaults.
- Make Peeper's default FxTwitter path fall back to the public syndication path
  before stale cache, preserving the no-credit monitoring lane during short
  public endpoint failures.

## v0.1.0 - 2026-05-23

Initial community-ready technical kit:

- OpenClaw skill for layered X/Twitter backend selection.
- Non-secret smoke doctor for xurl, direct bearer, and xAI auth checks.
- Headless OAuth2 helper for VPS/public-callback flows.
- Caddy callback, OpenClaw xAI config, and OAuth privacy-policy templates.
- Security, contribution, support, issue, PR, and CI scaffolding.
