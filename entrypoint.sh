#!/bin/sh
set -eu

MODEL_PATH="${MODEL_PATH:-/models/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
N_CTX="${N_CTX:-4096}"
N_GPU_LAYERS="${N_GPU_LAYERS:--1}"
N_THREADS="${N_THREADS:-8}"
TEMPERATURE="${TEMPERATURE:-0.7}"
TOP_P="${TOP_P:-0.9}"
TOP_K="${TOP_K:-64}"
REPEAT_PENALTY="${REPEAT_PENALTY:-1.1}"
LLM_ENABLE_THINKING="${LLM_ENABLE_THINKING:-false}"

if [ ! -f "$MODEL_PATH" ]; then
  echo "ERROR: model not found: $MODEL_PATH" >&2
  exit 1
fi

# Gemma 4: disable reasoning/thinking mode for voice_bot latency.
if [ "$LLM_ENABLE_THINKING" = "true" ]; then
  CHAT_KWARGS='{"enable_thinking":true}'
else
  CHAT_KWARGS='{"enable_thinking":false}'
fi

export LD_LIBRARY_PATH="/app:${LD_LIBRARY_PATH:-}"

exec /app/llama-server \
  -m "$MODEL_PATH" \
  --host "$HOST" \
  --port "$PORT" \
  -c "$N_CTX" \
  -ngl "$N_GPU_LAYERS" \
  -t "$N_THREADS" \
  --temp "$TEMPERATURE" \
  --top-p "$TOP_P" \
  --top-k "$TOP_K" \
  --repeat-penalty "$REPEAT_PENALTY" \
  --jinja \
  --chat-template-kwargs "$CHAT_KWARGS"
