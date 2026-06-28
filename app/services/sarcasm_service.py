import torch

from app.core.config import DEVICE

from app.services.model_loader import (
    sarcasm_model,
    sarcasm_tokenizer
)

from app.services.irony_service import predict_irony
from app.services.sentiment_service import predict_sentiment
from app.utils.text_cleaner import clean_text


def predict_sarcasm(
    text: str,
    threshold: float = 0.45
):
    cleaned = clean_text(
        text
    )

    inputs = sarcasm_tokenizer(
        cleaned,
        return_tensors="pt",
        truncation=True,
        max_length=128
    ).to(DEVICE)

    with torch.no_grad():
        outputs = sarcasm_model(
            **inputs
        )

        probs = torch.softmax(
            outputs.logits,
            dim=1
        )[0].cpu().numpy()

    not_sarcastic = float(
        probs[0]
    )

    sarcastic = float(
        probs[1]
    )

    irony_result = predict_irony(
        text
    )

    sentiment_result = predict_sentiment(
        text
    )

    irony_score = irony_result[
        "irony_score"
    ]

    if sarcastic >= threshold:
        label = "Sarcastic"
        decision_reason = "sarcasm_model_threshold"

    else:
        label = "Not Sarcastic"
        decision_reason = "sarcasm_model_below_threshold"

    if label == "Sarcastic":
        if sarcastic >= 0.80:
            confidence = "Very High"
        elif sarcastic >= 0.65:
            confidence = "High"
        elif sarcastic >= 0.55:
            confidence = "Medium"
        else:
            confidence = "Low"
    else:
        if not_sarcastic >= 0.85:
            confidence = "High"
        elif not_sarcastic >= 0.70:
            confidence = "Medium"
        else:
            confidence = "Low"

    return {
        "label": label,
        "confidence": confidence,
        "decision_reason": decision_reason,

        "model_sarcasm_score": round(
            sarcastic * 100,
            2
        ),

        "model_not_sarcasm_score": round(
            not_sarcastic * 100,
            2
        ),

        "irony_score": irony_score,
        "non_irony_score": irony_result[
            "non_irony_score"
        ],

        "sentiment_label": sentiment_result[
            "label"
        ],
        "negative_score": sentiment_result[
            "negative_score"
        ],
        "neutral_score": sentiment_result[
            "neutral_score"
        ],
        "positive_score": sentiment_result[
            "positive_score"
        ]
    }