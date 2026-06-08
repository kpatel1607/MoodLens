from app.services.sarcasm_service import (
    predict_sarcasm
)

from app.services.emotion_service import (
    predict_emotions
)

from app.services.emotion_adjuster import (
    apply_keyword_emotion_corrections,
    adjust_emotions_for_sarcasm
)

from app.services.interpreter import (
    infer_sentiment,
    generate_interpretation
)


def analyze_single(text: str):
    sarcasm_result = predict_sarcasm(
        text
    )

    raw_emotion = predict_emotions(
        text,
        threshold=0.30,
        top_k=5
    )

    keyword_adjusted = (
        apply_keyword_emotion_corrections(
            text,
            raw_emotion
        )
    )

    final_emotion = (
        adjust_emotions_for_sarcasm(
            sarcasm_result,
            keyword_adjusted
        )
    )

    sentiment = infer_sentiment(
        final_emotion["top_emotions"],
        sarcasm_result
    )

    interpretation = generate_interpretation(
        sarcasm_result,
        raw_emotion,
        final_emotion,
        sentiment
    )

    return {
        "text": text,
        "sarcasm": sarcasm_result,
        "raw_emotion": raw_emotion,
        "final_emotion": final_emotion,
        "sentiment": sentiment,
        "interpretation": interpretation
    }