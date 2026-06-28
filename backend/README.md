---
title: MoodLens API
emoji: 🧠
colorFrom: yellow
colorTo: red
sdk: docker
app_port: 7860
---

# MoodLens API

FastAPI backend for MoodLens emotion, sarcasm and mood sequence analysis.

## Model configuration

The backend loads private Hugging Face repos through environment variables:

- `HF_TOKEN`: Hugging Face read token for private repos.
- `MOODLENS_EMOTION_MODEL_ID`: defaults to `kpatel1607/moodlens-emotion-v2`.
- `MOODLENS_SARCASM_MODEL_ID`: defaults to `kpatel1607/moodlens-sarcasm-v4`.
- `MOODLENS_FUSION_ENGINE_ID`: defaults to `kpatel1607/moodlens-fusion-engine-v1`.
- `MOODLENS_SARCASM_THRESHOLD`: defaults to `0.34`.

Older `EMOTION_MODEL_ID`, `SARCASM_MODEL_ID`, `FUSION_ENGINE_ID`, and `SARCASM_THRESHOLD` names are still accepted as compatibility aliases, but the `MOODLENS_*` names are preferred.
