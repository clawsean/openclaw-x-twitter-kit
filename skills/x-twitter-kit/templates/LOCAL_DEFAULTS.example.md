# X/Twitter Kit Local Defaults

Keep this file local to your OpenClaw workspace as:

```text
~/.openclaw/workspace/skills/x-twitter-kit/LOCAL_DEFAULTS.md
```

Do not commit real tokens, OAuth callback codes, access tokens, refresh tokens,
or bearer token values.

## Auth Defaults

- xAI/Grok OAuth profile:
  `xai:your-email@example.com`
- Expected xurl OAuth2 username:
  `your_x_handle`
- Optional xurl bookmark app:
  `default`
- Optional direct bearer secret ref:
  `op://Vault/Item/Bearer Token`

## Routing Defaults

- Ordinary X/Twitter search, research, summaries, and cited discovery:
  OpenClaw/xAI `x_search` through the signed-in xAI/Grok OAuth profile first.
- Exact tweet URL or tweet ID reads:
  `xurl read <url-or-id>`.
- Timeline, mentions, bookmarks, and account-aware reads:
  `xurl` with the correct app/user context.
- Direct bearer/API calls:
  deterministic script fallback only.

## Standing Policies

- Public/mutating actions require explicit approval unless your workspace has a
  separate standing policy.
- Bookmark contents should not be printed unless the user explicitly asks and
  the target chat is appropriate.
