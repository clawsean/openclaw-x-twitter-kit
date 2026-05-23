# Security

This repo must never contain real X/Twitter, xAI, or password-manager secrets.

## Reporting a vulnerability

If the issue can be discussed publicly without exposing credentials, open a GitHub issue:

https://github.com/clawSean/openclaw-x-twitter-kit/issues

If the report includes credential leakage, exploitable token handling, or private account data, do **not** open a public issue. Use GitHub private vulnerability reporting if enabled, or contact the repo owner through GitHub and keep details minimal until a private channel is established.

## Never commit or paste

- `~/.xurl` or copies of it
- OAuth2 Client Secrets
- OAuth1 Consumer Secrets / Access Token Secrets
- OAuth callback URLs containing `code=` or `state=` values
- access tokens, refresh tokens, bearer tokens, or xAI API keys
- `.env` files with real values
- verbose API logs containing Authorization headers

## If a secret leaks

1. Revoke or rotate the credential immediately in the provider console.
2. Remove the secret from the working tree and history if it was committed.
3. Re-run `scripts/ci-check.sh`.
4. Mention that rotation happened in the public issue/PR, but do not paste the old secret.

## Security posture

This kit provides helper scripts, templates, and OpenClaw skill guidance. It is not a full auth server, credential vault, or compliance layer. Host applications remain responsible for encrypted token storage, user consent, legal/privacy requirements, and production monitoring.

Public/mutating X actions should require clear user intent and explicit approval unless the operator creates a separate standing policy.
