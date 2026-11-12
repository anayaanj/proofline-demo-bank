# Card Fraud Detection Model – Documentation

| | |
|---|---|
| Version | 2.1, September 2021 (first issued May 2019) |
| Model | Card transaction fraud score |
| Owner | M. Byrne, Fraud Analytics |
| Status | In production |
| Model tier | 2 |
| Last independent validation | October 2021 |
| Next review | October 2022 |

## 1. Purpose and use

The model scores card transactions for the probability that they are fraudulent and raises alerts for the fraud operations team to review. It is used for alerting only: it does not decline transactions automatically, and every alert is worked by an analyst.

## 2. Data

**Source.** An extract of card transactions supplied by the card processor, covering two days in September 2013: 284,807 transactions, of which 492 (0.17%) are confirmed fraud. There are no missing values.

**Fields.**
- `Time`: seconds elapsed since the first transaction in the extract.
- `Amount`: the transaction amount.
- `V1` to `V28`: principal components of confidential transaction attributes. The processor applies the transformation before the data reaches the bank, so the original attributes are not available.
- `Class`: the target, 1 for a confirmed fraud and 0 for a genuine transaction.

**Time-based split.** The development window is hours 0 to 32 (162,525 transactions, 356 frauds). The validation window is hours 32 to 40 (62,340 transactions, 59 frauds). The out-of-time window is hours 40 to 48 (59,942 transactions, 77 frauds).

## 3. Methodology

**Model.** Logistic regression (scikit-learn `LogisticRegression`, L2 penalty, C = 1.0, no class weighting) on standardised inputs, fitted on the development window.

**Inputs.** The 2021 feature review removed three components with low importance (`V13`, `V15` and `V22`). The model therefore uses the remaining 25 principal components plus two engineered features:
- hour of day, derived from `Time`;
- log(1 + `Amount`).

Raw `Time` and `Amount` are not used directly.

**Score.** The predicted probability of fraud, between 0 and 1.

## 4. Performance

Performance was measured on the logistic regression in September 2021. Accuracy is not reported because fraud prevalence is only 0.17%.

| Window | Transactions | Frauds | PR-AUC | Recall at 0.50 | Precision at 0.50 |
|---|---|---|---|---|---|
| Validation (hours 32–40) | 62,340 | 59 | 0.56 | 0.44 | 0.60 |
| Out-of-time (hours 40–48) | 59,942 | 77 | 0.68 | 0.49 | 0.69 |

## 5. Implementation and decision rules

The model runs as a Python batch job. Each run refits the model on the development window and scores every transaction.

**Alert rule.** An alert is raised when the score is 0.50 or higher. At this threshold, about 0.07% of validation transactions and 0.09% of out-of-time transactions are alerted.

**Business rules and overrides.** None. Every alert comes from the model score.

**Outputs.** These include a scored file with the score and the alert flag for each transaction.

## 6. Limitations

- The data covers only two days, so it shows no weekly or seasonal patterns, and it dates from 2013.
- The principal components are opaque, so individual alerts cannot be explained in terms of the original transaction attributes.
- The data holds no protected characteristics, so the fairness of alerting across customer groups cannot be assessed.
- Fraud is rare (0.17%), so PR-AUC, recall and precision are the primary performance measures.

## 7. Governance

- **Ownership.** M. Byrne (Fraud Analytics) owns the model.
- **Validation.** Independently validated in October 2021, on the logistic regression described in this document. Model tier 2.
- **Review cycle.** Annual. The next review is due in October 2022.
- **Change control.** Any change to the model type, the inputs or the alert threshold needs independent validation before it goes into production, and this document must be updated.
