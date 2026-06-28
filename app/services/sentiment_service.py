import torch

from app.core.config import DEVICE

from app.services.model_loader import (
    sentiment_model,
    sentiment_tokenizer
)


def predict_sentiment(text: str):
    inputs = sentiment_tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        max_length=128
    ).to(DEVICE)

    with torch.no_grad():
        outputs = sentiment_model(**inputs)
        probs = torch.softmax(outputs.logits, dim=1)[0].cpu().numpy()

    id2label = sentiment_model.config.id2label

    scores = {
        id2label[i].lower(): float(probs[i])
        for i in range(len(probs))
    }

    negative = 0.0
    neutral = 0.0
    positive = 0.0

    for label, score in scores.items():
        if "negative" in label or label == "label_0":
            negative = max(negative, score)
        elif "neutral" in label or label == "label_1":
            neutral = max(neutral, score)
        elif "positive" in label or label == "label_2":
            positive = max(positive, score)

    final_label = max(
        {
            "Negative": negative,
            "Neutral": neutral,
            "Positive": positive
        },
        key={
            "Negative": negative,
            "Neutral": neutral,
            "Positive": positive
        }.get
    )

    return {
        "label": final_label,
        "negative_score": round(negative * 100, 2),
        "neutral_score": round(neutral * 100, 2),
        "positive_score": round(positive * 100, 2),
        "raw_scores": scores
    }