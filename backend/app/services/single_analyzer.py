from app.services.fusion_engine import analyze_statement


def analyze_single(text: str):
    return analyze_statement(text)
