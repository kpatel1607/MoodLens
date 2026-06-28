import re
from collections import Counter

from app.core.config import SARCASM_THRESHOLD
from app.utils.sequence_splitter import split_sentences


# MoodLens Fusion Engine V1: inference-time fusion over emotion + sarcasm models.
MAX_LENGTH = 128

POSITIVE_EMOTIONS = {"joy", "love", "gratitude", "optimism"}
NEGATIVE_EMOTIONS = {"anger", "annoyance", "sadness", "fear", "disappointment"}
NEUTRAL_EMOTIONS = {"neutral", "confusion", "surprise"}

EMOTION_SCORE_MAP = {
    "joy": 80,
    "love": 75,
    "gratitude": 70,
    "optimism": 65,
    "neutral": 0,
    "confusion": -10,
    "surprise": 5,
    "annoyance": -55,
    "anger": -75,
    "sadness": -70,
    "fear": -65,
    "disappointment": -60,
}

POSITIVE_WORD_CUES = [
    "great", "amazing", "wonderful", "perfect", "fantastic", "excellent",
    "brilliant", "awesome", "lovely", "beautiful", "nice", "fun", "helpful",
    "convenient", "incredible", "impressive", "smooth", "peaceful", "calm",
    "happy", "glad", "proud", "thankful", "grateful", "appreciate", "love",
    "enjoy", "enjoying", "relieved", "satisfied", "confident", "motivated",
]

NEGATIVE_EVENT_CUES = [
    "crash", "crashed", "crashing", "fail", "failed", "failure", "rejected",
    "reject", "ignored", "ignore", "ruined", "ruin", "broke", "broken",
    "corrupt", "corrupted", "deleted", "lost", "error", "bug", "issue",
    "problem", "wrong", "worse", "worst", "missed", "late", "deadline",
    "pressure", "stress", "stressed", "anxious", "anxiety", "overwhelmed",
    "exhausted", "tired", "drained", "burnt out", "burned out", "lonely",
    "sad", "upset", "hurt", "disappointed", "angry", "annoyed",
    "frustrated", "confused", "worried", "scared", "nervous", "blamed",
    "blame", "cancelled", "canceled", "cancel", "betrayed", "betray",
    "lied", "lied to", "disrespected", "insulted", "humiliated", "excluded",
    "left out", "treated badly", "treated poorly", "treated unfairly",
    "not respected", "not valued", "made fun of",
]

CONTRAST_CUES = [
    "but", "except", "although", "though", "however", "yet", "still",
    "instead", "even though", "only to",
]

INTENSIFIER_CUES = [
    "so", "really", "absolutely", "totally", "definitely", "literally",
    "obviously", "clearly", "exactly", "just",
]

SARCASM_PATTERN_CUES = [
    "what a", "how nice", "how convenient", "just what", "exactly what",
    "couldn't have asked", "love when", "i love when", "i just love",
    "thanks for", "thank you for", "thanks a lot", "very kind",
    "very helpful", "as if", "because apparently", "really appreciate",
    "appreciate being",
]

VAGUE_UNCERTAIN_CUES = [
    "something", "interesting", "one way", "i guess", "apparently", "sure",
    "fine", "okay then", "unexpected", "well",
]

POSITIVE_RESOLUTION_CUES = [
    "solved", "fixed", "resolved", "completed", "finished", "improved",
    "finally works", "works now", "went well", "successfully", "relieved",
    "satisfied", "proud", "confident", "prepared", "motivated",
]

NEUTRAL_ACTIVITY_CUES = [
    "went to", "attended", "lecture", "lectures", "meeting started",
    "meeting ended", "submitted", "received", "confirmation", "cleaned",
    "arranged", "had lunch", "studied", "filled", "opened", "closed",
    "checked", "updated", "wrote down", "read", "walked",
]

SHORT_AMBIGUOUS_POSITIVE = ["nice", "sure", "fine", "okay", "cool", "great", "amazing", "perfect"]

SUPPORTIVE_POSITIVE_CUES = [
    "supported", "support", "helped", "help", "encouraged", "encourage",
    "comforted", "understood", "listened", "guided", "motivated",
    "stood by", "was there for me", "received support",
]

STUDENT_NEGATIVE_CUES = [
    "surprise test", "test", "exam", "assignment", "submission", "deadline",
    "harder", "difficult paper", "unexpected question", "too many deadlines",
    "unfinished assignment", "before i finished", "before finishing",
]

