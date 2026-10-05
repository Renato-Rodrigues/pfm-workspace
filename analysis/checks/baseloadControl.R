# The baseload control and the soft selection keys: the evidence behind ADR 0048.
#   Rscript analysis/checks/baseloadControl.R [group] [compareGroup]      (default v6 v5)
# Four questions, all estimation-side (history only; the scenario-panel unit fix of PITFALLS 28
# does not change any of them):
#   1. Which terms carry the VIF of the X-2079 design, in each group? (v6: the Bulk incumbent
#      share against the hydro/nuclear/geothermal control; Iceland's geothermal tips it over 6.)
#   2. What does the control do? The mean regression with and without it, population kept: the
#      Bulk incumbent-share coefficient, and the countries whose fit moves (nuclear/hydro ones).
#   3. What the soft keys decide: the deployed spec under each softVifGate / inferenceTGate.
#   4. How many specs the soft VIF key demotes, per control set and channel set.
# The mean regression is replicated by OLS on the squeezed logit of the index (the satP engine,
# MODEL.md 2.1) with standardized drivers and products of standardized drivers as interactions;
# main effects match sweep.rds to about 0.02. It stands in for the frontier's efficiency ratio,
# which the coupling reads; the omitted-variable argument is the same for both.
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args) >= 1) args[1] else "v6"
g0 <- if (length(args) >= 2) args[2] else "v5"
suppressMessages(library(magclass))

panelOf <- function(group) {
  h <- jsonlite::fromJSON(file.path("output/pfm", group, "manifest.json"))$panel_hash
  f <- paste0("panel_", h, ".rds")
  cand <- c(file.path("output/pfm/fit-cache/panels", f), file.path("output/remind-inputs", group, "panels", f))
  hit <- cand[file.exists(cand)][1]
  if (is.na(hit)) stop("panel ", f, " not found in: ", paste(cand, collapse = ", "))
  readRDS(hit)
}
fe <- read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_EU_OECDp.csv")
mmOf <- function(s) if (is.data.frame(s$maximin)) s$maximin else s$maximin[[1]]

GE <- "Government Effectiveness (WGI)"; VA <- "Vertical Accountability (VDem)"
BOTH <- c("Innovator Power", "Incumbent Power", "Incumbent Power pc")
G <- "GDP per Capita (Q-centred)"; POP <- "Population"; H <- "Hydro Nuclear Share"

# The estimation sample: countries with the outcome, Estonia excluded (PITFALLS 27), 2001-last.
sample <- function(p, sec, drop = character(0)) {
  last <- max(getYears(p, as.integer = TRUE)); yrs <- 2001:last
  ps <- p[, yrs, paste0("Policy Stringency|", sec)]
  cs <- setdiff(getItems(p, 1)[apply(is.finite(ps) & ps != 0, 1, any)], c("EST", drop))
  list(cs = cs, yrs = yrs)
}
column <- function(p, s, v) { a <- as.array(p[s$cs, s$yrs, v]); as.vector(t(matrix(a, nrow = length(s$cs)))) }
vif <- function(X) {
  X <- X[stats::complete.cases(X), , drop = FALSE]
  stats::setNames(vapply(seq_len(ncol(X)), function(j) {
    f <- stats::lm.fit(cbind(1, X[, -j, drop = FALSE]), X[, j])
    1 / (sum(f$residuals^2) / sum((X[, j] - mean(X[, j]))^2))
  }, numeric(1)), colnames(X))
}
# VIF design as computeVIF() builds it: main effects, controls and the trend (no FE, no interactions).
vifDesign <- function(p, sec, ctl, drop = character(0)) {
  s <- sample(p, sec, drop)
  X <- sapply(c(paste0(BOTH, "|", sec), GE, VA, ctl), function(v) column(p, s, v))
  colnames(X) <- c(BOTH, GE, VA, ctl)
  cbind(X, trend = 1 / (1 + exp(-0.2 * (rep(s$yrs, length(s$cs)) - 2010))))
}
meanRegression <- function(p, sec, ctl) {
  s <- sample(p, sec); z <- function(x) (x - mean(x)) / stats::sd(x)
  X <- sapply(c(paste0(BOTH, "|", sec), GE, VA, ctl), function(v) z(column(p, s, v)))
  colnames(X) <- make.names(c(BOTH, GE, VA, ctl))
  for (a in make.names(BOTH)) for (q in make.names(c(GE, VA))) {
    X <- cbind(X, X[, a] * X[, q]); colnames(X)[ncol(X)] <- paste0(a, "_x_", q)
  }
  yr <- rep(s$yrs, length(s$cs)); cty <- rep(s$cs, each = length(s$yrs))
  X <- cbind(X, logisticTimeTrend = z(1 / (1 + exp(-0.2 * (yr - 2010)))))
  r <- fe$RegionCode[match(cty, fe$CountryCode)]
  X <- cbind(X, regionFEOECD = as.numeric(r == "OECD"), regionFEother = as.numeric(r == "other"))
  S <- column(p, s, paste0("Policy Stringency|", sec)); n <- length(S)
  y <- stats::qlogis(((S / 10) * (n - 1) + 0.5) / n)
  m <- stats::lm(y ~ X)
  list(coef = stats::setNames(stats::coef(m), sub("^X", "", names(stats::coef(m)))), r2 = summary(m)$r.squared,
       rows = data.frame(country = cty, year = yr, y = y, fit = stats::fitted(m)))
}

