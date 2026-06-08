import torch

from app.core.config import DEVICE

from app.services.model_loader import (
    irony_model,
    irony_tokenizer
)


def predict_irony(text: str):
    inputs = irony_tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        max_length=128
    ).to(DEVICE)

    with torch.no_grad():
        outputs = irony_model(**inputs)
        probs = torch.softmax(outputs.logits, dim=1)[0].cpu().numpy()

    id2label = irony_model.config.id2label

    scores = {
        id2label[i].lower(): float(probs[i])
        for i in range(len(probs))
    }

    irony_score = 0.0
    non_irony_score = 0.0

    for label, score in scores.items():
        if "irony" in label or "sarcasm" in label:
            irony_score = max(irony_score, score)
        else:
            non_irony_score = max(non_irony_score, score)

    return {
        "irony_score": round(irony_score * 100, 2),
        "non_irony_score": round(non_irony_score * 100, 2),
        "raw_scores": scores
    }