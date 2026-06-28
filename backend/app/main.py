from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router

app = FastAPI(
    title="MoodLens API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.get("/")
def root():
    return {"message": "MoodLens API running"}


@app.get("/routes")
def list_routes():
    return [
        {
            "path": route.path,
            "methods": list(route.methods)
        }
        for route in app.routes
    ]


@app.get("/debug/models")
def debug_models():
    from app.core.config import (
        EMOTION_MODEL_DIR,
        SARCASM_MODEL_DIR,
        SARCASM_THRESHOLD
    )
    from app.services.model_loader import (
        emotion_model,
        emotion_tokenizer,
        sarcasm_model,
        sarcasm_tokenizer
    )

    sarcasm_label2id = sarcasm_model.config.label2id

    return {
        "emotion_model": EMOTION_MODEL_DIR,
        "sarcasm_model": SARCASM_MODEL_DIR,
        "emotion_labels": emotion_model.config.id2label,
        "sarcasm_labels": sarcasm_model.config.id2label,
        "emotion_tokenizer_class": emotion_tokenizer.__class__.__name__,
        "sarcasm_tokenizer_class": sarcasm_tokenizer.__class__.__name__,
        "sarcastic_index": sarcasm_label2id.get("Sarcastic", 1),
        "sarcasm_threshold": SARCASM_THRESHOLD
    }
