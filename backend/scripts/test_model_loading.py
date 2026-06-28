import os
import sys
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
PROJECT_DIR = BACKEND_DIR.parent
LOCAL_EMOTION = PROJECT_DIR / "saved_models" / "emotion_v2"
LOCAL_SARCASM = PROJECT_DIR / "saved_models" / "sarcasm_v4"

if LOCAL_EMOTION.is_dir():
    os.environ.setdefault("MOODLENS_EMOTION_MODEL_ID", str(LOCAL_EMOTION))

if LOCAL_SARCASM.is_dir():
    os.environ.setdefault("MOODLENS_SARCASM_MODEL_ID", str(LOCAL_SARCASM))

sys.path.insert(0, str(BACKEND_DIR))

from app.core.config import (  # noqa: E402
    EMOTION_MODEL_DIR,
    SARCASM_MODEL_DIR,
    SARCASM_THRESHOLD,
)
from app.services.model_loader import (  # noqa: E402
    emotion_model,
    emotion_tokenizer,
    sarcasm_model,
    sarcasm_tokenizer,
)


SAMPLE_TEXT = "I finally completed my project and I feel proud."


def main():
    print("emotion model:", EMOTION_MODEL_DIR)
    print("sarcasm model:", SARCASM_MODEL_DIR)
    print("emotion id2label:", emotion_model.config.id2label)
    print("sarcasm id2label:", sarcasm_model.config.id2label)
    print("sarcasm label2id:", sarcasm_model.config.label2id)
    print("backend sarcastic class index:", sarcasm_model.config.label2id.get("Sarcastic", 1))
    print("emotion tokenizer:", emotion_tokenizer.__class__.__name__)
    print("sarcasm tokenizer:", sarcasm_tokenizer.__class__.__name__)
    print("sarcasm threshold:", SARCASM_THRESHOLD)

    emotion_tokens = emotion_tokenizer(
        SAMPLE_TEXT,
        return_tensors="pt",
        truncation=True,
        max_length=128,
    )
    sarcasm_tokens = sarcasm_tokenizer(
        SAMPLE_TEXT,
        return_tensors="pt",
        truncation=True,
        max_length=128,
    )

    print("emotion token keys:", sorted(emotion_tokens.keys()))
    print("sarcasm token keys:", sorted(sarcasm_tokens.keys()))


if __name__ == "__main__":
    main()
