/* ================================================================
   M1_PD_SCORECARD.SAS   CARDS BEHAVIOURAL PD - CREDIT LINE MGMT
   JM 04/2018 | AB 04/2020 OVERLAY | AB 02/2021 +AGE +BAL_GRW3
   AB 06/2022 CUTOFF 540->520 | SAMPLE FROZEN 2018 - DO NOT RESAMPLE
   ================================================================ */
%let ROOT    = %sysget(HOME)/m1;
%let OUT     = &ROOT/out;
%let FACTOR  = 28.8539;
%let OFFSET  = 487.1229;
%let CUTOFF  = 520;
%let PMA_F   = 1.15;                 /* TEMP COVID OVERLAY - REMOVE 31DEC2021 */
%let MODVARS = W_DLQ_CUR W_DLQ_MAX5 W_DLQ_CNT6 W_REV_CNT6 W_NOUSE_CNT6 W_PIF_CNT6
               W_UTIL_M1 W_PAYR_M1 W_LIMIT_BAL W_PAYAMT_AVG3 W_AGE W_BAL_GRW3;
options missing=' ';
proc printto log="&OUT/m1_run.log" new; run;
ods html5 (id=keep) file="&OUT/m1_results.html";    /* named: SAS Studio has its own HTML5 */
%put NOTE: SYSVLONG=&sysvlong;
%include "&ROOT/code/m1_woe_bins.sas";

data BASE;
  infile "&ROOT/data/m1_taiwan_prepared.csv" dsd firstobs=2 truncover;
  input ID LIMIT_BAL SEX EDUCATION MARRIAGE AGE PAY_0 PAY_2-PAY_6
        BILL_AMT1-BILL_AMT6 PAY_AMT1-PAY_AMT6 BAD_FLAG SPLIT :$7. OBS_MONTH :$7.;
  array P{6} PAY_0 PAY_2-PAY_6;
  DLQ_CUR  = max(PAY_0, 0);
  DLQ_MAX5 = max(0, of PAY_2-PAY_6);
  DLQ_CNT6 = 0; REV_CNT6 = 0; NOUSE_CNT6 = 0; PIF_CNT6 = 0;
  do I = 1 to 6;
    DLQ_CNT6 + (P{I} >= 1);   REV_CNT6 + (P{I} = 0);
    NOUSE_CNT6 + (P{I} = -2); PIF_CNT6 + (P{I} = -1);
  end;
  UTIL_M1 = BILL_AMT1 / LIMIT_BAL;
  if BILL_AMT2 > 0 then PAYR_M1 = PAY_AMT1 / BILL_AMT2; else PAYR_M1 = -1;
  PAYAMT_AVG3 = mean(of PAY_AMT1-PAY_AMT3);
  BAL_GRW3 = (BILL_AMT1 - BILL_AMT4) / LIMIT_BAL;
  %APPLY_WOE
  BAD_DEV = BAD_FLAG;
  if SPLIT ne 'DEV' then BAD_DEV = .;          /* SCORE HOLDOUT/OOT IN SAME PASS */
  drop I;
run;

proc logistic data=BASE;
  model BAD_DEV = &MODVARS;
  output out=SCORED xbeta=XB p=PHAT;
  ods output ParameterEstimates=PE;
run;

data SCORED;
  set SCORED;
  length BAND $1 DECISION $7 OVR_CODE $3;
  PD     = 1 / (1 + exp(XB));
  PD_ADJ = min(PD * &PMA_F, 0.9999);
  SCORE  = round(&OFFSET + &FACTOR * log((1 - PD_ADJ) / PD_ADJ), 1);
  if      SCORE >= 560 then BAND = 'A';
  else if SCORE >= 540 then BAND = 'B';
  else if SCORE >= 520 then BAND = 'C';
  else if SCORE >= 500 then BAND = 'D';
  else if SCORE >= 480 then BAND = 'E';
  else BAND = 'F';
  if SCORE >= &CUTOFF then DECISION = 'APPROVE'; else DECISION = 'DECLINE';
  if UTIL_M1 >= 1 and DECISION = 'APPROVE' then do; DECISION = 'DECLINE'; OVR_CODE = 'P01'; end;
  if LIMIT_BAL >= 500000 and DECISION = 'DECLINE' and DLQ_CUR < 2 and SCORE >= &CUTOFF - 15
     then do; DECISION = 'APPROVE'; OVR_CODE = 'V01'; end;          /* VIP - RISK DIR 2019 */
run;

proc sql;
  create table BANDS as
  select SPLIT, BAND, count(*) as N, sum(BAD_FLAG) as N_BAD, mean(BAD_FLAG) as BAD_RATE,
         min(SCORE) as SCORE_MIN, max(SCORE) as SCORE_MAX
  from SCORED group by SPLIT, BAND;
quit;

%macro EXP(DS, F);
  data _X / view=_X; set &DS; format _numeric_ best32.; run;   /* default BEST12. truncates */
  proc export data=_X outfile="&OUT/&F" dbms=csv replace; run;
%mend;
%EXP(PE, coefficients.csv)
%EXP(SCORED(keep=ID SPLIT OBS_MONTH BAD_FLAG W_: XB PHAT PD PD_ADJ SCORE BAND DECISION OVR_CODE), scored.csv)
%EXP(BANDS, score_bands.csv)
%EXP(SCORED(keep=ID OBS_MONTH PD_ADJ), ifrs9_pd_feed.csv)          /* FINANCE FEED */
ods html5 (id=keep) close;
proc printto; run;
