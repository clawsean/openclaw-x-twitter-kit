# Local Routing Guide

This guide captures the routing shape this kit is designed to encourage. It is
a reusable policy pattern, not a requirement that every operator copy one
workspace's local defaults.

## Routing Ladder

Pick the job first, then choose the narrowest transport that can do it safely:

1. **Known public-account monitoring** -> Peeper first.
   - Uses public profile endpoints, local seen-state, and last-good cache.
   - Does not spend X API credits, X OAuth, xAI/Grok calls, or paid RSS bridges.
   - Best for recurring monitors such as "tell me when this public handle posts."

2. **Broad X/Twitter search and research** -> OpenClaw/xAI `x_search`.
   - Use the signed-in Grok/xAI OAuth auth profile when available.
   - Best for semantic discovery, thread/media-aware summaries, and cited
     research.
   - Not a replacement for metrics, bookmarks, account timelines, or actions.

3. **Exact tweet and account-aware reads** -> `xurl`.
   - Best for exact tweet URLs/IDs, timeline-like reads, bookmarks, media, and
     authenticated account context.
   - Requires the correct OAuth/developer-app setup and may still be limited by
     X API tier/scopes.

4. **Deterministic structured API needs** -> direct bearer/API scripts.
   - Use only when exact fields, pagination, metrics, or compatibility scripts
     require it.
   - Fetch secrets at runtime and never print Authorization headers.

5. **UI-only or tier-blocked cases** -> browser fallback.
   - Last resort.
   - Mutating/public actions still require explicit approval.

## Fallback Pattern

For recurring monitors, use this order before spending paid/authenticated calls:

```text
primary public source -> alternate public source -> stale local cache -> authenticated/paid fallback only when justified
```

In this repo, Peeper's default `fx` source follows that shape by falling back to
the public syndication source and then to stale cache before failure.

## Design Note: Peeper-First Routing

For known public accounts, consider Peeper-first routing before escalating to
X API, Grok, xAI, or browser automation. Fetch public profile and post context
cheaply first, then escalate only when the cheaper path is missing data,
requires authenticated account context, or needs deeper interpretation.

This keeps the kit's broader vision intact while making API spend, credential
exposure, and operational risk proportional to the job.

## Local Defaults

Workspace-specific defaults belong in a local, untracked `LOCAL_DEFAULTS.md`.
That file may name handles, auth profiles, secret references, xurl app names,
and standing policies.

Keep these out of public PRs:

- real account names that are not needed for the example
- private project/channel names
- token values, OAuth callback codes, headers, or `~/.xurl`
- bookmark contents or other account-private data

## Review Heuristic

If a task appears to use a paid/authenticated transport, ask:

- Is this a known public account monitor that Peeper/cache can answer?
- Is this broad research that belongs on `x_search`?
- Is this exact/account-aware work that truly needs `xurl`?
- Is this a mutation or public action that needs approval?

The goal is not to avoid powerful transports. The goal is to make spend,
auth, and safety proportional to the job.
