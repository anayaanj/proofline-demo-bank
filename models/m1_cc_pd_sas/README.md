# M1 · Cards behavioural PD scorecard (SAS)

A team-authored sample legacy model for testing Proofline. The SAS code, the 2019 model document and the inventory entry in `model.yaml` (`claimed`) are fictional: they were written to resemble a bank's legacy SAS scorecard. The data is public (below). It is not a real bank model.

| Path | What it is |
|---|---|
| `model.yaml` | Manifest (schema `LegacyModelManifest`) |
| `code/m1_pd_scorecard.sas` | Entry point: derives the characteristics, fits PROC LOGISTIC, scores, applies the decision rules, exports CSVs |
| `code/m1_woe_bins.sas` | `%WOE` / `%APPLY_WOE` macros with the frozen bins, `%include`d by the entry point |
| `docs/legacy_model_doc.md` | The model document as found (v2.3, March 2019) |
| `data_dictionary.csv` | Columns of the input file |
| `baseline/` | Frozen outputs of one run, with `RUNINFO.yaml` and `SHA256SUMS` |

## Provenance and licence

- **Source data:** Yeh, I. (2009). *Default of Credit Card Clients* [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C55S3H. Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). 30,000 anonymised credit card accounts (Taiwan, 2005).
- **Input file:** `data/prepared/m1_taiwan_prepared.csv` (repo root), SHA-256 `a97ac03f858d8d790927dd31c019ee04d391c5a6ee3d617501f348be5a1ae5b2`, built by `data/prepare_m1.py` from the UCI file (`uv run python data/get_data.py m1`). The file is committed because it is the sample of record.
- **Changes to the source:** the columns `X1`…`X23`, `Y` were renamed (`LIMIT_BAL` … `PAY_AMT6`, `BAD_FLAG`), and two columns were added. **Both added columns are synthetic:**

  | Column | How it was made | Seed |
  |---|---|---|
  | `SPLIT = OOT` | 6,000 rows drawn without replacement with probability proportional to exp(0.6·s), where s = 0.5·z(utilisation) − 0.5·z(age) + 0.5·z(months in arrears): a synthetic covariate shift | 42 |
  | `SPLIT = HOLDOUT` | 25% stratified random sample of the remaining rows; the rest is `DEV` | 42 |
  | `OBS_MONTH` | Random month: 2004-07 to 2005-06 for DEV and HOLDOUT, 2005-07 to 2005-09 for OOT | 43 |

  The OOT sample is **synthetic**. Label it as such, with a footnote, wherever its results appear.
- **Personal data:** none. The data is public and anonymised, and `ID` is a sequence number. `SEX`, `AGE`, `MARRIAGE` and `EDUCATION` are present so that fairness can be tested.
- **Attribution for derived outputs:** "Contains data from Yeh, I. (2009), Default of Credit Card Clients, UCI Machine Learning Repository, CC BY 4.0."

## Baseline status

**Provisional baseline from the R twin until the SAS ODA run (D-022).** The disclosure line for slides and reports: *"Parity is against an R emulation of the SAS program; the SAS run is pending."*

- Produced on 2026-11-05 with R 4.6.1 (2026-06-24, aarch64-apple-darwin) by `Rscript scripts/baselines/m1_twin.R data/prepared/m1_taiwan_prepared.csv legacy_models/m1_cc_pd_sas/baseline`. That script is an emulation of `code/m1_pd_scorecard.sas` and lives outside this folder. It writes the same files, with the same column names, as the SAS program's `%EXP` calls.
- Frozen with `uv run python scripts/baseline.py freeze m1 --engine "R 4.6.1 emulation of m1_pd_scorecard.sas"`.
- Numbers are written with 17 significant digits. `bins.csv` and `scaling.json` were written by the author from the code constants, and `freeze` checks them against the code and the data.

| File | Content |
|---|---|
| `coefficients.csv` | PROC LOGISTIC parameter estimates: Variable, DF, Estimate, StdErr, WaldChiSq, ProbChiSq |
| `scored.csv` | One row per account: ID, SPLIT, OBS_MONTH, BAD_FLAG, the 12 `W_*` WoE values, XB, PHAT, PD, PD_ADJ, SCORE, BAND, DECISION, OVR_CODE |
| `score_bands.csv` | SPLIT × BAND: N, N_BAD, BAD_RATE, SCORE_MIN, SCORE_MAX |
| `ifrs9_pd_feed.csv` | ID, OBS_MONTH, PD_ADJ, as written by the program |
| `bins.csv` | Variable, bin, lower, upper, inclusivity, WoE, n_dev, bad_rate_dev |
| `scaling.json` | Scaling constants, rounding, cut-off, overrides and bands, as implemented in the code |
| `logs/` | Engine log (and, after the SAS run, the SAS log and listing) |
| `RUNINFO.yaml`, `SHA256SUMS` | Run metadata and checksums |

