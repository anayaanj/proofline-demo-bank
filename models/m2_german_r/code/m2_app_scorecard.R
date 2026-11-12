# =====================================================================
# APPLICATION SCORECARD (PRIVATE LOANS)  -  build + score
# orig. K. Schmidt 2016 / mods 2019 (TW)        do not change bins w/o MRC approval
# =====================================================================
args <- commandArgs(trailingOnly = TRUE)
IN_FILE  <- if (length(args) > 0) args[1] else "../../../data/prepared/m2_south_german_prepared.csv"
OUT_DIR  <- if (length(args) > 1) args[2] else "../baseline"
PTS0 <- 600; ODDS0 <- 1/19; PDO <- 50     # scaling (bad:good odds)
CUTOFF <- 450
cat(R.version.string, "\n")
app <- read.csv(IN_FILE)
cat("applications read:", nrow(app), "\n")
app$dur_b  <- cut(app$laufzeit, c(-Inf, 9, 15, 24, 36, Inf))
app$amt_b  <- cut(app$hoehe,    c(-Inf, 1400, 2500, 4000, 8000, Inf))
app$age_b  <- cut(app$alter,    c(-Inf, 25, 30, 40, 50, Inf))
app$stat_b <- factor(app$laufkont)
app$hist_b <- factor(ifelse(app$moral %in% c(0, 1), "0-1", ifelse(app$moral == 2, "2", "3-4")))
app$purp_b <- factor(ifelse(app$verw %in% c(1), "newcar", ifelse(app$verw %in% c(2, 3), "used_furn",
                     ifelse(app$verw %in% c(4, 5), "radio_dom", "other"))))
app$sav_b  <- factor(ifelse(app$sparkont %in% c(4, 5), "4-5", as.character(app$sparkont)))
app$emp_b  <- factor(ifelse(app$beszeit %in% c(1, 2), "1-2", as.character(app$beszeit)))
app$fw_b   <- factor(app$gastarb)
app$std_b  <- factor(app$stund)
vars <- c("stat_b","dur_b","hist_b","purp_b","amt_b","sav_b","emp_b","age_b","fw_b","std_b")
dev <- app[app$split == "DEV", ]
calc_woe <- function(x, y) {                 # WoE = ln(%bad / %good), +0.5 on every cell (no empty bins)
  t <- table(x, y); b <- (t[, "1"] + 0.5) / sum(t[, "1"]); g <- (t[, "0"] + 0.5) / sum(t[, "0"])
  log(b / g)
}
WOE <- lapply(vars, function(v) calc_woe(dev[[v]], dev$bad)); names(WOE) <- vars
for (v in vars) app[[paste0("w_", v)]] <- as.numeric(WOE[[v]][as.character(app[[v]])])
dev <- app[app$split == "DEV", ]
# step(glm(...), direction="both")   # 2016 selection - final list frozen, do not re-run
fit <- glm(as.formula(paste("bad ~", paste0("w_", vars, collapse = " + "))), family = binomial(), data = dev)
print(summary(fit))
app$lp    <- predict(fit, newdata = app, type = "link")
app$pd    <- predict(fit, newdata = app, type = "response")
app$score <- round(PTS0 - PDO / log(2) * (log(app$pd / (1 - app$pd)) - log(ODDS0)))
app$decision <- ifelse(app$score >= CUTOFF, "ACCEPT", "DECLINE")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)
co <- summary(fit)$coefficients
write.csv(data.frame(term = rownames(co), estimate = sprintf("%.17g", co[, 1]), std_error = sprintf("%.17g", co[, 2])),
          file.path(OUT_DIR, "coefficients.csv"), row.names = FALSE)
bins <- do.call(rbind, lapply(vars, function(v) data.frame(variable = v, bin = names(WOE[[v]]),
                woe = sprintf("%.17g", WOE[[v]]), n_dev = as.vector(table(dev[[v]])),
                bad_rate_dev = sprintf("%.17g", as.vector(tapply(dev$bad, dev[[v]], mean))))))
write.csv(bins, file.path(OUT_DIR, "bins.csv"), row.names = FALSE)
wv <- paste0("w_", vars)                     # scored extract for MI / decision engine reconciliation
sc <- app[, c("app_id", "split", "bad", wv, "lp", "pd", "score", "decision")]
for (v in c(wv, "lp", "pd")) sc[[v]] <- sprintf("%.17g", sc[[v]])
write.csv(sc, file.path(OUT_DIR, "scored.csv"), row.names = FALSE)
sj <- c(sprintf('"pts0": %s', PTS0), sprintf('"odds0": %.17g', ODDS0), '"odds_definition": "bad:good"',
        sprintf('"pdo": %s', PDO), sprintf('"factor": %.17g', PDO / log(2)),
        sprintf('"offset": %.17g', PTS0 + PDO / log(2) * log(ODDS0)),
        '"score_formula": "round(pts0 - pdo / log(2) * (log(pd / (1 - pd)) - log(odds0)))"',
        '"rounding": "R round(), halves to even"', sprintf('"cutoff": %s', CUTOFF),
        '"decision_rule": "ACCEPT if score >= cutoff, else DECLINE"', '"overrides": []')
writeLines(c("{", paste0("  ", sj, c(rep(",", length(sj) - 1), "")), "}"), file.path(OUT_DIR, "scaling.json"))
cat("scored:", nrow(sc), " accepted:", sum(app$decision == "ACCEPT"), "\n")
