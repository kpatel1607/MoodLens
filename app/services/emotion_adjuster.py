from app.utils.text_cleaner import clean_text


emotion_keyword_rules = {
    "nervousness": [
        "nervous",
        "anxious",
        "anxiety",
        "worried",
        "tense"
    ],
    "pride": [
        "proud",
        "pride",
        "accomplished"
    ],
    "relief": [
        "relief",
        "relieved",
        "finally over",
        "can breathe"
    ],
    "embarrassment": [
        "embarrassed",
        "awkward",
        "ashamed",
        "humiliated"
    ],
    "disappointment": [
        "disappointed",
        "disappointing",
        "expected better"
    ],
    "annoyance": [
        "annoying",
        "irritating",
        "fed up",
        "tired of"
    ]
}


def apply_keyword_emotion_corrections(
    text,
    emotion_result
):
    cleaned = clean_text(
        text
    ).lower()

    existing = {
        item["emotion"]: item["score"]
        for item in emotion_result[
            "top_emotions"
        ]
    }

    for emotion, keywords in emotion_keyword_rules.items():
        for keyword in keywords:
            if keyword in cleaned:
                existing[emotion] = max(
                    existing.get(
                        emotion,
                        0
                    ),
                    55.0
                )

    adjusted_top = [
        {
            "emotion": emotion,
            "score": round(
                score,
                2
            )
        }
        for emotion, score in existing.items()
    ]

    adjusted_top = sorted(
        adjusted_top,
        key=lambda x: x["score"],
        reverse=True
    )[:5]

    adjusted_predicted = [
        item
        for item in adjusted_top
        if item["score"] >= 30
    ]

    return {
        "top_emotions": adjusted_top,
        "predicted_emotions": adjusted_predicted
    }


def adjust_emotions_for_sarcasm(
    sarcasm_result,
    emotion_result
):
    if sarcasm_result["label"] != "Sarcastic":
        return emotion_result

    existing = {
        item["emotion"]: item["score"]
        for item in emotion_result[
            "top_emotions"
        ]
    }

    if sarcasm_result["negative_score"] >= 40:
        existing["annoyance"] = max(
            existing.get(
                "annoyance",
                0
            ),
            65.0
        )

        existing["disappointment"] = max(
            existing.get(
                "disappointment",
                0
            ),
            55.0
        )

    else:
        existing["annoyance"] = max(
            existing.get(
                "annoyance",
                0
            ),
            50.0
        )

    for surface_emotion in [
        "admiration",
        "joy",
        "excitement",
        "approval",
        "love",
        "surprise"
    ]:
        if surface_emotion in existing:
            existing[surface_emotion] *= 0.45

    adjusted_top = [
        {
            "emotion": emotion,
            "score": round(
                score,
                2
            )
        }
        for emotion, score in existing.items()
    ]

    adjusted_top = sorted(
        adjusted_top,
        key=lambda x: x["score"],
        reverse=True
    )[:5]

    adjusted_predicted = [
        item
        for item in adjusted_top
        if item["score"] >= 30
    ]

    return {
        "top_emotions": adjusted_top,
        "predicted_emotions": adjusted_predicted
    }