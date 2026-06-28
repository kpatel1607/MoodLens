import os
import logging

os.environ["TRANSFORMERS_NO_TF"] = "1"
os.environ["USE_TF"] = "0"

from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification
)

from app.core.config import (
    DEVICE,
    HF_TOKEN,
    SARCASM_MODEL_DIR,
    EMOTION_MODEL_DIR,
    USE_LOCAL_MODELS,
    prepare_models
)

prepare_models()

logger = logging.getLogger(__name__)


def auth_token_for(model_id):
    if os.path.isdir(str(model_id)):
        return None

    return HF_TOKEN


def model_source_kind(model_id):
    return "local" if os.path.isdir(str(model_id)) else "huggingface"


def load_tokenizer(model_id):
    token = auth_token_for(model_id)

    try:
        return AutoTokenizer.from_pretrained(
            model_id,
            use_fast=True,
            token=token
        )
    except Exception as fast_error:
        logger.warning(
            "Fast tokenizer failed for %s: %s",
            model_id,
            fast_error
        )

        try:
            return AutoTokenizer.from_pretrained(
                model_id,
                use_fast=False,
                token=token
            )
        except Exception as slow_error:
            raise RuntimeError(
                f"Failed to load tokenizer for {model_id}. "
                f"Fast error: {fast_error}. Slow error: {slow_error}"
            ) from slow_error


def load_model(model_id):
    return (
        AutoModelForSequenceClassification
        .from_pretrained(
            model_id,
            token=auth_token_for(model_id)
        )
        .to(DEVICE)
    )


sarcasm_tokenizer = load_tokenizer(SARCASM_MODEL_DIR)
sarcasm_model = load_model(SARCASM_MODEL_DIR)

emotion_tokenizer = load_tokenizer(EMOTION_MODEL_DIR)
emotion_model = load_model(EMOTION_MODEL_DIR)

sarcasm_model.eval()
emotion_model.eval()

logger.info(
    "MoodLens model loading mode: %s",
    "local" if USE_LOCAL_MODELS else "huggingface"
)
logger.info(
    "Emotion model source: %s (%s)",
    EMOTION_MODEL_DIR,
    model_source_kind(EMOTION_MODEL_DIR)
)
logger.info(
    "Sarcasm model source: %s (%s)",
    SARCASM_MODEL_DIR,
    model_source_kind(SARCASM_MODEL_DIR)
)
logger.info("Emotion labels: %s", emotion_model.config.id2label)
logger.info("Sarcasm labels: %s", sarcasm_model.config.id2label)
logger.info(
    "Sarcastic index: %s",
    sarcasm_model.config.label2id.get("Sarcastic", 1)
)
logger.info(
    "Tokenizer classes: emotion=%s sarcasm=%s",
    emotion_tokenizer.__class__.__name__,
    sarcasm_tokenizer.__class__.__name__
)
