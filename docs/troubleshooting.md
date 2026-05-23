# Troubleshooting

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

The kit can validate that an xAI key exists and can call the model-list endpoint, but OpenClaw must also expose/configure the xAI plugin and `x_search` tool. See `templates/openclaw-xai-config.patch.json5` for the config shape.

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
