# Contributing

Thanks for helping make this kit safer and easier to reuse.

## Local checks

Run before opening a PR:

```bash
scripts/ci-check.sh
```

The check validates shell syntax, runs ShellCheck when available, verifies skill frontmatter/executable bits, scans for obvious secrets, and runs `git diff --check`.

## Development setup

Required:

- Bash
- Python 3
- `xurl` for live X/Twitter smoke tests: `npm install -g @xdevplatform/xurl`
- Optional: ShellCheck for local linting

Live X/Twitter tests require your own X Developer app and credentials. Do not use Jared/Sean credentials, and do not paste secrets into issues, PRs, or chat.

## Pull request expectations

For changes that touch auth, OAuth, scopes, or mutation behavior, include:

- what changed
- which auth context is affected: OAuth2, OAuth1, bearer, xAI, or browser fallback
- test output from `scripts/ci-check.sh`
- any live doctor output, redacted and with bookmark/tweet contents omitted when sensitive
- security considerations, especially new scopes, token handling, callback routes, or logs

Public/mutating X actions must remain approval-gated by default.

## Reporting logs safely

Before posting logs:

- remove OAuth callback `code=` and `state=` values
- remove bearer tokens, client secrets, access tokens, refresh tokens, and API keys
- do not include `~/.xurl` contents
- prefer command summaries like `xurl auth status` over raw credential files
