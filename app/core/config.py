import os
import torch

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

HF_TOKEN = os.getenv("HF_TOKEN")

SARCASM_MODEL_DIR = os.getenv(
    "SARCASM_MODEL_ID",
    "kpatel1607/moodlens-sarcasm-v4"
)

EMOTION_MODEL_DIR = os.getenv(
    "EMOTION_MODEL_ID",
    "kpatel1607/moodlens-emotion-v2"
)


def prepare_models():
    return