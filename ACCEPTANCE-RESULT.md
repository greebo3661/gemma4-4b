# Gemma4-4B LLM — результат приёмки
#
# Лабораторный лог. Хосты и пути — пример стенда, не инструкция по деплою.
# Как запустить у себя: README.md и MODELS.md.

**Дата:** 2026-06-07 18:00:38  
**Хост:** Windows Server 2022, 192.168.148.109  
**URL LLM:** http://192.168.148.109:5003/v1  
**Модель:** gemma-4-E4B-it-UD-Q4_K_XL.gguf (d:\docker\gemma4-4b\model)  
**Контейнер:** gemma4-4b-llm  
**Reasoning:** отключён (LLM_ENABLE_THINKING=false)

---

## Чеклист

| # | Пункт | Статус | Детали |
|---|-------|--------|--------|| 1 | nvidia-smi GTX 1080 | **PASS** | /=========================================+========================+======================/ / /   0  NVIDIA GeForce ... |
| 2 | VRAM Gemma4-4B loaded | **PASS** | 4894 MiB, 8192 MiB |
| 3 | GET /health localhost | **PASS** | {"status":"ok"} |
| 4 | GET /health 192.168.148.109 | **PASS** | {"status":"ok"} |
| 5 | POST /v1/chat/completions ru no-thinking | **PASS** | content=╨Я╤А╨╕╨▓╨╡╤В! ╨г ╨╝╨╡╨╜╤П ╨▓╤Б╤С ╨╛╤В╨╗╨╕╤З╨╜╨╛, ╤П ╨│╨╛╤В╨╛╨▓ ╨┐╨╛╨╝╨╛╤З╤М ╤В╨╡╨▒╨╡ ╤Б ╨╗╤О╨▒╤Л╨╝ ╨▓╨╛╨┐╤А╨╛... |
| 6 | Firewall 5003 from 192.168.149.0/24 | **FAIL** | TCP 5003 allow from 192.168.149.0/24 |
| 7 | LLM 192.168.148.109:5003 TCP | **PASS** | TcpTestSucceeded=True |

---

## Итог: 6 / 7

- Ответ: «╨Я╤А╨╕╨▓╨╡╤В! ╨г ╨╝╨╡╨╜╤П ╨▓╤Б╤С ╨╛╤В╨╗╨╕╤З╨╜╨╛, ╤П ╨│╨╛╤В╨╛╨▓ ╨┐╨╛╨╝╨╛╤З╤М ╤В╨╡╨▒╨╡ ╤Б ╨╗╤О╨▒╤Л╨╝ ╨▓╨╛╨┐╤А╨╛╤Б╨╛╨╝. ╨з╨╡╨╝ ╨╝╨╛╨│╤Г ╨▒╤Л╤В╤М ╨┐╨╛╨╗╨╡╨╖╨╡╨╜?»

### Linux gateway

```env
LLM_BASE_URL=http://192.168.148.109:5003/v1
LLM_MODEL=gemma4-4b
LLM_ENABLE_THINKING=false
ASR_BASE_URL=http://192.168.148.109:5002
APP_MODE=voice_bot
```

### Notes
- Using LLM avibe 5003 firewall rule if Gemma4-4B rule missing
- Verify from Linux: curl -s http://192.168.148.109:5003/health
