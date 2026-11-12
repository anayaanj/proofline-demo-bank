# Demo bank model repo

A model repo as a bank would keep it, connected to Proofline. Test models with planted defects, on public data.

```
proofline.yaml            settings: agent models, threshold overrides
models/<id>/model.yaml    one manifest per model
data/prepared/            model input data (paths in model.yaml are relative to this repo)
```

Run Proofline against it:

```bash
cd ../proofline
MRF_MODEL_REPO=../proofline-demo-bank uv run mrf models
```
