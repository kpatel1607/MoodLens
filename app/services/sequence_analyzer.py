from app.utils.sequence_splitter import (
    split_sentences
)

from app.services.single_analyzer import (
    analyze_single
)

from app.utils.mood_calculator import (
    calculate_overall_mood
)


def analyze_sequence(text: str):
    sentences = split_sentences(
        text
    )

    statement_results = [
        analyze_single(
            sentence
        )
        for sentence in sentences
    ]

    overall = calculate_overall_mood(
        statement_results
    )

    return {
        "input_text": text,
        "statement_count": len(
            statement_results
        ),
        "overall": overall,
        "statements": statement_results
    }