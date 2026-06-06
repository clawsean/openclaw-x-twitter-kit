# openclaw-x-twitter-kit — PROJECT_PROGRESS

*Created: 2026-05-23*  
*Status: v0 published ✅*

## Purpose

Share the layered X/Twitter setup we built for OpenClaw:

1. xAI/Grok OAuth-backed `x_search` as the primary search/research lane.
2. xurl as primary authenticated account/action lane.
3. Direct bearer API as deterministic script fallback.
4. Browser as last-resort fallback.

## Decisions

- Public repo under `clawSean/openclaw-x-twitter-kit`.
- OpenClaw-first, but scripts are generic enough for any VPS/agent setup.
- 1Password/env templates only; no committed secrets.
- v0 includes read/search/bookmarks, doctor, OAuth2 setup docs/templates.
- Ordinary X search/research should prefer OpenClaw's signed-in xAI/Grok OAuth auth profile; `XAI_API_KEY` is fallback only.
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

## 2026-06-05 — Grok OAuth auth-profile search default

Prompted by JPop's Twitter API credit exhaustion and the successful Grok/X Premium OAuth proof, flipped the documented search default:

- Ordinary X/Twitter search, research, summaries, and cited discovery now prefer OpenClaw/xAI `x_search` through the signed-in xAI/Grok auth profile.
- `xurl` remains the primary account/action transport for exact tweet reads, timelines, bookmarks, posting/replies, likes/reposts, media, and DMs.
- Direct bearer API remains the deterministic script/structured JSON lane for exact fields, metrics, pagination, and compatibility scripts.
- The doctor now checks for an xAI OAuth auth profile with `openclaw models auth list --provider xai --json`, reports API-key auth as fallback, and runs a small Grok model smoke when OAuth is available.

## 2026-06-06 — Offline capability test matrix

Prompted by JPop asking whether the previous modes remained fallback-safe and whether coverage was enough for full capability confidence.

Implemented:

- Added `scripts/test.sh`, a fake-command offline matrix for `twitter-doctor.sh`.
- Covered xAI/Grok OAuth auth-profile primary routing with `XAI_API_KEY` forced empty.
- Covered expired/stale OAuth profile detection followed by model-smoke refresh behavior.
- Covered `XAI_API_KEY` fallback smoke when OAuth profiles are missing.
- Covered `xurl` exact tweet read, search, and bookmark checks with an alternate bookmark app.
- Covered direct bearer fallback via fake `op` and fake `curl` while asserting bearer values are not printed.
- Covered expected xurl OAuth2 username mismatch as a nonzero failure.
- Added a guard that validation never calls mutating xurl verbs: post, reply, like, repost, delete, follow/unfollow, DM, mute, or block.
- Wired `scripts/test.sh` into `scripts/ci-check.sh`.
- Extended the matrix with degraded-path coverage: malformed `openclaw models auth list` JSON, missing `openclaw.json`, partial OpenClaw config surfaces (xai plugin disabled, `x_search` not in `tools.alsoAllow`), `xurl read` live failure, direct bearer HTTP 500, and an API-key fallback secret-leak canary check.

Still intentionally not automated:

- Posting/replying/liking/reposting/deleting/following as JPop.
- Browser fallback UI automation.
- Live X API reads while the X developer account is credit-depleted.

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
- GitHub Actions CI passed on `d93dec8` and `3207679`.
- GitHub community profile reports 100% health.
- Discussions enabled; topics added: `openclaw`, `x-api`, `twitter-api`, `xurl`, `oauth2`, `agents`, `agent-skills`.

## 2026-05-26 — Capability/transport design clarification

Prompted by comparing adjacent local-first X tooling, clarified the kit's scope without adding new dependencies:

- Reframed docs from generic “backends/lanes” toward capability-first routing and transport selection.
- Documented `xurl` as an external adapter boundary: shell out to supported commands; do not inspect, mutate, upload, or own `~/.xurl`.
- Added a troubleshooting section for capability mismatches where auth is healthy but a specific surface still fails.
- Kept durable Twitter memory/cache layers explicitly outside this kit while leaving a clean companion-tool seam.

Validation:

- `scripts/ci-check.sh` passed locally.
- `openclaw skills check` passed with `search-twitter` still visible/eligible.
