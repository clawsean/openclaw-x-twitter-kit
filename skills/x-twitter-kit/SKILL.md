---
name: x-twitter-kit
description: Use this when configuring, diagnosing, or operating layered X/Twitter access in OpenClaw: xurl OAuth1/OAuth2/bearer, direct X API bearer scripts, xAI x_search, bookmark access, or X posting safety.
---

# X/Twitter Kit

Use this skill to choose the correct X/Twitter transport/capability path and avoid mixing credentials, auth contexts, or safety rules.

## Capability-first routing

Pick the operation first, then choose the transport that can perform it safely:

- **Exact tweet URL read** → prefer `xurl`; use direct bearer only for deterministic scripts or when `xurl` is unavailable.
- **Search / timeline / mentions** → prefer `xurl` for account-aware live reads; use `x_search` for broad semantic discovery.
- **Bookmarks / likes / DMs / posting / replies** → require OAuth2 user context through `xurl`; verify the selected app before acting.
- **Repeated analysis / local memory** → use or add a local cache layer outside this kit. Do not keep spending live API reads when durable local state is available.
- **UI-only or API-tier gaps** → browser fallback, with explicit approval for any public/mutating action.

## Transport selection

1. **xurl (primary authenticated transport)**
   - Use for tweet URL reads, X search, bookmarks, timeline, likes/reposts/follows, media upload, posting/replies, and DMs.
   - Expected healthy state: `xurl auth status` shows an app with OAuth2 user, OAuth1 ✓ when configured, and bearer ✓ when configured.
   - Bookmarks require OAuth2 user context. If OAuth2 client registration lives under a non-default xurl app, use `xurl --app <oauth2-app> bookmarks` or set `XTK_BOOKMARK_APP` for the doctor.
   - Treat `xurl` as an adapter. Shell out to `xurl`; do not parse, mutate, upload, or take ownership of `~/.xurl`.

2. **Direct bearer API (deterministic script transport)**
   - Use for exact X API calls from scripts when structured JSON matters.
   - Fetch bearer tokens at runtime from a secret manager or env var. Never log Authorization headers.

3. **OpenClaw/xAI `x_search` (broad discovery transport)**
   - Use for semantic/broad discovery, thread/media-aware search, or when natural language beats X query syntax.
   - Not a replacement for bookmarks, account actions, or posting.

4. **Browser fallback (last resort)**
   - Use only for UI-only cases or API-tier blocks.
   - Public/mutating actions still need explicit approval.

## Safety rules

- Never read, print, summarize, upload, or send `~/.xurl` or copies of it into chat/context.
- Never ask users to paste tokens/secrets into chat.
- Do not use verbose API logging around OAuth or Authorization headers.
- Public/mutating actions require clear user intent and explicit approval unless there is a separate standing policy.
- Safe reads: tweet URL read, search, timeline/bookmark listing. Mutations: post, reply, delete, DM send, follow/unfollow, block/mute, bookmark add/remove.

## Diagnostics

Run the bundled doctor from the skill directory:

```bash
scripts/twitter-doctor.sh
```

Useful environment variables:

- `XTK_EXPECTED_X_USERNAME` — expected OAuth2 username in `xurl auth status`.
- `XTK_TEST_TWEET_URL` — public tweet URL for exact-read smoke test.
- `XTK_SEARCH_QUERY` — query for xurl search smoke test.
- `XTK_BOOKMARK_APP` — optional xurl app for OAuth2-only bookmark checks.
- `XTK_BEARER_OP_REF` — optional 1Password ref for legacy direct bearer check.
- `XTK_OPENCLAW_CONFIG` / `XTK_OPENCLAW_ENV` — optional OpenClaw config/env paths.

The doctor must not print secrets or bookmark contents.

## OAuth2 on a headless VPS

Use a public callback route instead of a local-browser tunnel when possible.

1. Configure X Developer app callback, e.g. `https://example.com/callback`.
2. Temporarily proxy that route to the VPS xurl listener on `127.0.0.1:8080`.
3. Run:

```bash
scripts/xurl-oauth2-auth.sh --app default --redirect-uri https://example.com/callback
```

4. Open the generated X auth URL and approve.
5. Verify with `xurl auth status` and `scripts/twitter-doctor.sh`.
6. Remove the temporary callback proxy unless immediate re-auth is expected.

Template files:

- `templates/Caddyfile.callback.example`
- `templates/privacy-policy-x-oauth.md`
- `templates/openclaw-xai-config.patch.json5`

## Common pitfall

`http://localhost:8080/callback` means the browser user's machine, not the VPS. On a headless VPS, either use an SSH tunnel deliberately or prefer a temporary public callback proxy.
