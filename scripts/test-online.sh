#!/usr/bin/env bash
set -euo pipefail

TWEET_URL="${XTK_TEST_TWEET_URL:-https://x.com/nousresearch/status/2056872329561710766}"
SEARCH_QUERY="${XTK_SEARCH_QUERY:-OpenClaw}"
BOOKMARK_APP="${XTK_BOOKMARK_APP:-}"
BEARER_OP_REF="${XTK_BEARER_OP_REF:-}"
XAI_MODEL="${XTK_XAI_MODEL:-xai/grok-4.3}"
XAI_X_SEARCH_MODEL="${XTK_XAI_X_SEARCH_MODEL:-grok-4.3}"
XAI_X_SEARCH_QUERY="${XTK_XAI_X_SEARCH_QUERY:-OpenClaw x_search from:xai}"
XAI_X_SEARCH_ALLOWED_HANDLES="${XTK_XAI_X_SEARCH_ALLOWED_HANDLES:-xai}"
XAI_RESPONSES_URL="${XTK_XAI_RESPONSES_URL:-https://api.x.ai/v1/responses}"
RUN_ONLINE="${XTK_RUN_ONLINE_TESTS:-0}"
RUN_XAI_X_SEARCH="${XTK_ONLINE_XAI_X_SEARCH:-1}"
RUN_XURL="${XTK_ONLINE_XURL:-1}"
RUN_BOOKMARKS="${XTK_ONLINE_BOOKMARKS:-0}"
RUN_BEARER="${XTK_ONLINE_BEARER:-0}"

PASS=0
SKIP=0
FAIL=0
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/xtk-online.XXXXXX")"

cleanup() {
  unset XAI_API_KEY
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

ok() { printf 'ok %s\n' "$1"; PASS=$((PASS+1)); }
skip() { printf 'skip %s\n' "$1"; [ -n "${2:-}" ] && printf '  %s\n' "$2"; SKIP=$((SKIP+1)); }
fail() { printf 'not ok %s\n' "$1" >&2; [ -n "${2:-}" ] && printf '  %s\n' "$2" >&2; FAIL=$((FAIL+1)); }

is_enabled() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

require_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd binary present ($(command -v "$cmd"))"
    return 0
  fi
  fail "$cmd binary missing"
  return 1
}

json_has_data_array() {
  python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if isinstance(d.get("data"), list) else 1)' >/dev/null 2>&1
}

json_has_data_object() {
  python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if isinstance(d.get("data"), dict) else 1)' >/dev/null 2>&1
}

tweet_id_from_url() {
  python3 - "$1" <<'PY'
import re
import sys

m = re.search(r'/status/(\d+)', sys.argv[1])
print(m.group(1) if m else '')
PY
}

