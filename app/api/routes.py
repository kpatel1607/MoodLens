from fastapi import APIRouter

from app.schemas.analysis_schema import AnalysisRequest
from app.services.single_analyzer import analyze_single
from app.services.sequence_analyzer import analyze_sequence
from app.utils.response_formatter import compact_sequence_response

router = APIRouter(
    prefix="/analyze",
    tags=["MoodLens Analysis"]
)


@router.post("/single")
def analyze_single_text(request: AnalysisRequest):
    return analyze_single(request.text)


@router.post("/sequence")
def analyze_sequence_text(request: AnalysisRequest):
    return analyze_sequence(request.text)


@router.post("/sequence/compact")
def analyze_sequence_compact(request: AnalysisRequest):
    full_response = analyze_sequence(request.text)
    return compact_sequence_response(full_response)