def compact_statement(statement):
    top_emotion = statement.get(
        "final_emotion",
        {"top_emotions": [{"emotion": statement.get("primary_emotion", "neutral"), "score": statement.get("emotion_score", 0)}]}
    )["top_emotions"][0]

    return {
        "text": statement["text"],
        "surface_emotion": statement.get("surface_emotion"),
        "surface_emotion_score": statement.get("surface_emotion_score"),
        "top3_emotions": statement.get("top3_emotions", []),
        "primary_emotion": statement.get("primary_emotion", top_emotion["emotion"]),
        "emotion_score": statement.get("emotion_score", top_emotion["score"]),
        "sarcasm_label": statement.get("sarcasm_label", statement["sarcasm"]["label"]),
        "sarcasm_score": statement.get("sarcasm_score", statement["sarcasm"]["model_sarcasm_score"]),
        "sarcasm_reason": statement.get("sarcasm_reason", statement["sarcasm"].get("sarcasm_reason")),
        "sentiment": statement["sentiment"],
        "mood_score": statement.get("mood_score"),
        "interpretation": statement["interpretation"]
    }


def compact_sequence_response(full_response):
    return {
        "input_text": full_response["input_text"],
        "statement_count": full_response["statement_count"],
        "overall": full_response["overall"],
        "statements": [
            compact_statement(statement)
            for statement in full_response["statements"]
        ]
    }
