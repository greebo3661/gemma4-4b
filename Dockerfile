# Thin wrapper around official llama.cpp CUDA server image (GTX 1080 / CUDA 12)
FROM ghcr.io/ggml-org/llama.cpp:server-cuda

USER root
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

ENV MODEL_PATH=/models/QAT/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf \
    HOST=0.0.0.0 \
    PORT=8080 \
    N_CTX=16384 \
    N_GPU_LAYERS=-1 \
    N_THREADS=8 \
    TEMPERATURE=0.7 \
    TOP_P=0.9 \
    TOP_K=64 \
    REPEAT_PENALTY=1.1 \
    LLM_ENABLE_THINKING=false

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=240s \
    CMD curl -f "http://127.0.0.1:8080/health" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
