# Веса Gemma 4 E4B QAT

В git нет `.gguf`. Каталог `model/` в `.gitignore`.

## Ожидаемый путь

```
model/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf
```

Compose монтирует `./model` в `/models:ro`.  
`MODEL_PATH` по умолчанию: `/models/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf`.

## Откуда взять файл

Рекомендуемая карточка Unsloth (Dynamic QAT GGUF):

https://huggingface.co/unsloth/gemma-4-E4B-it-qat-GGUF

Скачайте `gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf` (~4.2 GB) в `model/QAT/`.

Лицензия весов: [Gemma 4](https://ai.google.dev/gemma/docs/gemma_4_license).

## Что не нужно для текста

`mmproj-BF16.gguf` (vision) в этом compose не подключается.
