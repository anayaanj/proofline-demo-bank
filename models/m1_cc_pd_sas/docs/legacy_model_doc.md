# Cards Behavioural PD Scorecard

**Model Documentation, Version 2.3, March 2019**
Retail Credit Risk Analytics · Classification: Internal

| Item | Detail |
|---|---|
| Model name | Cards Behavioural PD Scorecard |
| Inventory reference | CR-PD-0001 |
| Model type | Logistic regression scorecard on weight-of-evidence (WoE) characteristics |
| Portfolio | Credit cards, existing accounts |
| Model owner | J. Murphy, Retail Credit Risk Analytics |
| Model developer | J. Murphy |
| Model tier | Tier 3 |
| Status | Approved for production use |
| Last independent validation | 14 March 2019 (Model Validation, Retail), no open findings |
| Next scheduled review | March 2020 |
| Approving committee | Retail Credit Model Committee (RCMC) |

### Version history

| Version | Date | Author | Summary of changes |
|---|---|---|---|
| 1.0 | May 2018 | J. Murphy | Development documentation for RCMC approval |
| 2.0 | November 2018 | J. Murphy | Validation comments addressed: characteristic definitions, holdout results |
| 2.3 | March 2019 | J. Murphy | Annual review following the validation of 14 March 2019. No change to the model, the scaling or the decision rule |

---

## 1. Purpose and use

1.1 The scorecard ranks existing credit card accounts by their risk of going bad (as defined in section 2.2) and converts that risk into a score.

1.2 **Use.** The score is used for credit-line management only. Each month it determines whether an account is eligible for a credit-limit increase. Eligible accounts are passed to the limit-increase programme run by Cards Credit Strategy.

1.3 **Out of scope.** The model is not used for impairment provisioning (IFRS 9), regulatory capital, pricing, collections or account closure. Any new use requires a model change request and a validation before go-live.

1.4 **Users.** Cards Credit Strategy (decision owner) and Retail Credit Risk Analytics (model owner).

## 2. Data and target

2.1 **Source.** Monthly account-level snapshots from the card management system. Each record holds the credit limit, six months of repayment status, statement balances and payment amounts. Sex, education, marital status and age are held on the development file for portfolio monitoring only.

2.2 **Target definition.** An account is *bad* if it reaches 90 or more days past due at any point in the 12 months after the observation month. All other accounts are *good*. There is no indeterminate category.

2.3 **Sample window.** Observation months January 2016 to December 2017. The development file was extracted and frozen in March 2018.

2.4 **Samples.**

| Sample | Accounts | Definition |
|---|---|---|
| Development | 18,000 | In-time accounts used to fit the model |
| Holdout | 6,000 | 25% stratified random sample of the in-time accounts, held back for testing |
| Out-of-time | 6,000 | Accounts observed from January to March 2018, reserved for ongoing monitoring |
| **Total** | **30,000** | |

2.5 **Bad rate.** 20.5% in the development sample (3,692 bad accounts) and 20.5% in the holdout.

2.6 **Data quality.** There are no missing values. Repayment status uses the codes -2 (no balance), -1 (paid in full), 0 (revolving, minimum paid) and 1 to 9 (months in arrears). Codes -2 and 0 are not defined in the source system dictionary; their meaning was agreed with Cards Operations in 2018.

## 3. Methodology

3.1 **Approach.** Each candidate characteristic was coarse-classed on the development sample and replaced by its weight of evidence, WoE = ln(%good / %bad), so that a higher WoE means lower risk. A logistic regression was then fitted by maximum likelihood on the WoE-transformed characteristics (SAS PROC LOGISTIC), using the development sample only.

3.2 **Characteristic selection.** Forty-one candidate characteristics were reviewed. Selection combined information value (IV), correlation checks and business review. The final list was frozen in April 2018.

3.3 **Final characteristics.** The scorecard uses 10 characteristics. Bins are right-open (lower <= x < upper), and the WoE values are listed from the lowest bin to the highest. IV is measured on the development sample.

