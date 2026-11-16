#!/usr/bin/env bash
set -e

MODEL="qwen2.5-coder:3b"

echo "Waiting for Ollama server at $OLLAMA_HOST..."
until curl -s "${OLLAMA_HOST}/api/tags" > /dev/null; do
  sleep 2
done

echo "Pulling model: ${MODEL}..."
ollama pull "${MODEL}"

# Configure Continue VS Code extension for fast tab autocomplete and inline edits
mkdir -p ~/.continue
cat <<EOF > ~/.continue/config.json
{
  "models": [
    {
      "title": "Qwen 2.5 Coder 3B",
      "provider": "ollama",
      "model": "${MODEL}",
      "apiBase": "http://ollama:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Qwen 2.5 Coder 3B",
    "provider": "ollama",
    "model": "${MODEL}",
    "apiBase": "http://ollama:11434"
  },
  "tabAutocompleteOptions": {
    "debounceDelay": 250,
    "maxPromptTokens": 1024
  }
}
EOF

echo "Environment ready! Installed versions:"
gcc --version | head -n 1
rustc --version
node --version
nasm -v
python3 --version
cmake --version | head -n 1
ninja --version
dotnet --version
java -version 2>&1 | head -n 1
go version
sqlite3 --version
starship --version
ollama list