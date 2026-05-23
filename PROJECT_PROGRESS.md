# openclaw-x-twitter-kit — PROJECT_PROGRESS

*Created: 2026-05-23*  
*Status: v0 scaffolded, locally smoke-tested, ready to publish*

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

## Validation

2026-05-23 local checks:

- `bash -n` passed for bundled scripts.
- Shareable `twitter-doctor.sh` passed locally with 12 passed / 0 warnings / 0 failed using environment overrides.
- Local source `projects/twitter-capabilities/scripts/twitter-doctor.sh` passed 11 / 0 / 0 after updating bookmark check to use the local OAuth2 app.
- Secret-ish grep passed for real tokens/callback codes.

## Important implementation note

Some xurl setups keep OAuth2 client registration separate from default OAuth1/bearer credentials. In our local setup, default read/search works through `default`, while OAuth2-only bookmark operations require `--app jpop-oauth2`. The kit supports this with `XTK_BOOKMARK_APP`.