| # | Characteristic | Definition | Bin edges | WoE by bin | IV |
|---|---|---|---|---|---|
| 1 | DLQ_CUR | Current arrears: max(PAY_0, 0) | 1, 2, 3 | 0.4855, -0.5889, -2.0936, -2.3241 | 0.749 |
| 2 | DLQ_MAX5 | Worst arrears in months t-2 to t-6: max(0, PAY_2 ... PAY_6) | 1, 3 | 0.4678, -0.9901, -1.7896 | 0.508 |
| 3 | DLQ_CNT6 | Months in arrears (status 1 or more) in the last six | 1, 2, 4 | 0.6834, -0.4844, -1.0857, -1.9165 | 0.768 |
| 4 | REV_CNT6 | Revolving months (status 0) in the last six | 1, 4, 6 | -0.2037, -0.4021, -0.2960, 0.8384 | 0.241 |
| 5 | NOUSE_CNT6 | No-balance months (status -2) in the last six | 1, 4 | -0.0432, 0.0917, 0.1937 | 0.007 |
| 6 | PIF_CNT6 | Paid-in-full months (status -1) in the last six | 1, 4 | -0.1271, 0.1900, 0.3164 | 0.033 |
| 7 | UTIL_M1 | Utilisation: BILL_AMT1 / LIMIT_BAL | 0.05, 0.30, 0.60, 0.90 | 0.0784, 0.4421, -0.0353, -0.2725, -0.2664 | 0.060 |
| 8 | PAYR_M1 | Payment ratio: PAY_AMT1 / BILL_AMT2, or -1 when BILL_AMT2 <= 0 | 0, 0.04, 0.10, 0.50, 1 | -0.0949, -0.5857, 0.0441, 0.0535, 0.2702, 0.4655 | 0.119 |
| 9 | LIMIT_BAL | Credit limit | 50,000; 100,000; 200,000; 360,000 | -0.6945, -0.2207, 0.0985, 0.3269, 0.5370 | 0.145 |
| 10 | PAYAMT_AVG3 | Average payment over the last three months: mean(PAY_AMT1 ... PAY_AMT3) | 1,000; 3,000; 10,000 | -0.4702, -0.1844, 0.3657, 0.7789 | 0.163 |

Coefficients and the points allocation are held in the model build pack (RCMC paper 2018-05) and are not reproduced here.

3.4 **Score scaling.** A score of 600 corresponds to good:bad odds of 50:1, and every 20 points double the odds (PDO = 20). Score = 487.1229 + 28.8539 × ln(odds), rounded to the nearest whole point, where odds = (1 - PD) / PD and PD is the scorecard PD.

3.5 **Score bands.**

| Band | Score |
|---|---|
| A | 560 and above |
| B | 540 to 559 |
| C | 520 to 539 |
| D | 500 to 519 |
| E | 480 to 499 |
| F | below 480 |

## 4. Performance

4.1 **Discrimination at development.**

| Sample | Gini | KS |
|---|---|---|
| Development | 0.62 | 0.47 |
| Holdout | 0.60 | 0.45 |

4.2 The validation of 14 March 2019 reproduced these results. Out-of-time results are reported through quarterly monitoring and are not repeated here.

## 5. Implementation and decision rule

5.1 **Platform.** SAS 9.4, monthly batch. Program `m1_pd_scorecard.sas` derives the characteristics, applies the frozen bins held in `m1_woe_bins.sas`, estimates the model on the frozen development sample and scores all accounts.

5.2 **Post-model adjustments.** None. No adjustments are applied: the PD produced by the scorecard is used as it stands, with no overlays, scaling factors or management adjustments.

5.3 **Decision rule.** An account is eligible for a credit-limit increase (decision APPROVE) when its score is 540 or above, that is, bands A and B. All other accounts are DECLINE. At this cut-off the expected approval rate is 49% of scored accounts.

5.4 **Overrides.** None. The decision follows the cut-off for every account, and Cards Credit Strategy does not override individual decisions.

5.5 **Outputs.** The batch produces one business output: the account-level file of score, band and decision used by the limit-increase programme. The model has no other downstream consumers.

## 6. Limitations

6.1 The target uses a 12-month outcome window, so the score ranks accounts on 12-month risk. It is not a point-in-time or lifetime PD.

6.2 Behavioural history is limited to the last six months.

6.3 Repayment status codes -2 and 0 rely on the 2018 interpretation agreed with Cards Operations (section 2.6).

6.4 **Protected characteristics.** No protected characteristics are used as model inputs. Age, sex and marital status are excluded from the scorecard and are used only to monitor outcomes by group.

6.5 The model has not been validated for any use other than credit-line management (section 1.3).

## 7. Governance

7.1 **Ownership.** Model owner and developer: J. Murphy, Retail Credit Risk Analytics.

7.2 **Tier.** Tier 3: limited materiality, because the decisions concern limit increases on existing accounts and can be reversed.

7.3 **Validation.** Independent validation was completed on 14 March 2019 with no open findings. Next scheduled review: March 2020.

7.4 **Monitoring.** A quarterly monitoring pack goes to RCMC: population stability of the score and of each characteristic, Gini on recent outcomes, and the approval rate against the expected 49%.

7.5 **Change control.** Any change to the characteristics, bins, coefficients, scaling, cut-off, decision rule or post-model adjustments requires RCMC approval and an update to this document before implementation.

### Sign-off

| Role | Name | Date |
|---|---|---|
| Model owner | J. Murphy | 20 March 2019 |
| Head of Retail Credit Risk Analytics | S. Kelly | 22 March 2019 |
| Model Validation | P. Byrne | 14 March 2019 |

---

## Appendix A. Glossary

| Term | Meaning |
|---|---|
| WoE | Weight of evidence of a bin: ln(%good / %bad) |
| IV | Information value: the sum over bins of (%good - %bad) × WoE |
| Gini | 2 × AUC - 1, a measure of rank-ordering power |
| KS | Kolmogorov-Smirnov statistic: the maximum gap between the cumulative score distributions of goods and bads |
| PDO | Points to double the odds |
| PD | Probability of default (here: of going bad, section 2.2) |
