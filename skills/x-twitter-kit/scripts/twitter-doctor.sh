#!/usr/bin/env bash
set -u

TWEET_URL="${XTK_TEST_TWEET_URL:-https://x.com/nousresearch/status/2056872329561710766}"
SEARCH_QUERY="${XTK_SEARCH_QUERY:-OpenClaw}"
EXPECTED_USER="${XTK_EXPECTED_X_USERNAME:-}"
BOOKMARK_APP="${XTK_BOOKMARK_APP:-}"
BEARER_OP_REF="${XTK_BEARER_OP_REF:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEEPER_SCRIPT="${XTK_PEEPER_SCRIPT:-$SCRIPT_DIR/peeper.mjs}"
PEEPER_FIXTURE="${XTK_PEEPER_FIXTURE:-$SCRIPT_DIR/../fixtures/edgewallet-cache.json}"
CONFIG="${XTK_OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
ENV_FILE="${XTK_OPENCLAW_ENV:-$HOME/.openclaw/.env}"
XAI_MODEL="${XTK_XAI_MODEL:-xai/grok-4.3}"
XAI_EXPECTED="${XTK_XAI_EXPECTED:-XTK_XAI_OAUTH_OK}"
XAI_PROMPT="${XTK_XAI_PROMPT:-Reply exactly: ${XAI_EXPECTED}}"
SKIP_XURL_LIVE="${XTK_SKIP_XURL_LIVE:-0}"

PASS=0
FAIL=0
WARN=0
XAI_OAUTH_AVAILABLE=0
XAI_OAUTH_PRESENT=0
XAI_API_KEY_FALLBACK_AVAILABLE=0
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/xtk-doctor.XXXXXX")"

cleanup() {
  unset XAI_API_KEY
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

strip_ansi() { sed -E 's/\x1B\[[0-9;?]*[A-Za-z]//g'; }
ok() { printf '✅ %s\n' "$1"; PASS=$((PASS+1)); }
fail() { printf '❌ %s\n' "$1"; [ -n "${2:-}" ] && printf '   %s\n' "$2" | head -3; FAIL=$((FAIL+1)); }
warn() { printf '⚠️  %s\n' "$1"; [ -n "${2:-}" ] && printf '   %s\n' "$2" | head -3; WARN=$((WARN+1)); }

json_has_data_array() {
  python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if isinstance(d.get("data"), list) else 1)' >/dev/null 2>&1
}

json_has_data_object() {
  python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if isinstance(d.get("data"), dict) else 1)' >/dev/null 2>&1
}

tweet_id_from_url() {
  python3 - "$1" <<'PY'
import re, sys
m=re.search(r'/status/(\d+)', sys.argv[1])
print(m.group(1) if m else '')
PY
}

printf 'X/Twitter doctor — non-secret smoke tests\n'
printf '=========================================\n'

if command -v xurl >/dev/null 2>&1; then ok "xurl binary present ($(command -v xurl))"; else fail "xurl binary missing" "Install @xdevplatform/xurl"; fi

if [ -f "$CONFIG" ]; then
  python3 - "$CONFIG" <<'PY' >"$TMP_ROOT/config.out" 2>"$TMP_ROOT/config.err"
import json, sys
cfg=json.load(open(sys.argv[1]))
checks={
  'skills.entries.xurl.enabled': cfg.get('skills',{}).get('entries',{}).get('xurl',{}).get('enabled') is True,
  'plugins.entries.xai.enabled': cfg.get('plugins',{}).get('entries',{}).get('xai',{}).get('enabled') is True,
  'plugins.entries.xai.config.xSearch.enabled': cfg.get('plugins',{}).get('entries',{}).get('xai',{}).get('config',{}).get('xSearch',{}).get('enabled') is True,
  'tools.alsoAllow includes x_search': 'x_search' in cfg.get('tools',{}).get('alsoAllow',[]),
}
for name, passed in checks.items():
    print(('OK ' if passed else 'NO ') + name)
sys.exit(0 if all(checks.values()) else 1)
PY
  if grep -q '^NO ' "$TMP_ROOT/config.out"; then warn "OpenClaw config is missing some X surfaces" "$(cat "$TMP_ROOT/config.out")"; else ok "OpenClaw config enables xurl + xAI x_search surfaces"; fi
