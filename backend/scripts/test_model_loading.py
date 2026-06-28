import os
import sys
from pathlib import Path

os.environ["TRANSFORMERS_NO_TF"] = "1"
os.environ["USE_TF"] = "0"

from transformers import (
    AutoConfig,
    AutoModelForSequenceClassification,
    AutoTokenizer,
)


BACKEND_DIR = Path(__file__).resolve().parents[1]
PROJECT_DIR = BACKEND_DIR.parent
LOCAL_EMOTION = PROJECT_DIR / "saved_models" / "emotion_v2"
LOCAL_SARCASM = PROJECT_DIR / "saved_models" / "sarcasm_v4"

sys.path.insert(0, str(BACKEND_DIR))

from app.core.config import SARCASM_THRESHOLD  # noqa: E402


SAMPLE_TEXT = "I finally completed my project and I feel proud."


def load_one(name, path):
    print(f"{name} model: {path}", flush=True)
    config = AutoConfig.from_pretrained(path)
    print(f"{name} id2label: {config.id2label}", flush=True)
    print(f"{name} label2id: {config.label2id}", flush=True)

    tokenizer = AutoTokenizer.from_pretrained(path, use_fast=True)
    tokens = tokenizer(
        SAMPLE_TEXT,
        return_tensors="pt",
        truncation=True,
        max_length=128,
    )
    print(f"{name} tokenizer: {tokenizer.__class__.__name__}", flush=True)
    print(f"{name} token keys: {sorted(tokens.keys())}", flush=True)

    model = AutoModelForSequenceClassification.from_pretrained(path)
    print(f"{name} loaded num_labels: {model.config.num_labels}", flush=True)
    return model, tokenizer


def main():
    emotion_model, _ = load_one("emotion", LOCAL_EMOTION)
    del emotion_model

    sarcasm_model, _ = load_one("sarcasm", LOCAL_SARCASM)

    print(
        "backend sarcastic class index:",
        sarcasm_model.config.label2id.get("Sarcastic", 1),
        flush=True,
    )
    print("sarcasm threshold:", SARCASM_THRESHOLD, flush=True)


if __name__ == "__main__":
    main()