**Integrity.** Run `uv run python scripts/baseline.py verify m1`, or `cd baseline && shasum -a 256 -c SHA256SUMS`. The parity harness refuses to run if this fails. Never open a baseline CSV in Excel: re-saving it changes the bytes.

## Running the SAS program on SAS OnDemand for Academics (for the team member with an ODA account)

The run is manual (`run: {engine: sas_oda, mode: manual}`) and takes under a minute.

1. Sign in at https://welcome.oda.sas.com and open **SAS Studio**.
2. In the left pane, open **Server Files and Folders** and right-click **Files (Home)** → **New** → **Folder**: create `m1`. Inside `m1` create three folders: `code`, `data` and `out`. The names are lower case and must match exactly, because the program builds its paths from your home folder (`%sysget(HOME)/m1`).
3. Upload the files without opening or editing them. Right-click a folder → **Upload Files**:
   - into `m1/data`: `data/prepared/m1_taiwan_prepared.csv` from the repo (3.3 MB);
   - into `m1/code`: `legacy_models/m1_cc_pd_sas/code/m1_pd_scorecard.sas` and `legacy_models/m1_cc_pd_sas/code/m1_woe_bins.sas`.
4. Open `m1/code/m1_pd_scorecard.sas` (double-click) and press **Run** (F3). The program sends its log to `m1/out/m1_run.log`, so the SAS Studio **Log** tab stays nearly empty. That is expected.
5. Right-click `m1/out` → **Refresh**. It must contain six files: `coefficients.csv`, `scored.csv`, `score_bands.csv`, `ifrs9_pd_feed.csv`, `m1_run.log` and `m1_results.html`.
6. Open `m1_run.log` and check:
   - no line starts with `ERROR`;
   - the line `NOTE: SYSVLONG=…` is present (it records the SAS version);
   - the PROC LOGISTIC step reports `Convergence criterion (GCONV=1E-8) satisfied.`;
   - there is no warning about `%SYSGET`.
   Then open `m1_results.html` and check that PROC LOGISTIC shows *Number of Observations Read* 30000 and *Number of Observations Used* 18000.
7. Download all six files: right-click each → **Download File**.
8. Check the export precision. Open the downloaded `scored.csv` in a text editor (not Excel). The `XB`, `PD` and `PD_ADJ` values should have about 15 or 16 significant digits. The program formats every number with `BEST32.` before `PROC EXPORT`; if you see values cut to about 12 characters, stop and report it.
9. Replace the provisional baseline in the repo:
   - copy `coefficients.csv`, `scored.csv`, `score_bands.csv` and `ifrs9_pd_feed.csv` into `legacy_models/m1_cc_pd_sas/baseline/`, overwriting the R-twin files;
   - copy `m1_run.log` (the SAS log) and `m1_results.html` (the listing) into `legacy_models/m1_cc_pd_sas/baseline/logs/`;
   - delete `baseline/logs/m1_twin_run.log`. Keep `bins.csv` and `scaling.json`. `RUNINFO.yaml` and `SHA256SUMS` are rewritten in the next step.
10. Freeze the new baseline:
    ```bash
    uv run python scripts/baseline.py freeze m1 --engine "SAS (ODA)" --run-by "<your name>"
    ```
    `freeze` checks the export against the code constants and the prepared data. It writes `RUNINFO.yaml` (with the SAS version taken from the log) and `SHA256SUMS`, updates `baseline.digest` in `model.yaml`, and compares the SAS output with the R twin: expect a maximum |ΔPD| of about 1e-7 or less and identical decisions.
11. Run `uv run pytest tests/data -q`.
12. Add a `docs/DECISIONS.md` entry for the re-baseline: frozen baselines are immutable, and a re-run needs a new freeze and a log entry (spec 02 §4.5). From then on, label M1 outputs: *"M1 outputs were generated using SAS software (SAS OnDemand for Academics)."*

**Troubleshooting.**
- *`%SYSGET` warning, or "Physical file does not exist":* check the folder names in step 2. If HOME still does not resolve, edit line 6 **of the copy on ODA only** to `%let ROOT = /home/<your-user-id>/m1;`. Your user ID appears in the path of Files (Home), for example `u12345678`. Then pass `--status "baseline of record from the SAS ODA run (D-022); ROOT path edited on ODA"` to `freeze`. Never edit the file in the repo.
- *Garbled numbers in the CSVs:* download again with **Download File**, and do not open the files in a spreadsheet tool before freezing.
