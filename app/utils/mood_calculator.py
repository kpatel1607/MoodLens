positive_emotions = {
    "admiration",
    "amusement",
    "approval",
    "caring",
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


def calculate_mood_score(statement):
    top_emotion = statement["final_emotion"]["top_emotions"][0]

    emotion = top_emotion["emotion"]
    score = top_emotion["score"]

    sentiment = statement["sentiment"]

    mood_score = 0

    if emotion in positive_emotions:
        mood_score += score

    elif emotion in negative_emotions:
        mood_score -= score

    # sentiment backup when emotion is neutral/mixed
    if sentiment == "Negative":
        mood_score -= 35

    elif sentiment == "Positive":
        mood_score += 25

    elif sentiment == "Sarcastic Negative":
        mood_score -= 50

    elif sentiment == "Sarcastic / Mixed":
        mood_score -= 35

    if statement["sarcasm"]["label"] == "Sarcastic":
        mood_score -= 15

    return round(mood_score, 2)


def calculate_overall_mood(
    statements
):
    if not statements:
        return {
            "overall_mood": "Neutral",
            "mood_score": 0,
            "dominant_emotion": None,
            "sarcasm_count": 0,
            "trend": []
        }

    scores = []

    emotion_counts = {}

    sarcasm_count = 0

    trend = []

    for statement in statements:
        score = calculate_mood_score(
            statement
        )

        scores.append(
            score
        )

        top_emotion = statement[
            "final_emotion"
        ]["top_emotions"][0]["emotion"]

        emotion_counts[top_emotion] = (
            emotion_counts.get(
                top_emotion,
                0
            )
            + 1
        )

        if (
            statement["sarcasm"]["label"]
            == "Sarcastic"
        ):
            sarcasm_count += 1
            trend.append(
                "sarcastic"
            )

        elif score > 15:
            trend.append(
                "positive"
            )

        elif score < -15:
            trend.append(
                "negative"
            )

        else:
            trend.append(
                "neutral"
            )

    avg_score = sum(scores) / len(
        scores
    )

    if avg_score >= 25:
        overall_mood = "Positive"

    elif avg_score <= -25:
        overall_mood = "Negative"

    elif sarcasm_count > 0:
        overall_mood = "Mixed with Sarcasm"

    else:
        overall_mood = "Neutral / Mixed"

    dominant_emotion = max(
        emotion_counts,
        key=emotion_counts.get
    )

    return {
        "overall_mood": overall_mood,
        "mood_score": round(
            avg_score,
            2
        ),
        "dominant_emotion": dominant_emotion,
        "sarcasm_count": sarcasm_count,
        "trend": trend
    }