# OpenClaw X/Twitter Kit

[![CI](https://github.com/clawSean/openclaw-x-twitter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/clawSean/openclaw-x-twitter-kit/actions/workflows/ci.yml)

A small OpenClaw-first helper skill + scripts for dependable X/Twitter access using layered transports and capability checks:

1. **OpenClaw xAI `x_search`** — preferred X search/research transport, using signed-in Grok/xAI OAuth auth profiles when available.
2. **xurl** — primary authenticated X account transport for tweet reads, bookmarks, timeline, media, and user actions.
3. **Direct bearer API** — deterministic script/API transport for exact X API calls, metrics, pagination, and compatibility scripts.
4. **Browser fallback** — last resort for UI-only cases or API-tier blocks.

The kit is designed to be shareable: it ships no secrets and should work for any OpenClaw/VPS user who brings their own X Developer app and credentials.

## Who this is for

- OpenClaw operators who want X/Twitter read/search/bookmark capability.
- Agent builders who need a repeatable OAuth2/xurl setup path.
- Technical friends who can bring their own X Developer app, callback URL, and credentials.

This is a **technical v0 kit**, not a hosted service or one-click consumer installer.

## Design stance

- Route by **capability** first: exact tweet read, search, bookmarks, DMs, posting, media, or broad discovery may require different auth contexts.
- For ordinary "search Twitter/X", research, summaries, and cited discovery, prefer OpenClaw/xAI `x_search` through the signed-in xAI/Grok auth profile. Do not spend X API credits or reach for an xAI API-key fallback unless OAuth is unavailable.
- Treat `xurl` as an external credential adapter. This kit shells out to `xurl`; it does **not** parse, mutate, upload, or own `~/.xurl`.
- Keep durable Twitter memory/cache layers outside this kit. Pair with local-first tools when you need repeated analysis without repeated live API reads.
- Keep public/mutating actions approval-gated even when auth is healthy.

## Contents

```text
skills/x-twitter-kit/
├── SKILL.md
├── scripts/
│   ├── twitter-doctor.sh
│   └── xurl-oauth2-auth.sh
└── templates/
    ├── Caddyfile.callback.example
    ├── openclaw-xai-config.patch.json5
    └── privacy-policy-x-oauth.md
```

Additional docs:

- [OpenClaw install notes](docs/openclaw-install.md)
- [X OAuth setup notes](docs/oauth.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Security policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)

## Quick start

1. Install `xurl`:

   ```bash
   npm install -g @xdevplatform/xurl
   ```

2. Create/configure an X Developer app:

   - App type: **Web App / Automated App / Bot**
   - Permissions: **Read + Write + DM** if you need bookmarks, posting, and DMs
   - Callback URL: your public callback route, e.g. `https://example.com/callback`
   - Privacy/terms pages: use the templates in `skills/x-twitter-kit/templates/`

3. Register app credentials with `xurl` outside of agent/chat context. Do not paste credentials into chat or commit them.

4. Sign into xAI/Grok in OpenClaw for OAuth-backed `x_search`:

   ```bash
   openclaw models auth login --provider xai --method oauth
   openclaw models auth list --provider xai
   ```

   On a headless/VPS setup, use device-code auth when available:

   ```bash
   openclaw models auth login --provider xai --device-code
   ```

5. Run OAuth2 auth for X account surfaces:

   ```bash
   skills/x-twitter-kit/scripts/xurl-oauth2-auth.sh \
     --app default \
     --redirect-uri https://example.com/callback
   ```

6. Run the doctor:

   ```bash
   XTK_EXPECTED_X_USERNAME=your_handle \
   XTK_BOOKMARK_APP=default \
   skills/x-twitter-kit/scripts/twitter-doctor.sh
   ```

   If your OAuth2 client registration is in a separate xurl app, set `XTK_BOOKMARK_APP` to that app name.

6. Install the skill into OpenClaw:

   ```bash
   cp -R skills/x-twitter-kit ~/.openclaw/workspace/skills/
   ```

   Or configure `skills.load.extraDirs` to point at this repo's `skills` directory. See [OpenClaw install notes](docs/openclaw-install.md).

## Safety model

- Bookmarks require OAuth2 user context. OAuth1 and app-only bearer are not enough.
- Some xurl setups keep OAuth2 client registration and default OAuth1/bearer credentials under different app names. That is okay; use `XTK_BOOKMARK_APP` / `xurl --app <oauth2-app>` for OAuth2-only endpoints.
- `x_search` should be the default for broad discovery and research, and it should prefer OpenClaw's xAI OAuth auth profile. It is not a replacement for bookmarks, posting, metrics, pagination, or other structured/account actions.
- If both xAI OAuth and `XAI_API_KEY` are configured, treat the API key as a fallback, not the normal Twitter-search lane.
- Public/mutating actions — posting, replies, DMs, likes/reposts, follows, bookmark mutation, deletes — should stay approval-gated.
- Never commit or paste `~/.xurl`, OAuth callback codes, client secrets, access/refresh tokens, bearer tokens, or xAI keys.

## Local validation

```bash
scripts/ci-check.sh
```

`ci-check.sh` includes `scripts/test.sh`, an offline fake-command capability
matrix for the doctor. It exercises:

- xAI/Grok OAuth auth-profile primary routing.
- Expired/stale OAuth profile refresh smoke behavior.
- `XAI_API_KEY` fallback behavior when OAuth is absent.
- `xurl` exact read, search, and bookmark checks.
- Direct bearer fallback checks without printing bearer values.
- Expected-user mismatch failure behavior.
- Malformed xAI auth JSON.
- Missing and partial OpenClaw config surfaces.
- xurl live read failures.
- Direct bearer HTTP failures.
- API-key fallback secret-leak canaries.
- Guardrails that validation does not call mutating xurl verbs such as post,
  reply, like, repost, delete, follow, DM, mute, or block.

## Optional online validation

The online runner is opt-in because it spends live xAI/X calls and can fail
when credentials, subscriptions, or X API credits are unavailable:

```bash
XTK_RUN_ONLINE_TESTS=1 scripts/test-online.sh
```

By default it runs only non-mutating checks:

- xAI/Grok auth-profile model smoke, then a direct xAI Responses `x_search`
  request using the OpenClaw xAI OAuth profile.
- `xurl read` against `XTK_TEST_TWEET_URL`.
- `xurl search` against `XTK_SEARCH_QUERY`.

Additional online checks are explicit:

```bash
XTK_RUN_ONLINE_TESTS=1 \
XTK_ONLINE_BOOKMARKS=1 \
XTK_BOOKMARK_APP=default \
scripts/test-online.sh
```

```bash
XTK_RUN_ONLINE_TESTS=1 \
XTK_ONLINE_BEARER=1 \
XTK_BEARER_OP_REF='op://Vault/Item/Bearer Token' \
scripts/test-online.sh
```

The online runner never calls posting, reply, like, repost, delete, follow,
bookmark-mutation, DM, mute, or block commands. Bookmark list checks store
temporary JSON only long enough to validate shape and do not print bookmark
contents.

For live auth validation, run the doctor with your own credentials/config:

```bash
XTK_EXPECTED_X_USERNAME=your_handle \
XTK_BOOKMARK_APP=default \
skills/x-twitter-kit/scripts/twitter-doctor.sh
```
