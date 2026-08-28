#!/usr/bin/env bash
# Creates a single central .env for LLM provider keys and wires it into zsh.
# Safe to re-run: never overwrites an existing file, never duplicates the
# .zshrc line. Writes placeholders only -- you fill in the real values.

set -euo pipefail

ENV_DIR="$HOME/.config/llm"
ENV_FILE="$ENV_DIR/.env"
ZSHRC="$HOME/.zshrc"
LOADER='set -a; [ -f ~/.config/llm/.env ] && source ~/.config/llm/.env; set +a'

mkdir -p "$ENV_DIR"
chmod 700 "$ENV_DIR"

if [ -f "$ENV_FILE" ]; then
  echo "==> $ENV_FILE already exists -- leaving it alone."
else
  cat > "$ENV_FILE" <<'ENVEOF'
# LLM provider keys. Real values only -- no quotes, no spaces around '='.
# Get keys from:
#   Anthropic   https://console.anthropic.com/settings/keys
#   OpenAI      https://platform.openai.com/api-keys
#   DeepSeek    https://platform.deepseek.com/api_keys
#   Gemini      https://aistudio.google.com/apikey
#   OpenRouter  https://openrouter.ai/keys

ANTHROPIC_API_KEY=
OPENAI_API_KEY=
DEEPSEEK_API_KEY=
GEMINI_API_KEY=
OPENROUTER_API_KEY=
ENVEOF
  echo "==> Created $ENV_FILE"
fi

chmod 600 "$ENV_FILE"
echo "==> Permissions set to 600 (owner read/write only)"

touch "$ZSHRC"
if grep -qF 'config/llm/.env' "$ZSHRC"; then
  echo "==> Loader line already in $ZSHRC -- skipping."
else
  {
    echo ''
    echo '# Load LLM provider keys into the environment'
    echo "$LOADER"
  } >> "$ZSHRC"
  echo "==> Added loader line to $ZSHRC"
fi

# Global gitignore so a stray .env can never be staged in any repo.
GLOBAL_IGNORE="$(git config --global core.excludesfile 2>/dev/null || true)"
# git stores this path verbatim, so an existing value may be a literal "~/..."
GLOBAL_IGNORE="${GLOBAL_IGNORE/#\~/$HOME}"
if [ -z "$GLOBAL_IGNORE" ]; then
  GLOBAL_IGNORE="$HOME/.gitignore_global"
  git config --global core.excludesfile "$GLOBAL_IGNORE"
  echo "==> Set global gitignore to $GLOBAL_IGNORE"
fi
touch "$GLOBAL_IGNORE"
for pattern in '.env' '.env.local' '.env.*.local'; do
  grep -qxF "$pattern" "$GLOBAL_IGNORE" || echo "$pattern" >> "$GLOBAL_IGNORE"
done
echo "==> Global gitignore covers .env patterns"

cat <<'NEXT'

Done. Next:

  1. Paste your real keys in:   nano ~/.config/llm/.env
  2. Reload the shell:          source ~/.zshrc
  3. Check they loaded:         ./verify-keys.sh

NEXT
