#!/usr/bin/env bash
set -u

TWEET_URL="${XTK_TEST_TWEET_URL:-https://x.com/nousresearch/status/2056872329561710766}"
SEARCH_QUERY="${XTK_SEARCH_QUERY:-OpenClaw}"
EXPECTED_USER="${XTK_EXPECTED_X_USERNAME:-}"
BOOKMARK_APP="${XTK_BOOKMARK_APP:-}"
BEARER_OP_REF="${XTK_BEARER_OP_REF:-}"
CONFIG="${XTK_OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
ENV_FILE="${XTK_OPENCLAW_ENV:-$HOME/.openclaw/.env}"

PASS=0
FAIL=0
WARN=0

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
  python3 - "$CONFIG" <<'PY' >/tmp/xtk-doctor-config.out 2>/tmp/xtk-doctor-config.err
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
  if grep -q '^NO ' /tmp/xtk-doctor-config.out; then warn "OpenClaw config is missing some X surfaces" "$(cat /tmp/xtk-doctor-config.out)"; else ok "OpenClaw config enables xurl + xAI x_search surfaces"; fi
else
  warn "OpenClaw config not found" "$CONFIG"
fi

if grep -q '^XAI_API_KEY=' "$ENV_FILE" 2>/dev/null || [ -n "${XAI_API_KEY:-}" ]; then ok "xAI key appears configured without printing it"; else warn "xAI key not found" "x_search backend probe will be skipped unless XAI_API_KEY is set"; fi

if grep -q 'handle /callback\*' /etc/caddy/Caddyfile 2>/dev/null; then warn "temporary OAuth callback proxy appears present" "Remove it when not actively re-authing"; else ok "no Caddy /callback* proxy detected"; fi

if command -v xurl >/dev/null 2>&1; then
  AUTH_STATUS="$(xurl auth status 2>&1 | strip_ansi)"
  if [ -n "$EXPECTED_USER" ]; then
    if grep -q "oauth2: ${EXPECTED_USER}" <<<"$AUTH_STATUS"; then ok "xurl OAuth2 user matches ${EXPECTED_USER}"; else fail "xurl OAuth2 user mismatch" "$AUTH_STATUS"; fi
  elif grep -q 'oauth2: ' <<<"$AUTH_STATUS" && ! grep -q 'oauth2: (none)' <<<"$AUTH_STATUS"; then
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

TWEET_ID="$(tweet_id_from_url "$TWEET_URL")"
if [ -n "$BEARER_OP_REF" ] && command -v op >/dev/null 2>&1 && [ -n "$TWEET_ID" ]; then
  if TOKEN="$(op read "$BEARER_OP_REF" 2>/dev/null)" && [ -n "$TOKEN" ]; then
    HTTP_CODE="$(curl -sS -o /tmp/xtk-doctor-tweet.json -w '%{http_code}' \
      -H "Authorization: Bearer ${TOKEN}" \
      -H 'User-Agent: openclaw-x-twitter-kit' \
      "https://api.twitter.com/2/tweets/${TWEET_ID}?tweet.fields=author_id,created_at,public_metrics" 2>/tmp/xtk-doctor-curl.err)"
    unset TOKEN
    if [ "$HTTP_CODE" = "200" ] && python3 -c 'import json; d=json.load(open("/tmp/xtk-doctor-tweet.json")); assert d.get("data",{}).get("id")' >/dev/null 2>&1; then
      ok "legacy direct bearer tweet read works"
    else
      warn "legacy direct bearer tweet read failed" "HTTP ${HTTP_CODE}; $(cat /tmp/xtk-doctor-curl.err 2>/dev/null)"
    fi
  else
    warn "1Password bearer token read failed" "$BEARER_OP_REF unavailable"
  fi
else
  warn "legacy direct bearer check skipped" "Set XTK_BEARER_OP_REF to a 1Password bearer-token reference"
fi

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE" >/dev/null 2>&1 || true
  set +a
fi
if [ -n "${XAI_API_KEY:-}" ]; then
  HTTP_CODE="$(curl -sS -o /tmp/xtk-doctor-xai-models.json -w '%{http_code}' \
    -H "Authorization: Bearer ${XAI_API_KEY}" \
    https://api.x.ai/v1/models 2>/tmp/xtk-doctor-xai.err)"
  if [ "$HTTP_CODE" = "200" ]; then ok "xAI API key works for model list (x_search backend auth)"; else warn "xAI API key probe failed" "HTTP ${HTTP_CODE}; $(cat /tmp/xtk-doctor-xai.err 2>/dev/null)"; fi
else
  warn "live xAI API probe skipped" "Set XAI_API_KEY to test x_search backend auth"
fi
unset XAI_API_KEY

rm -f /tmp/xtk-doctor-config.out /tmp/xtk-doctor-config.err /tmp/xtk-doctor-tweet.json /tmp/xtk-doctor-curl.err /tmp/xtk-doctor-xai-models.json /tmp/xtk-doctor-xai.err

printf '\nSummary: %d passed, %d warnings, %d failed\n' "$PASS" "$WARN" "$FAIL"
[ "$FAIL" -eq 0 ]
