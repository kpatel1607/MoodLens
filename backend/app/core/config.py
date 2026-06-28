import os
import json
from functools import lru_cache

os.environ.setdefault("HF_HOME", "/tmp/huggingface")
os.environ.setdefault("HF_HUB_CACHE", "/tmp/huggingface/hub")

import torch

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

HF_TOKEN = os.getenv("HF_TOKEN")

DEFAULT_EMOTION_MODEL_ID = "kpatel1607/moodlens-emotion-v2"
DEFAULT_SARCASM_MODEL_ID = "kpatel1607/moodlens-sarcasm-v4"
DEFAULT_FUSION_ENGINE_ID = "kpatel1607/moodlens-fusion-engine-v1"
DEFAULT_SARCASM_THRESHOLD = 0.34

BACKEND_DIR = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        "..",
        ".."
    )
)

LOCAL_EMOTION_MODEL_DIR = os.path.join(
    BACKEND_DIR,
    "saved_models",
    "emotion"
)

LOCAL_SARCASM_MODEL_DIR = os.path.join(
    BACKEND_DIR,
    "saved_models",
    "sarcasm"
)


def env_value(primary_name, legacy_name, default_value):
    return os.getenv(primary_name) or os.getenv(legacy_name) or default_value


def env_flag(name, default=False):
    value = os.getenv(name)

    if value is None:
        return default

    return value.strip().lower() in {"1", "true", "yes", "on"}


USE_LOCAL_MODELS = env_flag("USE_LOCAL_MODELS", default=False)

EMOTION_MODEL_DIR = env_value(
    "MOODLENS_EMOTION_MODEL_ID",
    "EMOTION_MODEL_ID",
    LOCAL_EMOTION_MODEL_DIR if USE_LOCAL_MODELS else DEFAULT_EMOTION_MODEL_ID
)

SARCASM_MODEL_DIR = env_value(
    "MOODLENS_SARCASM_MODEL_ID",
    "SARCASM_MODEL_ID",
    LOCAL_SARCASM_MODEL_DIR if USE_LOCAL_MODELS else DEFAULT_SARCASM_MODEL_ID
)

FUSION_ENGINE_ID = env_value(
    "MOODLENS_FUSION_ENGINE_ID",
    "FUSION_ENGINE_ID",
    DEFAULT_FUSION_ENGINE_ID
)

SARCASM_THRESHOLD = float(
    os.getenv("MOODLENS_SARCASM_THRESHOLD")
    or os.getenv("SARCASM_THRESHOLD")
    or DEFAULT_SARCASM_THRESHOLD
)


@lru_cache(maxsize=1)
def load_fusion_config():
    try:
        from huggingface_hub import hf_hub_download

        config_path = hf_hub_download(
            repo_id=FUSION_ENGINE_ID,
            filename="fusion_config.json",
            token=HF_TOKEN
        )

        with open(config_path, "r", encoding="utf-8") as config_file:
            return json.load(config_file)

    except Exception:
        return {}


def prepare_models():
    return
