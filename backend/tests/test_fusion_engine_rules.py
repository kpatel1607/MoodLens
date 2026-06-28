from app.services.fusion_engine import (
    aggregate_statements,
    calibrate_sarcasm,
    adjust_emotion_with_sarcasm,
    calculate_mood_score,
)


def emotion(emotion_name, score=70):
    return {
        "top_emotions": [{"emotion": emotion_name, "score": score}],
        "predicted_emotions": [{"emotion": emotion_name, "score": score}],
    }


def sarcasm(probability=0.12):
    score = round(probability * 100, 2)
    return {
        "label": "Sarcastic" if probability >= 0.34 else "Not Sarcastic",
        "confidence": "Low",
        "decision_reason": "raw",
        "model_sarcasm_score": score,
        "model_not_sarcasm_score": round(100 - score, 2),
    }


def fused_statement(text, raw_emotion="joy", raw_score=72, raw_sarcasm=0.12, previous_negative=False):
    raw = emotion(raw_emotion, raw_score)
    calibrated = calibrate_sarcasm(text, raw, sarcasm(raw_sarcasm), previous_negative)
    final = adjust_emotion_with_sarcasm(text, raw, calibrated, previous_negative)
    primary = final["top_emotions"][0]
    mood_score = calculate_mood_score(primary["emotion"], primary["score"], calibrated)
    return {
        "text": text,
        "primary_emotion": primary["emotion"],
        "mood_score": mood_score,
        "sarcasm_label": calibrated["label"],
        "sarcasm_score": calibrated["model_sarcasm_score"],
    }


def test_clear_sarcasm_from_positive_surface_negative_event():
    result = fused_statement("Great, the app crashed during my final demo.")
    assert result["sarcasm_label"] == "Sarcastic"
    assert result["primary_emotion"] == "annoyance"
    assert result["mood_score"] < -15


def test_literal_negative_is_not_sarcastic():
    result = fused_statement("The server crashed before the demo.", raw_emotion="sadness")
    assert result["sarcasm_label"] == "Not Sarcastic"
    assert result["primary_emotion"] == "sadness"
    assert result["mood_score"] < -15


def test_literal_positive_resolution_stays_positive():
    result = fused_statement("I fixed the issue after debugging for hours and I feel proud.", raw_emotion="joy")
    assert result["sarcasm_label"] == "Not Sarcastic"
    assert result["primary_emotion"] == "joy"
    assert result["mood_score"] > 15


def test_supportive_context_becomes_gratitude():
    result = fused_statement("My friend supported me when I was stressed.", raw_emotion="sadness")
    assert result["sarcasm_label"] == "Not Sarcastic"
    assert result["primary_emotion"] == "gratitude"
    assert result["mood_score"] > 15


def test_student_context_positive_surface_is_sarcastic():
    result = fused_statement("Wonderful, another surprise test before I finished the assignment.")
    assert result["sarcasm_label"] == "Sarcastic"
    assert result["primary_emotion"] == "annoyance"


def test_coding_context_positive_surface_is_sarcastic():
    result = fused_statement("Perfect, the deployment failed again after saying it was successful.")
    assert result["sarcasm_label"] == "Sarcastic"
    assert result["primary_emotion"] == "annoyance"


def test_vague_uncertain_stays_near_neutral():
    result = fused_statement("Today was certainly something.", raw_emotion="joy")
    assert result["sarcasm_label"] == "Uncertain"
    assert result["primary_emotion"] == "neutral"
    assert -15 <= result["mood_score"] <= 15


def test_short_ambiguous_positive_without_context_is_uncertain():
    result = fused_statement("Nice.")
    assert result["sarcasm_label"] == "Uncertain"
    assert -15 <= result["mood_score"] <= 15


def test_previous_negative_context_makes_positive_surface_likely_sarcastic():
    result = fused_statement("Perfect timing.", previous_negative=True)
    assert result["sarcasm_label"] == "Likely Sarcastic"
    assert result["primary_emotion"] == "annoyance"


def test_multiline_aggregation_weights_sarcasm_and_negative_context():
    statements = [
        fused_statement("I woke up feeling okay.", raw_emotion="neutral"),
        fused_statement("Then the assignment portal crashed before submission.", raw_emotion="sadness"),
        fused_statement("Great, exactly what I needed before finals.", previous_negative=True),
    ]
    overall = aggregate_statements(statements)
    assert overall["overall_mood"] == "Negative with Sarcasm"
    assert overall["sarcasm_count"] == 1

