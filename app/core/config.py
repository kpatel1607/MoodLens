import os

os.environ.setdefault("HF_HOME", "/tmp/huggingface")
os.environ.setdefault("HF_HUB_CACHE", "/tmp/huggingface/hub")

import torch

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

HF_TOKEN = os.getenv("HF_TOKEN")

SARCASM_MODEL_DIR = (
    os.getenv("MOODLENS_SARCASM_MODEL_ID")
    or os.getenv("SARCASM_MODEL_ID")
    or "kpatel1607/moodlens-sarcasm-v4"
)

EMOTION_MODEL_DIR = (
    os.getenv("MOODLENS_EMOTION_MODEL_ID")
    or os.getenv("EMOTION_MODEL_ID")
    or "kpatel1607/moodlens-emotion-v2"
)


def prepare_models():
    return
