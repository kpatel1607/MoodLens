# MoodLens Saved Model Metadata

Model weights are not committed to GitHub.

Production model weights are hosted on Hugging Face:

- Emotion repo: `kpatel1607/moodlens-emotion-v2`
- Sarcasm repo: `kpatel1607/moodlens-sarcasm-v4`

This folder keeps safe metadata/tokenizer files for reference. Heavy artifacts such as `model.safetensors`, `pytorch_model.bin`, `training_args.bin`, `.pt`, `.pth`, `.onnx`, and `.ckpt` files are ignored by Git.

Local `saved_models/` can be restored by downloading from Hugging Face. A `backend/scripts/download_models.py` helper is not currently present in this project.
