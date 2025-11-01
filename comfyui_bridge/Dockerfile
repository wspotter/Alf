# AlphaOmega ComfyUI container with NVIDIA CUDA support
FROM nvidia/cuda:12.4-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        libgl1 \
        libglib2.0-0 \
        python3 \
        python3-pip \
        python3-dev \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app/ComfyUI

# Clone ComfyUI
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI && \
    mv /tmp/ComfyUI/* /app/ComfyUI && \
    rm -rf /tmp/ComfyUI

# Install PyTorch with CUDA support
RUN pip install --upgrade pip setuptools wheel && \
    pip install torch==2.4.0+cu124 torchvision==0.19.0+cu124 torchaudio==2.4.0+cu124 --index-url https://download.pytorch.org/whl/cu124 && \
    pip install transformers==4.44.2 && \
    pip install -r requirements.txt && \
    pip install onnxruntime-gpu>=1.18.0 accelerate>=0.32.0

EXPOSE 8188

CMD ["python", "main.py", "--listen", "--port", "8188"]
