import re


def split_sentences(text: str):
    text = str(text).strip()

    if not text:
        return []

    text = re.sub(r"[\r\n]+", ". ", text)

    sentences = re.split(
        r"(?<=[.!?])\s+|(?<=;)\s+",
        text
    )

    return [
        sentence.strip()
        for sentence in sentences
        if sentence.strip()
    ]
