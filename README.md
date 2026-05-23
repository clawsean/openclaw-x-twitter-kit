# OpenClaw X/Twitter Kit

[![CI](https://github.com/clawSean/openclaw-x-twitter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/clawSean/openclaw-x-twitter-kit/actions/workflows/ci.yml)

A small OpenClaw-first helper skill + scripts for dependable X/Twitter access using layered backends:

1. **xurl** — primary authenticated X lane for tweet reads, search, bookmarks, timeline, media, and user actions.
2. **Direct bearer API** — deterministic script/API lane for exact X API calls.
3. **OpenClaw xAI `x_search`** — broad semantic discovery lane.
4. **Browser fallback** — last resort for UI-only cases or API-tier blocks.

The kit is designed to be shareable: it ships no secrets and should work for any OpenClaw/VPS user who brings their own X Developer app and credentials.

## Who this is for

- OpenClaw operators who want X/Twitter read/search/bookmark capability.
- Agent builders who need a repeatable OAuth2/xurl setup path.
- Technical friends who can bring their own X Developer app, callback URL, and credentials.

This is a **technical v0 kit**, not a hosted service or one-click consumer installer.

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

4. Run OAuth2 auth:

   ```bash
   skills/x-twitter-kit/scripts/xurl-oauth2-auth.sh \
     --app default \
     --redirect-uri https://example.com/callback
   ```

5. Run the doctor:

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
- `x_search` is excellent for broad discovery, but it is not a replacement for bookmarks or posting.
- Public/mutating actions — posting, replies, DMs, likes/reposts, follows, bookmark mutation, deletes — should stay approval-gated.
- Never commit or paste `~/.xurl`, OAuth callback codes, client secrets, access/refresh tokens, bearer tokens, or xAI keys.

## Local validation

```bash
scripts/ci-check.sh
```

For live auth validation, run the doctor with your own credentials/config:

```bash
XTK_EXPECTED_X_USERNAME=your_handle \
XTK_BOOKMARK_APP=default \
skills/x-twitter-kit/scripts/twitter-doctor.sh
```