else
  warn "OpenClaw config not found" "$CONFIG"
fi

if command -v openclaw >/dev/null 2>&1; then
  if openclaw models auth list --provider xai --json >"$TMP_ROOT/xai-auth.json" 2>"$TMP_ROOT/xai-auth.err"; then
    XAI_AUTH_SUMMARY="$(XTK_DOCTOR_XAI_AUTH_JSON="$TMP_ROOT/xai-auth.json" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone

try:
    data = json.load(open(os.environ["XTK_DOCTOR_XAI_AUTH_JSON"]))
except Exception as exc:
    print(f"WARN|could not parse xAI auth profile list: {exc}")
    raise SystemExit(0)

profiles = [
    p for p in data.get("profiles", [])
    if p.get("provider") == "xai" and p.get("type") == "oauth"
]
if not profiles:
    print("MISSING|no xAI OAuth auth profile found")
    raise SystemExit(0)

profile = profiles[0]
profile_id = profile.get("id") or "xai OAuth profile"
expires_at = profile.get("expiresAt")
if not expires_at:
    print(f"OK|{profile_id} present")
    raise SystemExit(0)

try:
    expires = datetime.fromisoformat(str(expires_at).replace("Z", "+00:00"))
except Exception:
    print(f"OK|{profile_id} present; unparsed expiry {expires_at}")
    raise SystemExit(0)

if expires <= datetime.now(timezone.utc):
    print(f"EXPIRED|{profile_id} expired at {expires_at}")
else:
    print(f"OK|{profile_id} expires at {expires_at}")
PY
)"
    XAI_AUTH_STATUS="${XAI_AUTH_SUMMARY%%|*}"
    XAI_AUTH_DETAIL="${XAI_AUTH_SUMMARY#*|}"
    case "$XAI_AUTH_STATUS" in
      OK)
        ok "xAI OAuth auth profile present (${XAI_AUTH_DETAIL})"
        XAI_OAUTH_PRESENT=1
        XAI_OAUTH_AVAILABLE=1
        ;;
      EXPIRED)
        warn "xAI OAuth auth profile token is expired/stale; model smoke will attempt refresh" "$XAI_AUTH_DETAIL"
        XAI_OAUTH_PRESENT=1
        ;;
      MISSING)
        warn "xAI OAuth auth profile missing" "$XAI_AUTH_DETAIL"
        ;;
      *)
        warn "xAI OAuth auth profile check inconclusive" "$XAI_AUTH_DETAIL"
        ;;
    esac
  else
    warn "xAI OAuth auth profile check failed" "$(cat "$TMP_ROOT/xai-auth.err" 2>/dev/null)"
  fi
else
  warn "OpenClaw CLI missing" "Cannot inspect xAI auth profiles"
fi

if grep -q '^XAI_API_KEY=' "$ENV_FILE" 2>/dev/null || [ -n "${XAI_API_KEY:-}" ]; then
  XAI_API_KEY_FALLBACK_AVAILABLE=1
  ok "xAI API-key fallback appears configured (not primary)"
elif [ "$XAI_OAUTH_AVAILABLE" -eq 1 ] || [ "$XAI_OAUTH_PRESENT" -eq 1 ]; then
  ok "xAI API-key fallback absent; OAuth profile is configured as primary"
else
  warn "xAI API-key fallback not found" "No OAuth profile or API-key fallback was detected"
fi

if grep -q 'handle /callback\*' /etc/caddy/Caddyfile 2>/dev/null; then warn "temporary OAuth callback proxy appears present" "Remove it when not actively re-authing"; else ok "no Caddy /callback* proxy detected"; fi

if [ -f "$PEEPER_SCRIPT" ] && command -v node >/dev/null 2>&1; then
  PEEPER_CACHE="$TMP_ROOT/peeper-cache.json"
  [ -f "$PEEPER_FIXTURE" ] && cp "$PEEPER_FIXTURE" "$PEEPER_CACHE"
  if node "$PEEPER_SCRIPT" --limit 1 --json --cache "$PEEPER_CACHE" >"$TMP_ROOT/peeper.json" 2>"$TMP_ROOT/peeper.err"; then
    PEEPER_STATUS="$(python3 - "$TMP_ROOT/peeper.json" <<'PY'
