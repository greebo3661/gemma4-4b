# Gemma4-4B LLM Service (Docker + GTX 1080)

OpenAI-совместимый LLM-сервис на официальном образе **[llama.cpp](https://github.com/ggml-org/llama.cpp)** (`server-cuda`). Модель — **Gemma 4 E4B IT QAT** в формате GGUF (`Q4_K_XL`). Контракт API — OpenAI (`POST /v1/chat/completions`), reasoning отключён для низкой задержки voice_bot.

> **Актуальная модель:** используется **QAT**-версия `model/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf` (~4.2 GB). Старый файл `model/gemma-4-E4B-it-UD-Q4_K_XL.gguf` (не-QAT, ~5.1 GB) **не используется** — можно удалить или оставить как архив.

## Архитектура

```
docker-compose.yml -> Dockerfile (FROM llama.cpp:server-cuda) -> entrypoint.sh -> llama-server
        |                                                                              |
   ./model (ro volume) ------------------------------------------> -m QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf
```

- **Образ:** тонкая обёртка над `ghcr.io/ggml-org/llama.cpp:server-cuda` (+ `curl` для healthcheck), запуск через `entrypoint.sh`.
- **Модель:** `model/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf` монтируется как `:ro` volume в `/models`.
- **API:** OpenAI `/v1/chat/completions`, `/health`. Порт контейнера `8080` -> хост `5003`.
- **Reasoning:** `LLM_ENABLE_THINKING=false` -> `--chat-template-kwargs '{"enable_thinking":false}'`.
- Файл `model/QAT/mmproj-BF16.gguf` (vision-проектор) **не используется** в текстовом режиме.

## Ресурсы (GTX 1080, 8 GB)

| Параметр | Значение | Комментарий |
|----------|----------|-------------|
| Веса модели | ~4.2 GB | `Q4_K_XL`, QAT |
| `N_CTX` | `16384` | помещается на 8 GB |
| `N_GPU_LAYERS` | `-1` | полный офлоад |
| VRAM при загрузке | ~4.9 GB / 8 GB | проверено |

Порт **5003** общий для всех LLM (`gemma4-2b`, `gemma4-12b`, `a-vibe`) — одновременно поднять нельзя. Рекомендуемый стек на GTX 1080: **gigaam-asr (5002) + gemma4-4b-llm (5003)** (~5.0–5.5 GB VRAM суммарно).

## Быстрый старт

```powershell
# Порт 5003 и VRAM: остановите другие LLM
cd D:\docker\a-vibe;    docker compose down
cd D:\docker\gemma4-2b; docker compose down

cd D:\docker\gemma4-4b
docker compose up -d --build
docker compose logs -f gemma4-4b-llm   # дождитесь "server is listening"
```

```powershell
curl.exe -s http://127.0.0.1:5003/health
pwsh -NoProfile -File scripts\run-acceptance-tests.ps1   # -> ACCEPTANCE-RESULT.md
```

Firewall (admin, один раз): `scripts\add-firewall-rule.ps1` (правило `LLM Gemma4-4B 5003`, TCP 5003 из `192.168.149.0/24`).

## Переменные

| Env | Default | Описание |
|-----|---------|----------|
| `MODEL_PATH` | `/models/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf` | путь к GGUF в контейнере |
| `PORT` | `8080` | HTTP внутри контейнера (хост 5003) |
| `N_CTX` | `16384` | размер контекста |
| `N_GPU_LAYERS` | `-1` | число слоёв на GPU (`-1` = все) |
| `N_THREADS` | `8` | CPU-потоки |
| `TEMPERATURE` / `TOP_P` / `TOP_K` | `0.7` / `0.9` / `64` | сэмплинг |
| `REPEAT_PENALTY` | `1.1` | штраф за повтор |
| `LLM_ENABLE_THINKING` | `false` | reasoning-режим (off для voice_bot) |

## Linux gateway

```env
LLM_BASE_URL=http://192.168.148.109:5003/v1
LLM_MODEL=gemma4-4b
LLM_ENABLE_THINKING=false
ASR_BASE_URL=http://192.168.148.109:5002
APP_MODE=voice_bot
```

## Ссылки

- [ACCEPTANCE-RESULT.md](ACCEPTANCE-RESULT.md) — результат приёмки (6/7, chat ru без thinking)
- [gemma4-12b-qat/](../gemma4-12b-qat/) — старшая модель 12B QAT (solo, контекст 8192)
- [model/QAT/README.md](model/QAT/README.md) — карточка модели Unsloth
- [llama.cpp server](https://github.com/ggml-org/llama.cpp/tree/master/tools/server) — документация API
