# gemma4-4b

OpenAI-совместимый LLM на [llama.cpp](https://github.com/ggml-org/llama.cpp) (`server-cuda`) и **Gemma 4 E4B IT QAT** (GGUF `Q4_K_XL`).

Reasoning выключен (`enable_thinking: false`) — низкая задержка для голосовых ботов и локальных агентов.

Проверено на **NVIDIA GTX 1080 8 GB**. Веса **не входят** в репозиторий.

## Что внутри

| | |
|---|---|
| Образ | обёртка над `ghcr.io/ggml-org/llama.cpp:server-cuda` |
| API | `GET /health`, `POST /v1/chat/completions` |
| Порт хоста | `5003` → контейнер `8080` |
| Контекст | `16384` |
| VRAM | ~4.9 GB при полном оффлоаде слоёв |
| Модель | `gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf` (~4.2 GB) |

Vision-проектор `mmproj-BF16.gguf` в текстовом режиме не используется.

## Требования

- Docker с NVIDIA Container Toolkit
- GPU, куда влезает ~5 GB весов + KV-кэш
- Свободный TCP **5003**
- Файл GGUF в `model/QAT/` (см. [MODELS.md](MODELS.md))

## Быстрый старт

1. Скачайте GGUF Unsloth / совместимый QAT в `model/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf`.
2. Поднимите сервис:

```bash
git clone https://github.com/greebo3661/gemma4-4b.git
cd gemma4-4b
cp .env.example .env
docker compose up -d --build
docker compose logs -f gemma4-4b-llm   # дождитесь "server is listening"
```

```bash
curl -s http://127.0.0.1:5003/health
curl -s http://127.0.0.1:5003/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma4-4b","messages":[{"role":"user","content":"Привет"}],"max_tokens":64}'
```

Приёмка (PowerShell):

```powershell
pwsh -NoProfile -File scripts/run-acceptance-tests.ps1
```

## Переменные

См. [.env.example](.env.example).

| Env | Default | Смысл |
|-----|---------|--------|
| `MODEL_PATH` | `/models/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf` | GGUF внутри контейнера |
| `N_CTX` | `16384` | контекст |
| `N_GPU_LAYERS` | `-1` | слои на GPU (`-1` = все) |
| `TEMPERATURE` / `TOP_P` / `TOP_K` | `0.7` / `0.9` / `64` | сэмплинг |
| `LLM_ENABLE_THINKING` | `false` | reasoning Gemma |

Том `./model` монтируется в `/models` только для чтения.

## Клиент

```env
LLM_BASE_URL=http://127.0.0.1:5003/v1
LLM_MODEL=gemma4-4b
LLM_ENABLE_THINKING=false
```

На одной карте 8 GB одновременно с этим сервисом обычно поднимают ASR на порту **5002**. Другие LLM на **5003** — нет.

## Лицензии

Код обёртки — [MIT](LICENSE).  
Веса Gemma 4 — [Gemma license](https://ai.google.dev/gemma/docs/gemma_4_license).  
Сборка QAT GGUF: [unsloth/gemma-4-E4B-it-qat-GGUF](https://huggingface.co/unsloth/gemma-4-E4B-it-qat-GGUF) (Apache-2.0 на карточке + лицензия Gemma).

## Ссылки

- [MODELS.md](MODELS.md) — куда класть GGUF
- [llama.cpp server](https://github.com/ggml-org/llama.cpp/tree/master/tools/server)
- [ACCEPTANCE-RESULT.md](ACCEPTANCE-RESULT.md) — лабораторная приёмка (хосты в тексте — пример)
