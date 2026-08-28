#!/usr/bin/env bash
# Checks each key against its provider. Prints OK / FAIL / not set.
# Never prints the key itself.

check() {
  local name="$1" url="$2"; shift 2
  local value="${!name:-}"

  if [ -z "$value" ]; then
    printf '  %-20s not set\n' "$name"
    return
  fi

  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$url" "$@")

  case "$code" in
    200) printf '  %-20s OK\n'                         "$name" ;;
    401) printf '  %-20s FAIL (401 invalid key)\n'     "$name" ;;
    403) printf '  %-20s FAIL (403 no access/billing)\n' "$name" ;;
    429) printf '  %-20s key valid, rate limited\n'    "$name" ;;
    000) printf '  %-20s no response (network?)\n'     "$name" ;;
      *) printf '  %-20s HTTP %s\n'                    "$name" "$code" ;;
  esac
}

echo 'Checking provider keys...'
echo

check ANTHROPIC_API_KEY  https://api.anthropic.com/v1/models \
  -H "x-api-key: ${ANTHROPIC_API_KEY:-}" -H 'anthropic-version: 2023-06-01'

check OPENAI_API_KEY     https://api.openai.com/v1/models \
  -H "Authorization: Bearer ${OPENAI_API_KEY:-}"

check DEEPSEEK_API_KEY   https://api.deepseek.com/models \
  -H "Authorization: Bearer ${DEEPSEEK_API_KEY:-}"

check GEMINI_API_KEY     "https://generativelanguage.googleapis.com/v1beta/models" \
  -H "x-goog-api-key: ${GEMINI_API_KEY:-}"

check OPENROUTER_API_KEY https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer ${OPENROUTER_API_KEY:-}"

echo
echo 'A "not set" means the shell has not loaded it -- run: source ~/.zshrc'
