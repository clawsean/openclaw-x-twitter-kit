# OpenClaw X/Twitter Kit

A small OpenClaw-first helper skill + scripts for dependable X/Twitter access using layered backends:

1. **xurl** — primary authenticated X lane for tweet reads, search, bookmarks, timeline, media, and user actions.
2. **Direct bearer API** — deterministic script/API lane for exact X API calls.
3. **OpenClaw xAI `x_search`** — broad semantic discovery lane.
4. **Browser fallback** — last resort for UI-only cases or API-tier blocks.

The kit is designed to be shareable: it ships no secrets and should work for any OpenClaw/VPS user who brings their own X Developer app and credentials.

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

## Recommended OpenClaw install shape

Copy or install `skills/x-twitter-kit/` as an OpenClaw skill. The skill tells agents which X/Twitter lane to use and points to the bundled scripts for deterministic checks.

## Notes

- Bookmarks require OAuth2 user context. OAuth1 and app-only bearer are not enough.
- Some xurl setups keep OAuth2 client registration and default OAuth1/bearer credentials under different app names. That is okay; use `XTK_BOOKMARK_APP` / `xurl --app <oauth2-app>` for OAuth2-only endpoints.
- `x_search` is excellent for broad discovery, but it is not a replacement for bookmarks or posting.
- Keep public actions approval-gated.
