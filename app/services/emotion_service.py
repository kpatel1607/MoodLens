import torch
import numpy as np

from app.core.config import DEVICE

from app.services.model_loader import (
    emotion_model,
    emotion_tokenizer
)

from app.utils.text_cleaner import clean_text


def get_emotion_labels():
    id2label = emotion_model.config.id2label

    labels = [
        id2label[i]
        for i in range(
            len(id2label)
        )
    ]

    return labels


EMOTION_LABELS = get_emotion_labels()


def predict_emotions(
    text: str,
    threshold: float = 0.30,
    top_k: int = 5
):
    cleaned = clean_text(
        text
    )

    inputs = emotion_tokenizer(
        cleaned,
        return_tensors="pt",
        truncation=True,
        max_length=128
    ).to(DEVICE)

    with torch.no_grad():
        outputs = emotion_model(
            **inputs
        )

        probs = torch.sigmoid(
            outputs.logits
        )[0].cpu().numpy()

    ranked_indices = np.argsort(
        probs
    )[::-1]

    top_emotions = [
        {
            "emotion": EMOTION_LABELS[idx],
            "score": round(
                float(probs[idx]) * 100,
                2
            )
        }
        for idx in ranked_indices[:top_k]
    ]

    predicted_emotions = [
        {
            "emotion": EMOTION_LABELS[i],
            "score": round(
                float(probs[i]) * 100,
                2
            )
        }
        for i in range(
            len(EMOTION_LABELS)
        )
        if probs[i] >= threshold
    ]

    return {
        "top_emotions": top_emotions,
        "predicted_emotions": predicted_emotions
    }