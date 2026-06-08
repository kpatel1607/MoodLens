import re


def clean_text(text: str) -> str:
    text = str(text)
    text = re.sub(
        r"http\S+|www\S+",
        "",
        text
    )
    text = re.sub(
        r"\s+",
        " ",
        text
    )
    return text.strip()