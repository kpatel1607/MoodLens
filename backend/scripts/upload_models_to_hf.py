import os
from pathlib import Path

from huggingface_hub import upload_folder


ROOT = Path(__file__).resolve().parents[2]

UPLOADS = [
    (
        ROOT / "saved_models" / "emotion_v2",
        "kpatel1607/moodlens-emotion-v2",
    ),
    (
        ROOT / "saved_models" / "sarcasm_v4",
        "kpatel1607/moodlens-sarcasm-v4",
    ),
]


def main():
    token = os.getenv("HF_TOKEN")

    if not token:
        raise SystemExit("HF_TOKEN is not set. Set it before uploading private repos.")

    for folder, repo_id in UPLOADS:
        if not folder.is_dir():
            raise SystemExit(f"Missing model folder: {folder}")

        print(f"Uploading {folder} -> {repo_id}")
        upload_folder(
            folder_path=str(folder),
            repo_id=repo_id,
            repo_type="model",
            token=token,
            commit_message="Update MoodLens model artifacts",
        )

    print("Model uploads completed.")


if __name__ == "__main__":
    main()
