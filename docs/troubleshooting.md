# Troubleshooting

## Auth is healthy but one operation still fails

Treat this as a **capability mismatch**, not a generic Twitter failure.

- Exact tweet reads, search, bookmarks, DMs, posting, media, and account actions can require different auth contexts/scopes.
- `xurl auth status` proves credentials exist; it does not prove every surface is available for the selected app.
- Re-run the failing surface directly with the same app/config the agent will use.
- Do not inspect or edit `~/.xurl` directly. Shell out to `xurl` and fix credentials through its supported commands.

If the same data will be queried repeatedly, use a local cache/memory layer outside this kit instead of burning live API reads every time.

## `Unsupported Authentication` on bookmarks

Bookmarks require OAuth2 user context. Retry with the OAuth2 app explicitly:

```bash
xurl --app <oauth2-app-name> bookmarks -n 1
```

Then set `XTK_BOOKMARK_APP=<oauth2-app-name>` for the doctor.

## Callback approved but xurl never completes

Likely causes:

- X Developer callback URL does not exactly match the redirect URI.
- Browser opened `localhost`, but xurl is listening on a remote VPS.
- The public callback proxy was removed too early.
- The authorization code expired before it reached xurl.

Prefer the temporary public callback proxy in `templates/Caddyfile.callback.example` for VPS setups.

## Missing xAI / `x_search` auth

Prefer the signed-in xAI/Grok OAuth profile before any API-key fallback:

```bash
openclaw models auth list --provider xai
openclaw models auth login --provider xai --method oauth
```

On a VPS or SSH-only setup, use device-code auth when available:

```bash
openclaw models auth login --provider xai --device-code
```

OpenClaw must also expose/configure the xAI plugin and `x_search` tool. See `templates/openclaw-xai-config.patch.json5` for the config shape.

If an ordinary X research task appears to burn X API credits, check whether the agent used `xurl search` or `/2/tweets/search/recent` instead of `x_search`. Use xurl/direct bearer only when the task needs account context, exact fields, metrics, pagination, bookmarks, posting, or deterministic structured JSON.

## What not to paste into issues

Never paste:

- `~/.xurl`
- OAuth callback URLs containing `code=` or `state=`
- Client Secrets
- Access tokens
- Refresh tokens
- Bearer tokens
- XAI API keys
- full verbose API traces with Authorization headers

Use `xurl auth status` and redacted doctor output instead.