import json
import sys

try:
    data = json.load(open(sys.argv[1]))
except Exception as exc:
    print(f"BAD|could not parse Peeper output: {exc}")
    raise SystemExit(0)

if data.get("authUsed") or data.get("xApiUsed") or data.get("xAiUsed"):
    print("PAID|Peeper reported an auth, X API, or xAI path")
    raise SystemExit(0)

tweets = data.get("tweets") or []
tweet_id = tweets[0].get("id") if tweets and isinstance(tweets[0], dict) else ""
if not tweet_id:
    print("BAD|Peeper returned no tweet IDs")
elif data.get("stale"):
    print(f"CACHE|{tweet_id}")
else:
    print(f"LIVE|{tweet_id}")
PY
)"
    PEEPER_STATE="${PEEPER_STATUS%%|*}"
    PEEPER_DETAIL="${PEEPER_STATUS#*|}"
    case "$PEEPER_STATE" in
      LIVE)
        ok "Peeper no-credit monitor works via public FxTwitter source (${PEEPER_DETAIL})"
        ;;
      CACHE)
        ok "Peeper no-credit monitor works via cache fallback (${PEEPER_DETAIL})"
        ;;
      PAID)
        fail "Peeper smoke used a paid/auth path" "$PEEPER_DETAIL"
        ;;
      *)
        warn "Peeper smoke inconclusive" "$PEEPER_DETAIL"
        ;;
    esac
  else
    warn "Peeper smoke failed" "$(cat "$TMP_ROOT/peeper.err" 2>/dev/null)"
  fi
elif [ ! -f "$PEEPER_SCRIPT" ]; then
  warn "Peeper script not bundled with this skill install" "$PEEPER_SCRIPT"
else
  warn "Peeper smoke skipped" "Node.js is required for scripts/peeper.mjs"
fi

if command -v xurl >/dev/null 2>&1; then
  AUTH_STATUS="$(xurl auth status 2>&1 | strip_ansi)"
  if [ -n "$EXPECTED_USER" ]; then
    if grep -q "oauth2: ${EXPECTED_USER}" <<<"$AUTH_STATUS"; then ok "xurl OAuth2 user matches ${EXPECTED_USER}"; else fail "xurl OAuth2 user mismatch" "$AUTH_STATUS"; fi
  elif grep 'oauth2: ' <<<"$AUTH_STATUS" | grep -vq 'oauth2: (none)'; then
    ok "xurl has at least one OAuth2 user"
  else
    warn "xurl OAuth2 user not detected" "$AUTH_STATUS"
  fi
  if grep -q 'oauth1: ✓' <<<"$AUTH_STATUS"; then
    ok "xurl OAuth1 credential detected"
  else
    warn "xurl OAuth1 not detected" "Optional unless posting/user-context OAuth1 is needed"
  fi
  if grep -q 'bearer: ✓' <<<"$AUTH_STATUS"; then
    ok "xurl bearer credential detected"
  else
    warn "xurl bearer not detected" "Optional if xurl search works via another auth path"
  fi

  if [ "$SKIP_XURL_LIVE" = "1" ]; then
    warn "xurl live read/search/bookmark checks skipped" "XTK_SKIP_XURL_LIVE=1"
  else
    READ_JSON="$(xurl read "$TWEET_URL" 2>&1)"
    if printf '%s' "$READ_JSON" | json_has_data_object; then ok "xurl exact tweet URL read works"; else fail "xurl exact tweet read failed" "$READ_JSON"; fi

    SEARCH_JSON="$(xurl search "$SEARCH_QUERY" -n 1 2>&1)"
    if printf '%s' "$SEARCH_JSON" | json_has_data_array; then ok "xurl search works"; else fail "xurl search failed" "$SEARCH_JSON"; fi

    if [ -n "$BOOKMARK_APP" ]; then
      BOOKMARK_JSON="$(xurl --app "$BOOKMARK_APP" bookmarks -n 1 2>&1)"
      BOOKMARK_LABEL="xurl bookmarks work via app ${BOOKMARK_APP} (OAuth2 user context)"
    else
      BOOKMARK_JSON="$(xurl bookmarks -n 1 2>&1)"
      BOOKMARK_LABEL="xurl bookmarks work with default app (OAuth2 user context)"
    fi
    if printf '%s' "$BOOKMARK_JSON" | json_has_data_array; then ok "$BOOKMARK_LABEL"; else warn "xurl bookmarks failed" "$BOOKMARK_JSON"; fi
  fi
