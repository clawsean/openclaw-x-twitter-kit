# Security

This repo must never contain real X/Twitter, xAI, or 1Password secrets.

Do not commit:

- `~/.xurl` or copies of it
- OAuth2 Client Secrets
- OAuth1 Consumer Secrets / Access Token Secrets
- Bearer tokens
- `.env` files with real values
- OAuth callback URLs containing `code=` or `state=` values
- verbose API logs containing Authorization headers

Use a password manager, environment variables, or OpenClaw secret providers for real credentials.

Public/mutating X actions — post, reply, delete, DM, follow/unfollow, block/mute, bookmark mutation — should require clear user intent and explicit approval unless the operator has created a separate standing policy.