CODING_NEGATIVE_CUES = [
    "debugging", "works locally", "fails online", "deployment", "backend",
    "frontend", "api", "server", "build failed", "runtime error", "same code",
]

CLEAR_POSITIVE_STUDY_CUES = [
    "studied well", "prepared", "feel prepared", "completed my notes",
    "finished my notes", "revised well", "ready for the exam",
    "confident for the exam",
]

EXPECTED_NEUTRAL_UNCERTAIN_CUES = [
    "exactly what i expected", "what i expected", "as expected",
]

NEGATION_CUES = ["not", "never", "doesn't", "dont", "don't", "didn't", "isn't", "wasn't", "no"]


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", str(text).lower()).strip()


def has_any(text, cues):
    value = normalize_text(text)
    return any(cue in value for cue in cues)


def cue_count(text, cues):
    value = normalize_text(text)
    return sum(1 for cue in cues if cue in value)


def top_emotion(emotion_result):
    emotions = emotion_result.get("top_emotions") or []
    return emotions[0] if emotions else {"emotion": "neutral", "score": 0.0}


def has_positive_surface(text):
    return has_any(text, POSITIVE_WORD_CUES)


def has_student_negative_event(text):
    return has_any(text, STUDENT_NEGATIVE_CUES)


def has_coding_negative_context(text):
    return has_any(text, CODING_NEGATIVE_CUES)


def has_negative_event(text):
    return has_any(text, NEGATIVE_EVENT_CUES) or has_student_negative_event(text) or has_coding_negative_context(text)


def has_contrast(text):
    return has_any(text, CONTRAST_CUES)


def has_sarcasm_pattern(text):
    return has_any(text, SARCASM_PATTERN_CUES)


def has_vague_uncertain_tone(text):
    return has_any(text, VAGUE_UNCERTAIN_CUES)


def has_positive_resolution(text):
    return has_any(text, POSITIVE_RESOLUTION_CUES)


def has_neutral_activity(text):
    return has_any(text, NEUTRAL_ACTIVITY_CUES)


def has_exhaustion_or_stress(text):
    return has_any(text, ["stress", "stressed", "exhausted", "tired", "drained", "overwhelmed", "burnt out", "burned out"])


def has_supportive_positive(text):
    return has_any(text, SUPPORTIVE_POSITIVE_CUES)


def has_clear_positive_study(text):
    return has_any(text, CLEAR_POSITIVE_STUDY_CUES)


def has_expected_uncertain_tone(text):
    return has_any(text, EXPECTED_NEUTRAL_UNCERTAIN_CUES)


def is_short_ambiguous_positive(text):
    normalized = normalize_text(text).strip(".,!?")
    return normalized in SHORT_AMBIGUOUS_POSITIVE or (
        len(normalized.split()) <= 4 and has_any(normalized, SHORT_AMBIGUOUS_POSITIVE)
    )


def has_positive_opener(text):
    normalized = normalize_text(text)
    return bool(re.match(r"^(great|amazing|wonderful|perfect|lovely|nice|awesome|brilliant|fantastic)\b[,! ]", normalized))


def is_literal_positive_resolution(text):
    if has_supportive_positive(text) or has_clear_positive_study(text):
        return True
    if not has_positive_resolution(text):
        return False
    return not (
        has_positive_opener(text)
        and (has_student_negative_event(text) or has_coding_negative_context(text))
        and has_negative_event(text)
    )


def is_literal_neutral_activity(text, emotion_result):
    emotion = top_emotion(emotion_result)["emotion"]
    text_value = normalize_text(text)
    has_emotional_cue = has_positive_surface(text) or has_negative_event(text)
    return has_neutral_activity(text_value) and not has_emotional_cue and emotion in (NEUTRAL_EMOTIONS | {"joy", "optimism"})


def is_literal_negative_statement(text, emotion):
    return emotion in NEGATIVE_EMOTIONS and has_negative_event(text) and not has_positive_surface(text)


def contradiction_strength(text, previous_negative_context=False):
    normalized = normalize_text(text)
    strength = 0
    if has_positive_surface(text) and has_negative_event(text):
        strength += 2
    if has_positive_opener(text) and has_negative_event(text):
        strength += 1
    if has_sarcasm_pattern(text):
        strength += 2
    if has_contrast(text) and has_negative_event(text):
        strength += 1
    if has_any(text, INTENSIFIER_CUES) and has_positive_surface(text) and has_negative_event(text):
        strength += 1
    if previous_negative_context and has_positive_surface(text):
        strength += 1
    return strength


