positive_emotions = {
    "admiration",
    "amusement",
    "approval",
    "caring",
    "desire",
    "excitement",
    "gratitude",
    "joy",
    "love",
    "optimism",
    "pride",
    "relief"
}

negative_emotions = {
    "anger",
    "annoyance",
    "disappointment",
    "disapproval",
    "disgust",
    "embarrassment",
    "fear",
    "grief",
    "nervousness",
    "remorse",
    "sadness"
}

neutral_emotions = {
    "neutral",
    "confusion",
    "curiosity",
    "realization",
    "surprise"
}


def infer_sentiment(
    top_emotions,
    sarcasm_result
):
    if sarcasm_result["label"] == "Sarcastic":
        if sarcasm_result["negative_score"] >= 35:
            return "Sarcastic Negative"

        return "Sarcastic / Mixed"

    negative_score = sarcasm_result[
        "negative_score"
    ]

    positive_score = sarcasm_result[
        "positive_score"
    ]

    neutral_score = sarcasm_result[
        "neutral_score"
    ]

    if negative_score > max(
        positive_score,
        neutral_score
    ):
        return "Negative"

    if positive_score > max(
        negative_score,
        neutral_score
    ):
        return "Positive"

    return "Neutral / Mixed"


def generate_interpretation(
    sarcasm_result,
    raw_emotion,
    final_emotion,
    sentiment
):
    top_raw = raw_emotion[
        "top_emotions"
    ][0]

    top_adjusted = final_emotion[
        "top_emotions"
    ][0]

    if sarcasm_result["label"] == "Sarcastic":
        return (
            f"The text likely contains sarcasm. "
            f"The sarcasm model scored it "
            f"{sarcasm_result['model_sarcasm_score']}%. "
            f"The surface emotion looked like "
            f"{top_raw['emotion']} ({top_raw['score']}%), "
            f"but the adjusted hidden emotion appears to be "
            f"{top_adjusted['emotion']} ({top_adjusted['score']}%)."
        )

    return (
        f"The text appears mostly {sentiment.lower()}. "
        f"The strongest emotion is "
        f"{top_adjusted['emotion']} "
        f"({top_adjusted['score']}%)."
    )