out <- list(group = g, compareGroup = g0, generated = Sys.time())
P <- list(); P[[g0]] <- panelOf(g0); P[[g]] <- panelOf(g)

# 1. VIF sources ------------------------------------------------------------------------------
cat("1. VIF of the X-2079 design (main effects, controls, trend), by term\n")
out$vif <- do.call(rbind, lapply(names(P), function(k) do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) {
  rbind(data.frame(group = k, sector = sec, dropped = "none", t(vif(vifDesign(P[[k]], sec, c(G, POP, H)))), check.names = FALSE),
        data.frame(group = k, sector = sec, dropped = "ISL", t(vif(vifDesign(P[[k]], sec, c(G, POP, H), "ISL"))), check.names = FALSE))
}))))
print(cbind(out$vif[, 1:3], round(out$vif[, -(1:3)], 2)), row.names = FALSE)
out$corIncumbentBaseload <- vapply(names(P), function(k) {
  s <- sample(P[[k]], "Bulk"); stats::cor(column(P[[k]], s, "Incumbent Power|Bulk"), column(P[[k]], s, H)) }, numeric(1))
cat("cor(Incumbent Power|Bulk, Hydro Nuclear Share):", paste(sprintf("%s %.2f", names(P), out$corIncumbentBaseload)), "\n")

