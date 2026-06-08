import os

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


def load_tokenizer(model_id):
    return AutoTokenizer.from_pretrained(
        model_id,
        token=HF_TOKEN
    )


def load_model(model_id):
    return (
        AutoModelForSequenceClassification
        .from_pretrained(
            model_id,
            token=HF_TOKEN
        )
        .to(DEVICE)
    )


sarcasm_tokenizer = load_tokenizer(SARCASM_MODEL_DIR)
sarcasm_model = load_model(SARCASM_MODEL_DIR)

emotion_tokenizer = load_tokenizer(EMOTION_MODEL_DIR)
emotion_model = load_model(EMOTION_MODEL_DIR)

irony_tokenizer = load_tokenizer(
    "cardiffnlp/twitter-roberta-base-irony"
)
irony_model = load_model(
    "cardiffnlp/twitter-roberta-base-irony"
)

sentiment_tokenizer = load_tokenizer(
    "cardiffnlp/twitter-roberta-base-sentiment-latest"
)
sentiment_model = load_model(
    "cardiffnlp/twitter-roberta-base-sentiment-latest"
)

sarcasm_model.eval()
emotion_model.eval()
irony_model.eval()
sentiment_model.eval()