/* M1_WOE_BINS.SAS - FROZEN COARSE CLASSING 2018. WOE=LN(%GOOD/%BAD). AGE,BAL_GRW3 ADDED 2021 */
%macro WOE(V, EDGES, WOES);
  %local I N;
  %let N = %sysfunc(countw(&EDGES, %str( )));
  %do I = 1 %to &N;
    %if &I > 1 %then else;
    if &V < %scan(&EDGES, &I, %str( )) then W_&V = %scan(&WOES, &I, %str( ));
  %end;
  else W_&V = %scan(&WOES, %eval(&N + 1), %str( ));
%mend;
%macro APPLY_WOE;
  %WOE(DLQ_CUR,     1 2 3,                      0.4855 -0.5889 -2.0936 -2.3241)
  %WOE(DLQ_MAX5,    1 3,                        0.4678 -0.9901 -1.7896)
  %WOE(DLQ_CNT6,    1 2 4,                      0.6834 -0.4844 -1.0857 -1.9165)
  %WOE(REV_CNT6,    1 4 6,                      -0.2037 -0.4021 -0.2960 0.8384)
  %WOE(NOUSE_CNT6,  1 4,                        -0.0432 0.0917 0.1937)
  %WOE(PIF_CNT6,    1 4,                        -0.1271 0.1900 0.3164)
  %WOE(UTIL_M1,     0.05 0.30 0.60 0.90,        0.0784 0.4421 -0.0353 -0.2725 -0.2664)
  %WOE(PAYR_M1,     0 0.04 0.10 0.50 1,         -0.0949 -0.5857 0.0441 0.0535 0.2702 0.4655)
  %WOE(LIMIT_BAL,   50000 100000 200000 360000, -0.6945 -0.2207 0.0985 0.3269 0.5370)
  %WOE(PAYAMT_AVG3, 1000 3000 10000,            -0.4702 -0.1844 0.3657 0.7789)
  %WOE(AGE,         25 30 35 45 55,             -0.1666 0.0756 0.1855 0.0048 -0.1506 -0.3676)
  %WOE(BAL_GRW3,    -0.10 0.10 0.30,            -0.2343 -0.0224 0.3404 0.0215)
%mend;
