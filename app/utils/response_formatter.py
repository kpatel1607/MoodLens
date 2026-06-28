def compact_statement(statement):
    top_emotion = statement["final_emotion"]["top_emotions"][0]

    return {
        "text": statement["text"],
        "primary_emotion": top_emotion["emotion"],
        "emotion_score": top_emotion["score"],
        "sarcasm_label": statement["sarcasm"]["label"],
        "sarcasm_score": statement["sarcasm"]["model_sarcasm_score"],
        "sentiment": statement["sentiment"],
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