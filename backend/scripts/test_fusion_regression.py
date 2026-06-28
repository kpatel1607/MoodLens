import os
import sys
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
PROJECT_DIR = BACKEND_DIR.parent
LOCAL_EMOTION = PROJECT_DIR / "saved_models" / "emotion_v2"
LOCAL_SARCASM = PROJECT_DIR / "saved_models" / "sarcasm_v4"

if LOCAL_EMOTION.is_dir():
    os.environ.setdefault("USE_LOCAL_MODELS", "true")
    os.environ.setdefault("MOODLENS_EMOTION_MODEL_ID", str(LOCAL_EMOTION))

if LOCAL_SARCASM.is_dir():
    os.environ.setdefault("USE_LOCAL_MODELS", "true")
    os.environ.setdefault("MOODLENS_SARCASM_MODEL_ID", str(LOCAL_SARCASM))

sys.path.insert(0, str(BACKEND_DIR))

from app.services.fusion_engine import analyze_text  # noqa: E402


def run_case(text, expected_mood_hint, expected_sarcasm_hint):
    result = analyze_text(text)
    overall = result["overall"]
    statements = result["statements"]
    sarcasm_labels = [statement["sarcasm_label"] for statement in statements]

    print(
        {
            "text": text,
            "expected_mood": expected_mood_hint,
            "expected_sarcasm": expected_sarcasm_hint,
            "overall_mood": overall["overall_mood"],
            "mood_score": overall["mood_score"],
            "dominant_emotion": overall["dominant_emotion"],
            "sarcasm_labels": sarcasm_labels,
            "trend": overall["trend"],
        }
    )


def main():
    cases = [
        (
            "I finally completed my project and I feel proud.",
            "Positive",
            "Not Sarcastic",
        ),
        (
            "I am grateful for the support I received today.",
            "Positive",
            "Not Sarcastic",
        ),
        (
            "The server crashed. Great. Exactly what I needed.",
            "Negative with Sarcasm",
            "Sarcastic",
        ),
        (
            "I feel exhausted and overwhelmed today.",
            "Negative",
            "Not Sarcastic",
        ),
        (
            "I went to college today and attended my lectures.",
            "Neutral",
            "Not Sarcastic",
        ),
    ]

    for text, expected_mood, expected_sarcasm in cases:
        run_case(text, expected_mood, expected_sarcasm)


if __name__ == "__main__":
    main()
