# openclaw-x-twitter-kit — PROJECT_PROGRESS

*Created: 2026-05-23*  
*Status: v0 published ✅*

## Purpose

Share the layered X/Twitter setup we built for OpenClaw:

1. xurl as primary authenticated lane.
2. Direct bearer API as deterministic script fallback.
3. xAI `x_search` as broad discovery lane.
4. Browser as last-resort fallback.

## Decisions

- Public repo under `clawSean/openclaw-x-twitter-kit`.
- OpenClaw-first, but scripts are generic enough for any VPS/agent setup.
- 1Password/env templates only; no committed secrets.
- v0 includes read/search/bookmarks, doctor, OAuth2 setup docs/templates.
- Mutating/public X actions stay approval-gated.
- Public callback/Caddy route is the recommended OAuth path; localhost/tunnel remains a fallback.

## Current contents

- `README.md`
- `SECURITY.md`
- `.env.example`
- `skills/x-twitter-kit/SKILL.md`
- `skills/x-twitter-kit/scripts/twitter-doctor.sh`
- `skills/x-twitter-kit/scripts/xurl-oauth2-auth.sh`
- Caddy, OpenClaw xAI, and privacy-policy templates.

## Publication

- GitHub: https://github.com/clawSean/openclaw-x-twitter-kit
- Visibility: public
- Initial commit: `8f6bbf8` — `Initial OpenClaw X Twitter kit`

## Validation

2026-05-23 local checks:

- `bash -n` passed for bundled scripts.
- Shareable `twitter-doctor.sh` passed locally with 12 passed / 0 warnings / 0 failed using environment overrides.
- Local source `projects/twitter-capabilities/scripts/twitter-doctor.sh` passed 11 / 0 / 0 after updating bookmark check to use the local OAuth2 app.
- Secret-ish grep passed for real tokens/callback codes.

## Important implementation note

Some xurl setups keep OAuth2 client registration separate from default OAuth1/bearer credentials. In our local setup, default read/search works through `default`, while OAuth2-only bookmark operations require `--app jpop-oauth2`. The kit supports this with `XTK_BOOKMARK_APP`.

## 2026-05-23 — Community polish pass

Research inputs: GitHub community health docs, GitHub security/repository-topic docs, X OAuth2 PKCE docs, npm xurl metadata, OpenClaw local skill docs, and a Perplexity checklist synthesis.

Implemented:

- Community files: `CONTRIBUTING.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md`, issue templates, PR template.
- CI: `.github/workflows/ci.yml` plus `scripts/ci-check.sh` for Bash syntax, ShellCheck, skill frontmatter, executable bits, secret-ish scan, and whitespace checks.
- Docs: `docs/openclaw-install.md`, `docs/oauth.md`, `docs/troubleshooting.md`, and `docs/community-polish-sources.md`.
- README expanded with audience, docs links, install path, safety model, CI badge, and validation commands.
- SECURITY expanded with reporting guidance, leak response, and project responsibility boundaries.

Validation after polish:

- `scripts/ci-check.sh` passed locally with ShellCheck installed.
- Live doctor passed locally with 12 passed / 0 warnings / 0 failed.
