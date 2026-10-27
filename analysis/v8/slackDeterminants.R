# v8 test (design note 0009 section 8): what explains the distance below the ceiling? An efficiency-effects frontier
# (Battese & Coelli 1995) on the v7 panel: the slack u >= 0 is truncated normal with mean z'delta, so producer interests
# can hold policy below what the institutions allow without moving the ceiling itself - the reading section 3 tested in
# the ceiling and found against the theory.
#   Rscript analysis/v8/slackDeterminants.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-slack-determinants.rds
# The selected frontier (its prepared frame, its ceiling terms unchanged), refitted with frontier::sfa as
#   hn      half-normal slack (the v7 frontier);
#   tn      truncated-normal slack with a constant mean (the robustness battery's rung);
#   zRents  slack mean on fossil rents (log(1 + % of GDP), standardised; analysis/v8/_rents.R);
#   zExp    slack mean on the exporter dummy (rents > 5% of GDP);
#   zInst   slack mean on the three institutions (does slack depend on institutions rather than the ceiling? 0009 4.4);
#   zBoth   rents and the institutions.
# delta > 0: more slack, i.e. policy further below the ceiling. Reported: logLik, LR against hn, gamma, the delta table,
# E in 2023 for the exporters and the extremes, a covered-countries regional u (EU21) and its rank correlation with v7.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
source("analysis/v8/_rents.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g)
FOCUS <- c("SAU", "RUS", "NOR", "CAN", "AUS", "COL", "MEX", "IDN", "ISL", "PER", "ARG", "CHN", "USA")
INST <- c("Government.Effectiveness..WGI.", "Rule.of.Law..VDem.", "Vertical.Accountability..VDem.")
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
Rh <- v8RentsHistory(getItems(panel, dim = 1), getYears(panel, as.integer = TRUE), file.path(GD, "v8-wdi-rents.rds"))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"); rmap <- stats::setNames(map$RegionCode, map$CountryCode)
uOf <- function(E, cty) { r <- rmap[cty]; ww <- w[cty]; gg <- tapply((1 - E) * ww, r, sum) / tapply(ww, r, sum); (gg - min(gg)) / (max(gg) - min(gg)) }

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfg)))))
  d <- ff$data; obs <- ff$outcomeNatural
  # the slack determinants, from the same lagged year as the drivers (lag 1)
  rr <- Rh[cbind(match(as.character(d$region), rownames(Rh)), match(as.character(d$year - 1), colnames(Rh)))]
  d$zRents <- (rr - mean(rr, na.rm = TRUE)) / stats::sd(rr, na.rm = TRUE)
  d$zExporter <- as.numeric(expm1(rr) > 5)
  rhs <- paste(deparse(ff$formula[[3]], width.cutoff = 500L), collapse = " ")
  lhs <- deparse(ff$formula[[2]])
  zf <- function(z) stats::as.formula(paste(lhs, "~", rhs, "|", paste(z, collapse = " + ")))
  V <- list(hn = list(f = ff$formula), tn = list(f = ff$formula, truncNorm = TRUE),
            zRents = list(f = zf("zRents")), zExp = list(f = zf("zExporter")),
            zInst = list(f = zf(INST)), zBoth = list(f = zf(c("zRents", INST))))
  ll0 <- NA_real_
  out <- lapply(names(V), function(vn) {
    t0 <- Sys.time()
    m <- tryCatch(suppressWarnings(frontier::sfa(V[[vn]]$f, data = d, truncNorm = isTRUE(V[[vn]]$truncNorm), maxit = 1000)),
                  error = function(e) { message("[slack] ", sec, " ", vn, " failed: ", conditionMessage(e)); NULL })
    message(sprintf("[slack] %s %s: %.0f s", sec, vn, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    if (is.null(m)) return(NULL)
    b <- stats::coef(m); se <- tryCatch(sqrt(pmax(diag(stats::vcov(m)), 0)), error = function(e) b * NA)
    mm <- stats::model.matrix(ff$formula, d)
    E <- as.numeric(obs[rownames(mm)]) / (10 * stats::plogis(as.numeric(mm %*% b[colnames(mm)])))
    i23 <- d[rownames(mm), "year"] == 2023; cty <- as.character(d[rownames(mm), "region"])[i23]
    zk <- grep("^Z_", names(b), value = TRUE)
    list(fit = data.frame(sector = sec, variant = vn, logLik = as.numeric(stats::logLik(m)), k = length(b), gamma = b[["gamma"]],
                          fossil = b[["Incumbent.Power"]]),
         delta = if (length(zk)) data.frame(sector = sec, variant = vn, term = sub("^Z_", "", zk), delta = b[zk], z = b[zk] / se[zk], row.names = NULL) else NULL,
         E = stats::setNames(E[i23], cty))
  })
  names(out) <- names(V); out <- Filter(Negate(is.null), out)
  fit <- do.call(rbind, lapply(out, `[[`, "fit")); ll0 <- fit$logLik[fit$variant == "hn"]; k0 <- fit$k[fit$variant == "hn"]
  fit$LR <- 2 * (fit$logLik - ll0); fit$df <- fit$k - k0
  fit$p <- ifelse(fit$df > 0, stats::pchisq(pmax(fit$LR, 0), fit$df, lower.tail = FALSE), NA_real_)
  Em <- do.call(cbind, lapply(out, `[[`, "E")); cty <- rownames(Em)
  U <- apply(Em, 2, uOf, cty = cty)
  fit$spearmanU <- apply(U, 2, function(x) stats::cor(x, U[, "hn"], method = "spearman"))[fit$variant]
  list(fit = fit, delta = do.call(rbind, lapply(out, `[[`, "delta")), E = Em, U = U)
})
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), bySector = res), file.path(GD, "v8-slack-determinants.rds"))
options(width = 220)
for (sec in names(res)) { r <- res[[sec]]; cat("\n==========", sec, "==========\n")
  print(r$fit, digits = 4, row.names = FALSE); print(r$delta, digits = 3, row.names = FALSE)
  cat("E 2023:\n"); print(round(r$E[intersect(FOCUS, rownames(r$E)), ], 2))
  cat("regional u:\n"); print(round(r$U[order(-r$U[, "hn"]), ], 2)) }
