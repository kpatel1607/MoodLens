import sys
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
PROJECT_DIR = BACKEND_DIR.parent
sys.path.insert(0, str(BACKEND_DIR))

from app.services import fusion_engine  # noqa: E402


def emotion_result(label, score=72):
    return {
        "top_emotions": [{"emotion": label, "score": score}],
        "predicted_emotions": [{"emotion": label, "score": score}],
    }


def sarcasm_result(probability=0.12):
    score = round(probability * 100, 2)

    return {
        "label": "Sarcastic" if probability >= fusion_engine.SARCASM_THRESHOLD else "Not Sarcastic",
        "confidence": "Low",
        "decision_reason": "raw",
        "model_sarcasm_score": score,
        "model_not_sarcasm_score": round(100 - score, 2),
    }


def run_case(text, raw_emotion, expected_mood_hint, previous_negative_context=False):
    raw = emotion_result(raw_emotion)
    sarcasm = fusion_engine.calibrate_sarcasm(
        text,
        raw,
        sarcasm_result(),
        previous_negative_context=previous_negative_context,
    )
    final = fusion_engine.adjust_emotion_with_sarcasm(
        text,
        raw,
        sarcasm,
        previous_negative_context=previous_negative_context,
    )
    top = final["top_emotions"][0]
    mood_score = fusion_engine.calculate_mood_score(
        top["emotion"],
        top["score"],
        sarcasm,
    )
    sentiment = fusion_engine.calculate_sentiment(
        top["emotion"],
        sarcasm["label"],
        mood_score,
    )

    print(
        {
            "text": text,
            "expected": expected_mood_hint,
            "sarcasm": sarcasm["label"],
            "emotion": top["emotion"],
            "sentiment": sentiment,
            "mood_score": mood_score,
        }
    )

    return {
        "text": text,
        "primary_emotion": top["emotion"],
        "mood_score": mood_score,
        "sarcasm_label": sarcasm["label"],
        "sarcasm_score": sarcasm["model_sarcasm_score"],
    }


def main():
    cases = [
        ("I finally completed my project and I feel proud.", "joy", "Positive"),
        ("I am grateful for the support I received today.", "gratitude", "Positive"),
        ("The server crashed.", "sadness", "Negative / Not Sarcastic"),
        ("Great. Exactly what I needed.", "joy", "Negative with Sarcasm"),
        ("I feel exhausted and overwhelmed today.", "sadness", "Negative / Not Sarcastic"),
        ("I went to college today and attended my lectures.", "neutral", "Neutral"),
    ]

    statements = []
    previous_negative = False

    for text, raw_emotion, expected in cases:
        statement = run_case(
            text,
            raw_emotion,
            expected,
            previous_negative_context=previous_negative,
        )
        statements.append(statement)
        previous_negative = (
            statement["primary_emotion"] in fusion_engine.NEGATIVE_EMOTIONS
            or statement["mood_score"] < -15
            or fusion_engine.has_negative_event(text)
        )

    multi = fusion_engine.aggregate_statements(statements[2:4])
    print({"multi_sentence_overall": multi})


if __name__ == "__main__":
    main()