fi

TWEET_ID="$(tweet_id_from_url "$TWEET_URL")"
if [ -n "$BEARER_OP_REF" ] && command -v op >/dev/null 2>&1 && [ -n "$TWEET_ID" ]; then
  if TOKEN="$(op read "$BEARER_OP_REF" 2>/dev/null)" && [ -n "$TOKEN" ]; then
    HTTP_CODE="$(curl -sS -o "$TMP_ROOT/tweet.json" -w '%{http_code}' \
      -H "Authorization: Bearer ${TOKEN}" \
      -H 'User-Agent: openclaw-x-twitter-kit' \
      "https://api.twitter.com/2/tweets/${TWEET_ID}?tweet.fields=author_id,created_at,public_metrics" 2>"$TMP_ROOT/curl.err")"
    unset TOKEN
    if [ "$HTTP_CODE" = "200" ] && python3 - "$TMP_ROOT/tweet.json" <<'PY' >/dev/null 2>&1
import json, sys
d=json.load(open(sys.argv[1]))
assert d.get("data",{}).get("id")
PY
    then
      ok "legacy direct bearer tweet read works"
    else
      warn "legacy direct bearer tweet read failed" "HTTP ${HTTP_CODE}; $(cat "$TMP_ROOT/curl.err" 2>/dev/null)"
    fi
  else
    warn "1Password bearer token read failed" "$BEARER_OP_REF unavailable"
  fi
else
  warn "legacy direct bearer check skipped" "Set XTK_BEARER_OP_REF to a 1Password bearer-token reference"
fi

if [ "$XAI_OAUTH_PRESENT" -eq 1 ] && command -v openclaw >/dev/null 2>&1; then
  XAI_MODEL_OUT="$(XAI_API_KEY='' openclaw infer model run --local --json --model "$XAI_MODEL" --prompt "$XAI_PROMPT" 2>"$TMP_ROOT/xai-model.err")"
  XAI_MODEL_STATUS=$?
  if [ "$XAI_MODEL_STATUS" -eq 0 ] && printf '%s' "$XAI_MODEL_OUT" | grep -q "$XAI_EXPECTED"; then
    ok "xAI/Grok model smoke works with auth-profile lane (${XAI_MODEL})"
    XAI_OAUTH_AVAILABLE=1
  else
    warn "xAI/Grok model smoke failed" "$(cat "$TMP_ROOT/xai-model.err" 2>/dev/null)"
  fi
elif [ "$XAI_API_KEY_FALLBACK_AVAILABLE" -eq 1 ] && command -v openclaw >/dev/null 2>&1; then
  XAI_MODEL_OUT="$(openclaw infer model run --local --json --model "$XAI_MODEL" --prompt "$XAI_PROMPT" 2>"$TMP_ROOT/xai-model.err")"
  XAI_MODEL_STATUS=$?
  if [ "$XAI_MODEL_STATUS" -eq 0 ] && printf '%s' "$XAI_MODEL_OUT" | grep -q "$XAI_EXPECTED"; then
    ok "xAI/Grok model smoke works with API-key fallback lane (${XAI_MODEL})"
  else
    warn "xAI/Grok API-key fallback smoke failed" "$(cat "$TMP_ROOT/xai-model.err" 2>/dev/null)"
  fi
else
  warn "xAI/Grok model smoke skipped" "No usable xAI OAuth profile or API-key fallback detected"
fi

printf '\nSummary: %d passed, %d warnings, %d failed\n' "$PASS" "$WARN" "$FAIL"
[ "$FAIL" -eq 0 ]
