# Demo bank model repo

A model repo as a bank would keep it, connected to Proofline. Test models with planted defects, on public data.

```
proofline.yaml            settings: agent models, threshold overrides
models/<id>/model.yaml    one manifest per model
data/prepared/            model input data (paths in model.yaml are relative to this repo)
```

Run Proofline against it (offline, recorded AI answers, scripted sign-offs):

```bash
cd ../proofline
export MRF_MODEL_REPO=../proofline-demo-bank
uv run mrf models
uv run mrf run --model m1 --mode replay --approvals tests/fixtures/approvals/m1_demo.yaml
uv run mrf run --model m2 --mode replay --approvals tests/fixtures/approvals/m2_demo.yaml
uv run mrf run --model m3 --mode replay --approvals tests/fixtures/approvals/m3_document_only.yaml
uv run mrf mlflow-sync                           # runs and registry in mlflow.db
uv run streamlit run app/streamlit_app.py        # Portfolio page
uv run mlflow ui --backend-store-uri sqlite:///mlflow.db
```

## Context and rules

`context.example/` shows the context files. To use them, rename the folder to `context/` and move
`context.example/models/<id>/context.md` into `models/<id>/`. This changes the agents' prompts, so the run
needs record or live mode with a Gemini key; the offline replay covers the repo without context.

Bank rules go in `proofline.yaml` under `rules:`. They can only make a severity stricter.
