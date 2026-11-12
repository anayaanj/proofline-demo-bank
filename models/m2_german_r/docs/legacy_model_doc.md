# Application Scorecard (Private Loans) – Technical Note

| | |
|---|---|
| Version | 1.2, February 2017 |
| Model | Application scorecard for unsecured private loans |
| Owner and developer | K. Schmidt, Retail Credit Risk Analytics |
| Status | Approved by the Model Risk Committee, March 2017 |
| Model tier | 2 |
| Last independent validation | February 2017 |
| Next review | June 2018 (annual cycle) |

## 1. Purpose and use

The scorecard ranks new applications for unsecured private loans by their risk of not being repaid as agreed. Underwriting uses the score to accept or decline each application at the point of application. Every characteristic is taken from the application form, the bank's own account records or the credit bureau, as they stand when the application is made.

The scorecard does not set prices or credit limits. Manual referrals are handled by underwriting, outside the model.

## 2. Data and target

**Development data.** 1,000 private-loan applications from the historical loan archive, with application months from January 1973 to December 1975. This is the only archive with fully observed outcomes for every application, which is why it was used for the 2016 development.

**Target.** A loan is *bad* (`bad = 1`) if it was not repaid as agreed (`kredit = 0` in the source extract), and *good* otherwise. The sample holds 300 bad and 700 good loans. Bad loans are oversampled: they make up 30% of the sample, against an expected portfolio bad rate of about 5%.

**Sample split.** The sample is split once, stratified by outcome, into a development sample of 700 applications (70%) and a holdout sample of 300 (30%). The split is stored with the data (`split` = DEV or HOLDOUT) and has not been redrawn since 2016.

**Exclusions.** None. All 1,000 applications are complete, so no imputation is needed.

## 3. Methodology

### 3.1 Characteristics and coarse classes

The scorecard uses ten characteristics. Each is coarse-classed as below. The classes were set in 2016 and must not be changed without MRC approval.

| # | Characteristic | Code variable (source column) | Source | Classes |
|---|---|---|---|---|
| 1 | Checking account status | `stat_b` (`laufkont`) | Bank account records | No checking account · balance below 0 DM · 0 to 199 DM · 200 DM or more, or salary paid in for at least a year |
| 2 | Duration in months | `dur_b` (`laufzeit`) | Application form | up to 9 · 10–15 · 16–24 · 25–36 · over 36 |
| 3 | Credit history | `hist_b` (`moral`) | Credit bureau and bank records | Past payment delays or a critical account (codes 0–1) · no credits taken or all paid back duly (code 2) · existing credits paid back duly so far, or all credits at this bank paid back duly (codes 3–4) |
| 4 | Purpose | `purp_b` (`verw`) | Application form | New car · used car or furniture/equipment · radio/television or domestic appliances · other purposes |
| 5 | Credit amount in DM | `amt_b` (`hoehe`) | Application form | up to 1,400 · 1,401–2,500 · 2,501–4,000 · 4,001–8,000 · over 8,000 |
| 6 | Savings | `sav_b` (`sparkont`) | Application form | Unknown or no savings account · below 100 DM · 100 to 499 DM · 500 DM or more |
| 7 | Length of present employment | `emp_b` (`beszeit`) | Application form | Unemployed or under 1 year · 1 to under 4 years · 4 to under 7 years · 7 years or more |
| 8 | Applicant age in years | `age_b` (`alter`) | Application form | up to 25 · 26–30 · 31–40 · 41–50 · over 50 |
| 9 | Foreign worker | `fw_b` (`gastarb`) | Application form (employment section) | Yes · no |
| 10 | Prior payment deferrals | `std_b` (`stund`) | Credit bureau, at application | Any payment deferral (Stundung) granted by another lender before this application: yes · no |

### 3.2 Weight of evidence

Each class is replaced by its weight of evidence (WoE), estimated on the development sample:

> WoE<sub>k</sub> = ln[ (b<sub>k</sub> + 0.5) / (g<sub>k</sub> + 0.5) ] − ln( B / G )

Here b<sub>k</sub> and g<sub>k</sub> are the numbers of bad and good loans in class k, and B and G are the total numbers of bad and good loans in the development sample. In words, the WoE is the class's log-odds of being bad, with 0.5 added to each count so that no class has an undefined value, measured relative to the log-odds of the whole development sample. A positive WoE means the class is riskier than average.

### 3.3 Model

A logistic regression of `bad` on the ten WoE variables, fitted by maximum likelihood on the 700 development applications. The characteristics were chosen in 2016 by stepwise selection in both directions, and the final list is frozen. Because the WoE is oriented towards bad, every coefficient is expected to be positive, and all ten are.

### 3.4 Calibration

Because bad loans are oversampled (30% in the sample against about 5% in the portfolio), the model intercept is corrected for the sampling with the standard prior correction:

> intercept<sub>portfolio</sub> = intercept<sub>sample</sub> + ln[ (0.05 / 0.95) / (0.30 / 0.70) ]

The predicted PDs are therefore calibrated to the 5% portfolio bad rate. They can be read directly as portfolio probabilities of default.

### 3.5 Score scaling

Scores follow the bank's standard scaling: 600 points at good:bad odds of 50:1, and 20 points to double the odds (PDO 20).

> Score = Offset + Factor × ln(good:bad odds), with Factor = 20 / ln 2 = 28.8539 and Offset = 600 − Factor × ln 50 = 487.1229

Scores are rounded to the nearest whole point.

## 4. Performance

Performance was measured on the final model in February 2017.

| Sample | Applications | Bad rate | Gini |
|---|---|---|---|
| Development | 700 | 30.0% | 0.62 |
| Holdout | 300 | 30.0% | 0.61 |

The holdout Gini is within 0.01 of the development Gini, so there is no sign of overfitting. At the cut-off in section 5, about 67% of development applications are accepted.

## 5. Implementation and decision rules

The scorecard is implemented as an R batch program. Each run rebuilds the coarse classes and the WoE table from the frozen development sample, refits the model on the development sample, and scores every application.

**Decision rule.** Accept if the score is 500 or higher; otherwise decline.

**Overrides.** None are applied within the scorecard.

**Outputs.** These include the coefficient table, the WoE table and a scored file with one row per application.

## 6. Limitations

- The sample is small (1,000 applications), so the WoE of small classes is uncertain. The foreign-worker and savings classes should be watched in monitoring.
- The development archive is old, and the applicant population may have changed since. This is mitigated by quarterly monitoring (section 7).
- The oversampling of bad loans is handled by the prior correction in section 3.4.
- Applicant age is used. Age is a protected characteristic under the Equality Act 2010. Its use is permitted here because it is relevant risk information from a source on which it is reasonable to rely (Schedule 3, paragraph 20A); the supporting evidence is held in fair-lending memo FL-2016-07. Age is the only protected characteristic the scorecard uses: it does not use sex, marital status, nationality or any other protected characteristic.

## 7. Governance and monitoring

- **Ownership.** K. Schmidt (Retail Credit Risk Analytics) owns the model and developed it in 2016.
- **Approval.** Approved by the Model Risk Committee in March 2017 after independent validation in February 2017. Model tier 2.
- **Review cycle.** Annual. The next review is due in June 2018.
- **Monitoring.** Quarterly population stability index (PSI) on the score and on each characteristic; Gini on matured loans once a year.
- **Change control.** Any change to the coarse classes, the characteristic list, the scaling or the cut-off needs MRC approval before implementation, and this note must be updated.