# 2. What the control does ----------------------------------------------------------------------
cat("\n2. Mean regression, X-2079 design,", g, ": with the baseload control vs population only\n")
out$control <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  w <- meanRegression(P[[g]], sec, c(G, POP, H)); wo <- meanRegression(P[[g]], sec, c(G, POP))
  k <- c("Incumbent.Power", "Incumbent.Power.pc", "Innovator.Power", "Government.Effectiveness..WGI.", "Population")
  cf <- data.frame(term = k, withControl = w$coef[k], populationOnly = wo$coef[k], row.names = NULL)
  rr <- merge(w$rows, wo$rows[, c("country", "year", "fit")], by = c("country", "year"), suffixes = c(".with", ".without"))
  rr <- rr[rr$year >= max(rr$year) - 4, ]
  a <- stats::aggregate(cbind(y, fit.with, fit.without) ~ country, rr, mean)
  a$residWith <- a$y - a$fit.with; a$residWithout <- a$y - a$fit.without; a$shift <- a$residWithout - a$residWith
  a$rankWith <- rank(-a$residWith); a$rankWithout <- rank(-a$residWithout)
  last <- max(getYears(P[[g]], as.integer = TRUE))
  a$baseload <- as.numeric(P[[g]][a$country, last, H]); a$incumbentShare <- as.numeric(P[[g]][a$country, last, paste0("Incumbent Power|", sec)])
  cat(sprintf("  %s  R2 %.3f vs %.3f | residual-rank Spearman %.3f | median |shift| %.3f\n", sec, w$r2, wo$r2,
              stats::cor(a$residWith, a$residWithout, method = "spearman"), stats::median(abs(a$shift))))
  print(cbind(cf[, 1, drop = FALSE], round(cf[, -1], 3)), row.names = FALSE)
  list(coef = cf, r2 = c(with = w$r2, populationOnly = wo$r2), countries = a[order(a$shift), ])
})
cat("  Bulk, most affected countries (residual = observed - fitted, logit, last five years; rank 1 = most over-achieving):\n")
x <- out$control$Bulk$countries; x <- rbind(utils::head(x, 6), utils::tail(x, 6))
print(cbind(x["country"], round(x[, c("baseload", "incumbentShare", "residWith", "residWithout", "shift")], 2),
            x[, c("rankWith", "rankWithout")]), row.names = FALSE)

# 3. What the soft keys decide -------------------------------------------------------------------
cat("\n3. First near-tie band of", g, "ordered under each soft-key setting (deployed = first)\n")
s <- readRDS(file.path("output/pfm", g, "sweep.rds")); m <- mmOf(s); r <- s$results
m$vif <- tapply(r$maxVIF, r$model, max)[m$model]
m$tmin <- suppressWarnings(tapply(r$minSigTheoryT, r$model, function(v) min(v, na.rm = TRUE)))[m$model]
pass <- m[m$gatePass, ]; band <- pass[pass$minDeltaR2 >= max(pass$minDeltaR2) - 0.025, ]
boot <- tryCatch(readRDS(file.path("output/pfm", g, "selection-bootstrap.rds"))$specFreq, error = function(e) NULL)
settings <- data.frame(softVifGate = c(6, 7, 8, Inf, 6, Inf), inferenceTGate = c(2.33, 2.33, 2.33, 2.33, 0, 0))
out$softKeys <- do.call(rbind, lapply(seq_len(nrow(settings)), function(i) {
  fr <- as.integer(band$vif > settings$softVifGate[i]) + as.integer(!is.na(band$tmin) & band$tmin < settings$inferenceTGate[i])
  o <- band[order(band$idleControl, fr, band$trendKey, band$sumBIC), ]
  data.frame(settings[i, ], first = o$model[1], second = o$model[2],
             bootstrapShareFirst = if (is.null(boot) || is.na(boot[o$model[1]])) 0 else as.numeric(boot[o$model[1]]))
}))
print(out$softKeys, row.names = FALSE)

# 4. Who the soft VIF key demotes ----------------------------------------------------------------
tok <- function(v, i) vapply(strsplit(v, " "), `[`, "", i)
pass$baseloadControl <- grepl("Hyd", tok(pass$model, 5))
pass$rolPlusAccountability <- grepl("|RoL|", tok(pass$model, 2), fixed = TRUE) & !grepl("noAcc", tok(pass$model, 2))
out$vifShare <- stats::aggregate(cbind(vifAbove6 = pass$vif > 6) ~ baseloadControl + rolPlusAccountability, pass, mean)
cat("\n4. Share of hard-gate passers with max VIF > 6,", g, "\n"); print(out$vifShare, row.names = FALSE, digits = 2)
cat("   first band:", nrow(band), "specs,", sum(band$vif > 6), "with VIF > 6,", sum(band$tmin < 2.33, na.rm = TRUE), "with a significant theory term below |t| 2.33\n")

saveRDS(out, file.path("output/pfm", g, "baseload-control.rds"))
cat("\nWrote", file.path("output/pfm", g, "baseload-control.rds"), "\n")