def confidence_from_probability(probability):
    if probability >= 0.85:
        return "Very High"
    if probability >= 0.70:
        return "High"
    if probability >= 0.50:
        return "Medium"
    return "Low"


def calibrate_sarcasm(text, emotion_result, sarcasm_result, previous_negative_context=False):
    raw_probability = float(sarcasm_result.get("model_sarcasm_score", 0.0)) / 100.0
    raw_probability = max(0.0, min(raw_probability, 1.0))
    emotion = top_emotion(emotion_result)["emotion"]
    contradiction = contradiction_strength(text, previous_negative_context)

    label = "Sarcastic" if raw_probability >= SARCASM_THRESHOLD else "Not Sarcastic"
    probability = raw_probability
    reason = "sarcasm_model_threshold" if label == "Sarcastic" else "sarcasm_model_below_threshold"

    if is_literal_positive_resolution(text):
        label, probability, reason = "Not Sarcastic", min(probability, 0.20), "literal_positive_resolution"
    elif is_short_ambiguous_positive(text) and not previous_negative_context and not has_negative_event(text):
        label, probability, reason = "Uncertain", min(max(probability, 0.30), 0.32), "short_ambiguous_positive"
    elif is_literal_neutral_activity(text, emotion_result):
        label, probability, reason = "Not Sarcastic", min(probability, 0.15), "literal_neutral_activity"
    elif is_literal_negative_statement(text, emotion):
        label, probability, reason = "Not Sarcastic", min(probability, 0.20), "literal_negative_statement"
    elif has_expected_uncertain_tone(text) and not has_negative_event(text):
        label, probability, reason = "Uncertain", min(max(probability, 0.30), 0.32), "expected_uncertain_tone"
    elif has_positive_surface(text) and (has_student_negative_event(text) or has_coding_negative_context(text)) and not is_literal_positive_resolution(text):
        label, probability, reason = "Sarcastic", max(probability, 0.85), "positive_surface_with_student_or_coding_negative_context"
    elif contradiction >= 3:
        label, probability, reason = "Sarcastic", max(probability, 0.85), "strong_emotional_contradiction"
    elif contradiction == 2 and has_positive_surface(text) and has_negative_event(text):
        label, probability, reason = "Likely Sarcastic", max(probability, 0.75), "positive_surface_negative_event"
    elif previous_negative_context and has_positive_surface(text):
        label, probability, reason = "Likely Sarcastic", max(probability, 0.75), "positive_surface_after_negative_context"
    elif has_vague_uncertain_tone(text) and emotion in POSITIVE_EMOTIONS:
        label, probability, reason = "Uncertain", min(max(probability, 0.30), 0.32), "vague_positive_emotional_wording"

    probability = round(max(0.0, min(probability, 1.0)) * 100, 2)
    return {
        **sarcasm_result,
        "label": label,
        "confidence": confidence_from_probability(probability / 100.0),
        "decision_reason": reason,
        "model_sarcasm_score": probability,
        "model_not_sarcasm_score": round(max(0.0, 100.0 - probability), 2),
        "sarcasm_reason": reason,
    }


def score_for_emotion(emotion, model_score):
    base = abs(EMOTION_SCORE_MAP.get(emotion, 0))
    if base == 0:
        return round(max(0.0, min(float(model_score), 100.0)), 2)
    return round(max(float(model_score), base * 0.75), 2)


def adjusted_emotion_result(primary, score, original_result):
    top = [
        {"emotion": primary, "score": round(float(score), 2)},
        *[
            item for item in original_result.get("top_emotions", [])
            if item.get("emotion") != primary
        ],
    ]
    return {
        "top_emotions": top[:5],
        "predicted_emotions": [item for item in top[:5] if item["score"] >= 30],
    }


