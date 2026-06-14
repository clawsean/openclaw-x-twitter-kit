# X/Twitter Kit Vision

The X/Twitter kit should be the single routing and safety brain for X/Twitter
work across OpenClaw agents. It is not just a collection of commands; it
decides which transport to use, what context is needed, what is safe to do
automatically, and when an agent must stop for explicit approval.

## Goal

Reliable, low-cost, non-leaky X intelligence and action routing for agents.

The first-class workflows are monitoring, search, exact reads, summaries,
citations, diagnostics, and safe operational handoff. Posting and other account
actions are supported only through guarded, explicit paths.

## Product Shape

- **Capability-first routing:** Pick the operation first, then the transport.
  Known public-account monitoring should use Peeper; broad discovery and
  research should use OpenClaw/xAI `x_search`; exact tweets, timeline/account
  reads, bookmarks, posting, replies, and DMs should use `xurl`; direct bearer
  and browser access are fallbacks for specific gaps.
- **Spend-aware by default:** Do not burn xAI/Grok or X API calls for repeat
  monitoring when durable local state, Peeper, or a project cache can answer
  the need.
- **Stateful enough to be useful:** Repeated analysis should reuse local cache
  and seen-state where possible, instead of treating every request as a fresh
  live search.
- **Safety before convenience:** Public or mutating actions such as posting,
  replying, DMs, follows, likes, reposts, bookmark changes, block/mute, and
  deletes require clear user intent and explicit approval unless a separate
  standing policy exists.
- **Policy separate from adapters:** This skill owns route selection, safety,
  auth expectations, and reporting conventions. Tools like Peeper, `xurl`,
  direct API scripts, browser automation, and xAI search are adapters underneath
  that policy.
- **Diagnosable operations:** Agents should be able to distinguish broken auth,
  depleted API credits, missing scopes, unavailable adapters, rate limits, and
  normal no-result cases. Doctor scripts and local defaults exist to make that
  legible without exposing secrets.

## Non-Goals

- It should not connect company or brand accounts by default.
- It should not treat broad search, exact tweet reads, monitoring, and account
  mutations as interchangeable.
- It should not leak OAuth state, tokens, `~/.xurl`, raw headers, bookmark
  contents, or other sensitive account context into chat or logs.
- It should not spend live provider calls for avoidable repeat polling.

## Success Criteria

- An agent can answer "watch this public account" without paid API access.
- An agent can answer "search X for this topic" using the broad research path.
- An agent can read a specific tweet URL or account-aware timeline/bookmark
  context through the authenticated path when configured.
- Mutating account actions are hard to trigger accidentally.
- When something fails, the agent can report the likely failing layer and the
  next diagnostic step without guessing.
