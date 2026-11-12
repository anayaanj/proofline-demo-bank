# M2 · Private loan application scorecard (R)

A legacy application scorecard for the Proofline model-risk factory. It accepts or declines new applications for unsecured private loans. The Proofline team wrote it in the style of a bank's 2016–2019 base-R scorecard. It is not a real bank's model.

## Contents

| Path | What it is |
|---|---|
| `model.yaml` | Manifest, validated by `mrf.schemas.LegacyModelManifest` |
| `code/m2_app_scorecard.R` | The scorecard program (base R only) |
| `docs/legacy_model_doc.md` | The model's existing documentation (technical note, February 2017) |
| `data_dictionary.csv` | Column, type, meaning and allowed values for the prepared data |
| `baseline/` | Outputs of one frozen run of the code, with `SHA256SUMS` and `RUNINFO.yaml` |

## Data provenance and licence

- **Source.** *South German Credit (UPDATE)* [Dataset] (2020). UCI Machine Learning Repository, dataset 573. https://doi.org/10.24432/C5QG88. Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Background: Grömping, U. (2019), *South German Credit Data: Correcting a Widely Used Data Set*, Report 4/2019, Beuth University of Applied Sciences Berlin.
- **Download.** The zip is fetched from the UCI static URL and checked against a pinned SHA-256 (`data/prepare_m2.py`; registry in `data/SOURCES.yaml`). The `ucimlrepo` package cannot import this dataset.
- **Prepared file.** `data/prepared/m2_south_german_prepared.csv`: 1,000 rows, SHA-256 `c30ea574…f6c872`, built by `data/prepare_m2.py` (seed 42). It is committed, and it is the sample of record.
- **Changes made to the source (CC BY 4.0 asks us to say so).** The prepared file adds columns that the team derived or simulated. The register of synthetic augmentation is kept outside this folder, in `data/SOURCES.yaml` and the repository README.
- **Personal data.** None. The source is anonymised public data, and row IDs are sequence numbers.

## How the baseline was produced

Run from the repository root on 5 Nov 2026 with R 4.6.1 (2026-06-24) on macOS (arm64). It uses base R only and takes under a second:

```bash
Rscript legacy_models/m2_german_r/code/m2_app_scorecard.R data/prepared/m2_south_german_prepared.csv \
  legacy_models/m2_german_r/baseline > legacy_models/m2_german_r/baseline/logs/m2_run.log 2>&1
cd legacy_models/m2_german_r/baseline && shasum -a 256 *.csv *.json RUNINFO.yaml logs/* > SHA256SUMS
```

| File | Content |
|---|---|
| `coefficients.csv` | term, estimate, std_error (17 significant digits) |
| `bins.csv` | variable, bin, woe, n_dev, bad_rate_dev |
| `scored.csv` | One row per application: app_id, split, bad, per-row WoE (`w_*`), linear predictor `lp`, `pd`, `score`, `decision` |
| `scaling.json` | Scaling constants, rounding rule and cut-off, as implemented in the code |
| `logs/m2_run.log` | The R console output |
| `RUNINFO.yaml` | Engine and version, run time, who ran it, SHA-256 of the input and the code, row counts |

To verify, run `cd baseline && shasum -a 256 -c SHA256SUMS`. The manifest's `baseline.digest` is the SHA-256 of `SHA256SUMS`. A frozen baseline is immutable: a re-run needs a new freeze and an entry in `docs/DECISIONS.md` (spec 02 §4.5). Never open the CSVs in Excel, because re-saving changes their bytes.