def adjust_emotion_with_sarcasm(text, emotion_result, sarcasm_result, previous_negative_context=False):
    raw_top = top_emotion(emotion_result)
    raw_emotion = raw_top["emotion"]
    raw_score = float(raw_top["score"])
    label = sarcasm_result["label"]
    contradiction = contradiction_strength(text, previous_negative_context)

    primary = raw_emotion
    score = raw_score

    if is_literal_neutral_activity(text, emotion_result):
        primary = "neutral"
        score = max(45.0, raw_score * 0.60)
    elif has_supportive_positive(text):
        primary = "gratitude"
        score = max(60.0, raw_score)
    elif has_clear_positive_study(text):
        primary = "optimism"
        score = max(60.0, raw_score)
    elif is_literal_positive_resolution(text):
        primary = raw_emotion if raw_emotion in POSITIVE_EMOTIONS else "joy"
        score = max(55.0, raw_score)
    elif has_exhaustion_or_stress(text):
        primary = "sadness"
        score = max(55.0, raw_score)
    elif has_vague_uncertain_tone(text) and raw_emotion in POSITIVE_EMOTIONS:
        primary = "neutral"
        score = min(raw_score * 0.50, 45.0)
    elif label in {"Sarcastic", "Likely Sarcastic"} and raw_emotion in POSITIVE_EMOTIONS:
        primary = "annoyance"
        score = max(60.0, raw_score)
    elif label in {"Sarcastic", "Likely Sarcastic"} and raw_emotion in NEUTRAL_EMOTIONS and has_negative_event(text):
        primary = "annoyance"
        score = max(60.0, raw_score)
    elif label in {"Sarcastic", "Likely Sarcastic"} and raw_emotion in NEGATIVE_EMOTIONS:
        primary = raw_emotion
        score = max(score_for_emotion(raw_emotion, raw_score), raw_score)
    elif contradiction >= 2 and raw_emotion in POSITIVE_EMOTIONS and has_negative_event(text):
        primary = "annoyance"
        score = max(60.0, raw_score)
        sarcasm_result["label"] = "Likely Sarcastic"

    return adjusted_emotion_result(primary, score, emotion_result)


def calculate_sentiment(primary_emotion, sarcasm_label, mood_score):
    if sarcasm_label in {"Sarcastic", "Likely Sarcastic"}:
        return "Sarcastic Negative" if mood_score < -15 else "Sarcastic / Mixed"
    if sarcasm_label == "Uncertain":
        return "Neutral / Uncertain"
    if mood_score > 15 or primary_emotion in POSITIVE_EMOTIONS:
        return "Positive"
    if mood_score < -15 or primary_emotion in NEGATIVE_EMOTIONS:
        return "Negative"
    return "Neutral"


def calculate_mood_score(primary_emotion, emotion_score, sarcasm_result):
    label = sarcasm_result["label"]
    probability = float(sarcasm_result.get("model_sarcasm_score", 0.0)) / 100.0
    base = EMOTION_SCORE_MAP.get(primary_emotion, 0)

    if label in {"Sarcastic", "Likely Sarcastic"}:
        if primary_emotion in {"annoyance", "surprise", "confusion", "neutral"}:
            base = -60
        elif base > 0:
            base = -abs(base)
        else:
            base = base * (1.0 + min(probability, 0.40))

    if label == "Uncertain":
        base = max(-8.0, min(8.0, base * 0.20))

    model_weight = max(0.45, min(float(emotion_score) / 100.0, 1.0))
    return round(base * model_weight, 2)


def generate_interpretation(text, raw_emotion, final_emotion, sarcasm_result, sentiment):
    surface = top_emotion(raw_emotion)
    final = top_emotion(final_emotion)
    label = sarcasm_result["label"]
    reason = sarcasm_result["sarcasm_reason"].replace("_", " ")

    if label in {"Sarcastic", "Likely Sarcastic"}:
        return (
            f"MoodLens detected a positive surface with negative context. "
            f"The surface looked like {surface['emotion']} ({surface['score']}%), "
            f"but the fused reading is {final['emotion']} ({final['score']}%) because of {reason}."
        )
    if label == "Uncertain":
        return (
            f"The wording is ambiguous, so MoodLens keeps the mood close to neutral. "
            f"The strongest fused emotion is {final['emotion']} ({final['score']}%)."
        )
    return (
        f"The text appears mostly {sentiment.lower()}. "
        f"The strongest fused emotion is {final['emotion']} ({final['score']}%)."
    )