run_xai_oauth_x_search() {
  local model_out auth_json result_file py_out

  require_cmd openclaw || return
  require_cmd python3 || return

  model_out="$TMP_ROOT/xai-model.json"
  if XAI_API_KEY='' openclaw infer model run \
    --local \
    --json \
    --model "$XAI_MODEL" \
    --prompt 'Reply exactly: XTK_ONLINE_XAI_MODEL_OK' \
    >"$model_out" 2>"$TMP_ROOT/xai-model.err"; then
    if grep -q 'XTK_ONLINE_XAI_MODEL_OK' "$model_out"; then
      ok "xAI/Grok auth-profile model smoke works online (${XAI_MODEL})"
    else
      fail "xAI/Grok auth-profile model smoke returned unexpected output" "$(head -3 "$model_out")"
      return
    fi
  else
    fail "xAI/Grok auth-profile model smoke failed" "$(head -3 "$TMP_ROOT/xai-model.err" 2>/dev/null)"
    return
  fi

  auth_json="$TMP_ROOT/xai-auth.json"
  if ! openclaw models auth list --provider xai --json >"$auth_json" 2>"$TMP_ROOT/xai-auth.err"; then
    fail "xAI OAuth auth profile list failed" "$(head -3 "$TMP_ROOT/xai-auth.err" 2>/dev/null)"
    return
  fi

  result_file="$TMP_ROOT/xai-x-search-result.json"
  py_out="$TMP_ROOT/xai-x-search.out"
  if python3 - "$auth_json" "$result_file" "$XAI_X_SEARCH_MODEL" "$XAI_X_SEARCH_QUERY" "$XAI_X_SEARCH_ALLOWED_HANDLES" "$XAI_RESPONSES_URL" >"$py_out" 2>"$TMP_ROOT/xai-x-search.err" <<'PY'
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

auth_list_path, result_path, model, query, allowed_handles_raw, endpoint = sys.argv[1:]

def emit(status, message):
    print(f"{status}|{message}")

def token_from_profile(profile):
    for key in ("access", "accessToken", "token"):
        value = profile.get(key)
        if isinstance(value, str) and value:
            return value
        if isinstance(value, dict):
            for nested in ("access_token", "accessToken", "token", "value"):
                nested_value = value.get(nested)
                if isinstance(nested_value, str) and nested_value:
                    return nested_value
    return None

try:
    auth_list = json.loads(Path(auth_list_path).read_text())
except Exception as exc:
    emit("FAIL", f"could not parse xAI auth list: {exc}")
    raise SystemExit(1)

profiles = [
    p for p in auth_list.get("profiles", [])
    if p.get("provider") == "xai" and p.get("type") == "oauth" and p.get("id")
]
if not profiles:
    emit("FAIL", "no xAI OAuth auth profile found")
    raise SystemExit(1)

profile_id = profiles[0]["id"]
agent_dir = os.path.expanduser(str(auth_list.get("agentDir") or "~/.openclaw/agents/mainelobster/agent"))
auth_profiles_path = Path(agent_dir) / "auth-profiles.json"

try:
    store = json.loads(auth_profiles_path.read_text())
except Exception as exc:
    emit("FAIL", f"could not read OpenClaw auth profile store: {exc}")
    raise SystemExit(1)

profile = store.get("profiles", {}).get(profile_id)
if not isinstance(profile, dict) or profile.get("type") != "oauth":
    emit("FAIL", f"xAI auth profile {profile_id} is not an OAuth profile")
    raise SystemExit(1)

token = token_from_profile(profile)
if not token:
    emit("FAIL", f"xAI OAuth profile {profile_id} has no access token")
    raise SystemExit(1)

allowed_handles = [h.strip() for h in allowed_handles_raw.split(",") if h.strip()]
tool = {"type": "x_search"}
if allowed_handles:
    tool["allowed_x_handles"] = allowed_handles

body = {
    "model": model,
    "input": [{"role": "user", "content": query}],
    "tools": [tool],
}

request = urllib.request.Request(
    endpoint,
    data=json.dumps(body).encode("utf-8"),
    headers={
        "Content-Type": "application/json",
        "Authorization": "Bearer " + token,
        "User-Agent": "openclaw-x-twitter-kit-online-test",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(request, timeout=60) as response:
        response_body = response.read()
        status = response.status
except urllib.error.HTTPError as exc:
    response_body = exc.read(4096)
    try:
        detail = response_body.decode("utf-8", "replace")
    except Exception:
        detail = "<binary response>"
    emit("FAIL", f"xAI x_search HTTP {exc.code}: {detail[:500]}")
    raise SystemExit(1)
except Exception as exc:
    emit("FAIL", f"xAI x_search request failed: {exc}")
    raise SystemExit(1)

if status < 200 or status >= 300:
    emit("FAIL", f"xAI x_search HTTP {status}")
    raise SystemExit(1)

try:
    data = json.loads(response_body)
except Exception as exc:
    emit("FAIL", f"xAI x_search returned malformed JSON: {exc}")
    raise SystemExit(1)

text = data.get("output_text")
citations = data.get("citations") if isinstance(data.get("citations"), list) else []
annotation_citations = []
for output in data.get("output", []) if isinstance(data.get("output"), list) else []:
    if not isinstance(output, dict):
        continue
    for block in output.get("content", []) if isinstance(output.get("content"), list) else []:
        if isinstance(block, dict) and block.get("type") == "output_text" and isinstance(block.get("text"), str):
            text = text or block["text"]
            for annotation in block.get("annotations", []) if isinstance(block.get("annotations"), list) else []:
                if isinstance(annotation, dict) and isinstance(annotation.get("url"), str):
                    annotation_citations.append(annotation["url"])

all_citations = citations or annotation_citations
if not text:
    emit("FAIL", "xAI x_search returned no response text")
    raise SystemExit(1)

public_x_urls = [
    url for url in all_citations
    if isinstance(url, str) and ("x.com/" in url or "twitter.com/" in url)
]
if not public_x_urls and ("x.com/" not in text and "twitter.com/" not in text):
    emit("FAIL", "xAI x_search returned text but no X/Twitter citation or URL")
    raise SystemExit(1)

Path(result_path).write_text(json.dumps({
    "model": model,
    "query": query,
    "citationCount": len(all_citations),
    "firstCitation": public_x_urls[0] if public_x_urls else None,
}, indent=2) + "\n")
emit("OK", f"xAI OAuth x_search returned online X evidence ({len(all_citations)} citations)")
PY
  then
    if grep -q '^OK|' "$py_out"; then
      ok "$(cut -d'|' -f2- "$py_out" | head -1)"
    else
      fail "xAI OAuth x_search produced unexpected result" "$(head -3 "$py_out")"
    fi
  else
    fail "xAI OAuth x_search failed" "$(cat "$py_out" "$TMP_ROOT/xai-x-search.err" 2>/dev/null | head -6)"
  fi
}

run_xurl_online_reads() {
  local read_file search_file auth_status

  require_cmd xurl || return
  require_cmd python3 || return

  if auth_status="$(xurl auth status 2>&1)"; then
    if grep 'oauth2: ' <<<"$auth_status" | grep -vq 'oauth2: (none)'; then
      ok "xurl OAuth2 user detected"
    else
      fail "xurl OAuth2 user not detected" "$(printf '%s\n' "$auth_status" | head -5)"
    fi
  else
    fail "xurl auth status failed" "$(printf '%s\n' "$auth_status" | head -5)"
    return
  fi

  read_file="$TMP_ROOT/xurl-read.json"
  if xurl read "$TWEET_URL" >"$read_file" 2>"$TMP_ROOT/xurl-read.err"; then
    if json_has_data_object <"$read_file"; then
      ok "xurl exact tweet URL read works online"
    else
      fail "xurl exact tweet URL read returned unexpected JSON" "$(head -3 "$read_file")"
    fi
  else
    fail "xurl exact tweet URL read failed online" "$(head -5 "$TMP_ROOT/xurl-read.err" 2>/dev/null)"
  fi

  search_file="$TMP_ROOT/xurl-search.json"
  if xurl search "$SEARCH_QUERY" -n 1 >"$search_file" 2>"$TMP_ROOT/xurl-search.err"; then
    if json_has_data_array <"$search_file"; then
      ok "xurl search works online"
    else
      fail "xurl search returned unexpected JSON" "$(head -3 "$search_file")"
    fi
  else
    fail "xurl search failed online" "$(head -5 "$TMP_ROOT/xurl-search.err" 2>/dev/null)"
  fi
}

run_xurl_online_bookmarks() {
  local bookmarks_file

  require_cmd xurl || return
  require_cmd python3 || return

  bookmarks_file="$TMP_ROOT/xurl-bookmarks.json"
  if [ -n "$BOOKMARK_APP" ]; then
    if xurl --app "$BOOKMARK_APP" bookmarks -n 1 >"$bookmarks_file" 2>"$TMP_ROOT/xurl-bookmarks.err"; then
      :
    else
      fail "xurl bookmarks failed online via app ${BOOKMARK_APP}" "$(head -5 "$TMP_ROOT/xurl-bookmarks.err" 2>/dev/null)"
      return
    fi
  elif xurl bookmarks -n 1 >"$bookmarks_file" 2>"$TMP_ROOT/xurl-bookmarks.err"; then
    :
  else
    fail "xurl bookmarks failed online" "$(head -5 "$TMP_ROOT/xurl-bookmarks.err" 2>/dev/null)"
    return
  fi

  if json_has_data_array <"$bookmarks_file"; then
    ok "xurl bookmarks list works online without printing bookmark contents"
  else
    fail "xurl bookmarks returned unexpected JSON" "$(head -3 "$bookmarks_file")"
  fi
}

run_direct_bearer_online_read() {
  local tweet_id token http_code curl_config

  if [ -z "$BEARER_OP_REF" ]; then
    fail "legacy direct bearer online read missing XTK_BEARER_OP_REF"
    return
  fi

  require_cmd op || return
  require_cmd curl || return
  require_cmd python3 || return

  tweet_id="$(tweet_id_from_url "$TWEET_URL")"
  if [ -z "$tweet_id" ]; then
    fail "could not parse tweet id from XTK_TEST_TWEET_URL" "$TWEET_URL"
    return
  fi

  if ! token="$(op read "$BEARER_OP_REF" 2>"$TMP_ROOT/op.err")" || [ -z "$token" ]; then
    fail "1Password bearer token read failed" "$(head -3 "$TMP_ROOT/op.err" 2>/dev/null)"
    return
  fi

  curl_config="$TMP_ROOT/bearer-curl.conf"
  {
    printf 'header = "Authorization: Bearer %s"\n' "$token"
    printf 'header = "User-Agent: openclaw-x-twitter-kit-online-test"\n'
  } >"$curl_config"
  chmod 600 "$curl_config"
  unset token

  http_code="$(curl -sS -o "$TMP_ROOT/bearer-tweet.json" -w '%{http_code}' \
    -K "$curl_config" \
    "https://api.twitter.com/2/tweets/${tweet_id}?tweet.fields=author_id,created_at,public_metrics" \
    2>"$TMP_ROOT/curl.err")"

  if [ "$http_code" = "200" ] && python3 - "$TMP_ROOT/bearer-tweet.json" <<'PY' >/dev/null 2>&1
import json
import sys

d = json.load(open(sys.argv[1]))
assert d.get("data", {}).get("id")
PY
  then
    ok "legacy direct bearer tweet read works online"
  else
    fail "legacy direct bearer tweet read failed online" "HTTP ${http_code}; $(head -3 "$TMP_ROOT/curl.err" 2>/dev/null)"
  fi
}

printf '== online non-mutating X/Twitter capability tests ==\n'

if ! is_enabled "$RUN_ONLINE"; then
  skip "online tests disabled" "Set XTK_RUN_ONLINE_TESTS=1 to spend live xAI/X calls."
  printf 'PASS %d checks, SKIP %d checks, FAIL %d checks\n' "$PASS" "$SKIP" "$FAIL"
  exit 0
fi

if is_enabled "$RUN_XAI_X_SEARCH"; then
  run_xai_oauth_x_search
else
  skip "xAI OAuth x_search online test disabled" "Set XTK_ONLINE_XAI_X_SEARCH=1 to run it."
fi

if is_enabled "$RUN_XURL"; then
  run_xurl_online_reads
else
  skip "xurl online read/search tests disabled" "Set XTK_ONLINE_XURL=1 to run them."
fi

if is_enabled "$RUN_BOOKMARKS"; then
  run_xurl_online_bookmarks
else
  skip "xurl online bookmark list test disabled" "Set XTK_ONLINE_BOOKMARKS=1 to run it."
fi

if is_enabled "$RUN_BEARER"; then
  run_direct_bearer_online_read
else
  skip "legacy direct bearer online test disabled" "Set XTK_ONLINE_BEARER=1 and XTK_BEARER_OP_REF to run it."
fi

printf 'PASS %d checks, SKIP %d checks, FAIL %d checks\n' "$PASS" "$SKIP" "$FAIL"
[ "$FAIL" -eq 0 ]
