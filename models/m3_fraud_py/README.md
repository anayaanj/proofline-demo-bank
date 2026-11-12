# M3 · Card transaction fraud score (Python)

A legacy fraud model for the Proofline model-risk factory. It scores card transactions and raises alerts for analysts to review. The Proofline team wrote it in the style of a bank's 2019–22 Python fraud model. It is not a real bank's model.

## Contents

| Path | What it is |
|---|---|
| `model.yaml` | Manifest, validated by `mrf.schemas.LegacyModelManifest` |
| `code/fraud_model_v3.py` | The model program (pandas, scikit-learn) |
| `docs/legacy_model_doc.md` | The model's existing documentation (version 2.1, September 2021) |
| `data_dictionary.csv` | Column, type, meaning and allowed values for the source data |
| `baseline/` | Outputs of one frozen run of the code, with `SHA256SUMS` and `RUNINFO.yaml` |

## Data provenance and licence

- **Source.** *Credit Card Fraud Detection*, Machine Learning Group of the Université Libre de Bruxelles (ULB) with Worldline: 284,807 card transactions made over two days in September 2013, 492 of them fraudulent. Published on Kaggle (`mlg-ulb/creditcardfraud`) and mirrored on [OpenML as dataset 1597](https://www.openml.org/d/1597). Cite: Dal Pozzolo, A., Caelen, O., Johnson, R. A. and Bontempi, G. (2015), *Calibrating Probability with Undersampling for Unbalanced Classification*, IEEE Symposium Series on Computational Intelligence (SSCI).
- **Licence.** The database is under the [Open Database License (ODbL) 1.0](https://opendatacommons.org/licenses/odbl/1-0/) and its contents under the [Database Contents License (DbCL) 1.0](https://opendatacommons.org/licenses/dbcl/1-0/). Any derivative database we share, including the test sample below, is offered under the ODbL 1.0 with this attribution.
- **Download.** The parquet comes from the OpenML URL and is checked against a pinned SHA-256 (`data/prepare_m3.py`; registry in `data/SOURCES.yaml`). It is used instead of `fetch_openml`, because scikit-learn drops the `Time` column, which OpenML marks as the row identifier.
- **Prepared files.**
  - `data/interim/m3_ulb_fraud.parquet`: a byte-identical copy of the verified source (SHA-256 `b7efcb35…ad9496d`). It is git-ignored and is created by `uv run python data/prepare_m3.py`.
  - `data/prepared/m3_fraud_sample.csv`: a committed 5,000-row test sample, with every fraud plus 4,508 other transactions drawn with seed 42. It is for fast tests only, never for reported metrics.
- **Augmentation.** None. The split is the real time order.
- **Personal data.** None. `V1`–`V28` are principal components supplied by the data provider.

## How the baseline was produced

Run from the repository root on 5 Nov 2026 with Python 3.13.5, scikit-learn 1.9.1, numpy 2.5.4, pandas 3.1.1 and pyarrow 26.0.1 on macOS (arm64). It takes about 10 s:

```bash
uv run python data/prepare_m3.py
uv run python legacy_models/m3_fraud_py/code/fraud_model_v3.py data/interim/m3_ulb_fraud.parquet \
  legacy_models/m3_fraud_py/baseline > legacy_models/m3_fraud_py/baseline/logs/m3_run.log 2>&1
cd legacy_models/m3_fraud_py/baseline && shasum -a 256 *.csv *.json RUNINFO.yaml logs/* > SHA256SUMS
```

| File | Committed | Content |
|---|---|---|
| `scored.csv` | **No** (ODbL share-alike; 12.8 MB) | One row per transaction: row_id, Time, split, Class, score, alert, alert_reason |
| `model_params.json` | Yes | Model class, hyperparameters, feature list, threshold, high-value rule |
| `logs/m3_run.log` | Yes | Console output |
| `RUNINFO.yaml` | Yes | Engine and versions, run time, who ran it, SHA-256 of the input and the code, row counts |

`SHA256SUMS` lists `scored.csv` even though it is not committed. In a fresh clone, run `shasum -a 256 -c --ignore-missing SHA256SUMS`. After regenerating with the commands above, run `shasum -a 256 -c SHA256SUMS`. The model is not pickled: the factory re-runs the code rather than loading saved artefacts. Gradient-boosting results can differ in the last digits on other hardware or thread counts, so the tests compare regenerated scores with a tolerance. The manifest's `baseline.digest` is the SHA-256 of `SHA256SUMS`, and a frozen baseline is immutable (spec 02 §4.5).