def analyze_statement(text, previous_negative_context=False):
    from app.services.emotion_service import predict_emotions
    from app.services.sarcasm_service import predict_sarcasm

    raw_emotion = predict_emotions(text, threshold=0.30, top_k=5)
    raw_sarcasm = predict_sarcasm(text, threshold=SARCASM_THRESHOLD)
    sarcasm_result = calibrate_sarcasm(text, raw_emotion, raw_sarcasm, previous_negative_context)
    final_emotion = adjust_emotion_with_sarcasm(text, raw_emotion, sarcasm_result, previous_negative_context)
    final_top = top_emotion(final_emotion)
    mood_score = calculate_mood_score(final_top["emotion"], final_top["score"], sarcasm_result)
    sentiment = calculate_sentiment(final_top["emotion"], sarcasm_result["label"], mood_score)
    interpretation = generate_interpretation(text, raw_emotion, final_emotion, sarcasm_result, sentiment)

    result = {
        "text": text,
        "surface_emotion": top_emotion(raw_emotion)["emotion"],
        "surface_emotion_score": top_emotion(raw_emotion)["score"],
        "top3_emotions": raw_emotion.get("top_emotions", [])[:3],
        "sarcasm_label": sarcasm_result["label"],
        "sarcasm_score": sarcasm_result["model_sarcasm_score"],
        "sarcasm_reason": sarcasm_result["sarcasm_reason"],
        "primary_emotion": final_top["emotion"],
        "emotion_score": final_top["score"],
        "sentiment": sentiment,
        "mood_score": mood_score,
        "interpretation": interpretation,
        "sarcasm": sarcasm_result,
        "raw_emotion": raw_emotion,
        "final_emotion": final_emotion,
    }
    return result


def statement_weight(statement):
    weight = 1.0
    if statement["sarcasm_label"] in {"Sarcastic", "Likely Sarcastic"}:
        weight = max(weight, 1.6)
    if statement["mood_score"] < -25:
        weight = max(weight, 1.4)
    return weight


def aggregate_statements(statements):
    if not statements:
        return {
            "overall_mood": "Neutral",
            "mood_score": 0.0,
            "dominant_emotion": "neutral",
            "sarcasm_count": 0,
            "uncertain_count": 0,
            "trend": [],
        }

    weights = [statement_weight(statement) for statement in statements]
    weighted_sum = sum(statement["mood_score"] * weight for statement, weight in zip(statements, weights))
    avg_score = weighted_sum / sum(weights)
    sarcasm_count = sum(1 for statement in statements if statement["sarcasm_label"] in {"Sarcastic", "Likely Sarcastic"})
    uncertain_count = sum(1 for statement in statements if statement["sarcasm_label"] == "Uncertain")
    strong_sarcasm_exists = any(
        statement["sarcasm_label"] == "Sarcastic" and statement["sarcasm_score"] >= 75
        for statement in statements
    )

    if avg_score > 15:
        overall_mood = "Positive"
    elif avg_score < -15:
        overall_mood = "Negative"
    else:
        overall_mood = "Neutral"

    if strong_sarcasm_exists and avg_score < -8:
        overall_mood = "Negative with Sarcasm"
    elif uncertain_count and overall_mood == "Neutral":
        overall_mood = "Neutral / Uncertain"
    elif strong_sarcasm_exists and overall_mood == "Neutral":
        overall_mood = "Neutral / Mixed with Possible Sarcasm"

    emotions = Counter(statement["primary_emotion"] for statement in statements)
    dominant_emotion = emotions.most_common(1)[0][0]
    trend = [
        "sarcastic" if statement["sarcasm_label"] in {"Sarcastic", "Likely Sarcastic"}
        else "uncertain" if statement["sarcasm_label"] == "Uncertain"
        else "positive" if statement["mood_score"] > 15
        else "negative" if statement["mood_score"] < -15
        else "neutral"
        for statement in statements
    ]

    return {
        "overall_mood": overall_mood,
        "mood_score": round(avg_score, 2),
        "dominant_emotion": dominant_emotion,
        "sarcasm_count": sarcasm_count,
        "uncertain_count": uncertain_count,
        "trend": trend,
    }


def analyze_text(text: str):
    statements = []
    previous_negative_context = False

    for statement_text in split_sentences(text):
        statement = analyze_statement(statement_text, previous_negative_context)
        statements.append(statement)
        previous_negative_context = (
            statement["primary_emotion"] in NEGATIVE_EMOTIONS
            or statement["mood_score"] < -15
            or has_negative_event(statement_text)
        )

    return {
        "input_text": text,
        "statement_count": len(statements),
        "overall": aggregate_statements(statements),
        "statements": statements,
    }
