from pydantic import BaseModel, Field


class AnalysisRequest(BaseModel):
    text: str = Field(
        ...,
        min_length=1,
        max_length=5000
    )