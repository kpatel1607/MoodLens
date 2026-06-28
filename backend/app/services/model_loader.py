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
    prepare_models
)

prepare_models()

logger = logging.getLogger(__name__)


def auth_token_for(model_id):
    if os.path.isdir(str(model_id)):
        return None

    return HF_TOKEN


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
