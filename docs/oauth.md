# X OAuth setup notes

This kit assumes you bring your own X Developer app and credentials. It does not ship secrets and does not manage a hosted OAuth service for you.

## Recommended app shape

For the broad helper setup:

- App type: Web App / Automated App / Bot
- Permissions: Read + Write + DM if you need bookmarks, posting, and DMs
- Callback URL: exact-match URL you control, such as `https://example.com/callback`
- Website / privacy / terms URLs: public pages you control

Use least-privilege scopes if you only need read/search.

## OAuth2 / PKCE details to remember

Official X docs for OAuth 2.0 Authorization Code Flow with PKCE emphasize:

- callback URLs must match exactly
- authorization codes are short-lived
- `offline.access` is required if you want refresh tokens
- confidential apps get a client secret; public clients cannot keep a client secret safe

Docs: https://docs.x.com/resources/fundamentals/authentication/oauth-2-0/authorization-code

## Headless VPS callback flow

On a VPS, `localhost` in the browser usually means the user's laptop, not the VPS. Prefer a temporary public callback route:

1. Add `https://example.com/callback` to the X Developer app.
2. Temporarily proxy `/callback*` to the VPS xurl listener on `127.0.0.1:8080`.
3. Run:

   ```bash
   skills/x-twitter-kit/scripts/xurl-oauth2-auth.sh \
     --app default \
     --redirect-uri https://example.com/callback
   ```

4. Open the generated URL, approve, and wait for xurl to capture the callback.
5. Remove the temporary public callback proxy unless you are actively reauthing.

## Endpoint/auth context gotcha

`xurl auth status` can show OAuth2, OAuth1, and bearer credentials, but individual endpoints may still choose the wrong auth context.

If bookmarks fail with `Unsupported Authentication` and say OAuth 2.0 User Context is required, retry with the OAuth2 app explicitly:

```bash
xurl --app <oauth2-app-name> bookmarks -n 1
```

For the doctor, set:

```bash
XTK_BOOKMARK_APP=<oauth2-app-name>
```
