# What the coupling would read under the v7 interaction weights, on a Run-Group's data (design note 0007 §9-10).
#   Rscript analysis/checks/interactionWeightPaths.R [group]        (repo root; default v6; after edgeGateValidation.R,
#   which writes the scenario panel with the democracy indices, coupling/scen-PFMlevelBfix-<group>-democracy.rds)
#
# For the selected specification, unweighted ("none", a control that must reproduce the run) and with each v7 weight
# (liberal democracy, freedom of expression; the package form: the index read year by year, as the v7 panels build it):
#   1. the frontier, refitted (estimatePolicyStringencyModel, estimator "frontier");
#   2. the anchor (computeAnchorGap): the 2023 regional ranking u at EU21 and H12, from a temporary results folder that
#      holds the group's files with the weighted spec and coefficients; countries without CAPMF data keep the group's
#      band-rule efficiency ratio (donor-assignment-band-*.rds), as in edgeOptions.R;
#   3. the strength k(t) on the coupled hold-the-price energy system (computeStrengthPath), offline: no REMIND run;
#   4. the edge gate at its defaults (.pfmCeilingTrajectory), and the log-likelihood;
#   5. one country's observed stringency and ceiling, 2001-2023, and its projected stringency and ceiling on the coupled
#      energy system, 2025-2100 (the gap figure of D3.3);
#   6. the frontier coefficients with ML standard errors and the SD of each term in the estimation data (beta x SD(x));
#   7. every country's 2023 anchor: ceiling, stringency, basis (observed / assigned) - the frontier-fit figure.
# Choice between the weights, declared before the run (author, 2026-10-16: "compute both, show the best"):
#   (a) the weight must pass the edge gate in both sectors; (b) among those, the higher summed log-likelihood of the two
#   sector fits; (c) a tie within 1 log-likelihood unit goes to the higher Spearman correlation of the power & industry
#   ranking with the group's run (EU21).
# The group's madrat cache is COPIED to a temporary folder first, so its pinned files are never touched.
# Writes output/pfm/<group>/interaction-weight-paths.rds.
source("analysis/_common/_loadPfm.R")
suppressMessages({ pkgload::load_all("models/mrpfm", quiet = TRUE); library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v6"
GD <- file.path("output/pfm", g)
say <- function(...) message("[iw-paths:", g, "] ", ...)
WEIGHTS <- c(none = NA, libdem = "Liberal Democracy (VDem)", fexp = "Freedom of Expression (VDem)")
RES <- c("EU21", "H12"); EXAMPLE <- "POL"

rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
cache <- file.path(tempdir(), paste0("madrat-", g)); dir.create(cache, showWarnings = FALSE)
invisible(file.copy(list.files(file.path("data/madrat", g), full.names = TRUE), cache, overwrite = TRUE))
src <- Filter(dir.exists, unlist(rc$madrat$sourcefolder %||% rc$sourcefolder))[1]
setConfig(cachefolder = cache, forcecache = TRUE, sourcefolder = src, .verbose = FALSE)
options(pfm.panel = c(pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")], democracy = TRUE))
say("building the historical panel with the democracy key ...")
hist <- panelDataHistorical(aggregate = TRUE, outputRegionMappingFile = "country", includePolicyStringency = TRUE)
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, "-democracy.rds")))
anc0 <- stats::setNames(lapply(RES, function(r) pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), r)), RES)
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
fr0 <- readRDS(file.path(GD, "frontier.rds"))
SECS <- c("Bulk", "Diffuse")

out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), weights = WEIGHTS, example = EXAMPLE,
            fits = list(), rank = list(), strength = list(), series = list(), projection = list(), coefs = list(),
            anchor = list(), checks = list())
for (w in names(WEIGHTS)) {
  tmp <- file.path(tempdir(), paste0("iw-", w)); gtmp <- file.path(tmp, g); dir.create(gtmp, recursive = TRUE, showWarnings = FALSE)
  for (f in c("manifest.json", basename(pfm:::.pfmSelectedModels(GD)), paste0("donor-assignment-band-", SECS, ".rds")))
    file.copy(file.path(GD, f), file.path(gtmp, f), overwrite = TRUE)
  selW <- sel; fr <- fr0
  for (sec in SECS) {
    i <- which(vapply(selW, function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), logical(1)))
    if (!is.na(WEIGHTS[[w]])) selW[[i]]$interactionWeight <- WEIGHTS[[w]]
    cf <- selW[[i]]
    fit <- do.call(estimatePolicyStringencyModel, c(list(data = hist, sector = sec, estimator = "frontier", indexMax = 10,
                                                        modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cf)))
    b <- stats::coef(fit$model)
    V <- tryCatch(stats::vcov(fit$model), error = function(e) NULL)
    se <- if (is.null(V)) rep(NA_real_, length(b)) else sqrt(pmax(diag(V), 0))[names(b)]
    X <- stats::model.matrix(stats::delete.response(stats::terms(fit$formula)),
                             stats::model.frame(stats::delete.response(stats::terms(fit$formula)), data = fit$data, na.action = stats::na.omit))
    sdX <- apply(X, 2, stats::sd); names(sdX) <- gsub("`", "", names(sdX))
    tn <- gsub("`", "", names(b))
    out$coefs[[paste(w, sec)]] <- data.frame(weight = w, sector = sec, term = tn, estimate = as.numeric(b), se = as.numeric(se),
                                             sdX = as.numeric(sdX[tn]), stringsAsFactors = FALSE)
    fr$bySector[[sec]]$coefTable <- data.frame(term = names(b), estimate = as.numeric(b), stringsAsFactors = FALSE)
    ct <- pfm:::.pfmCeilingTrajectory(cf, sec, hist, scen, modelDir = NULL, indexMax = 10,
                                      edgeGate = pfm:::.pfmEdgeGateDefaults())
    out$fits[[paste(w, sec)]] <- data.frame(weight = w, sector = sec, n = nrow(fit$data),
                                            logLik = as.numeric(stats::logLik(fit$model)), gamma = b[["gamma"]],
                                            edgePass = isTRUE(ct$edge$pass), edgeDetail = ct$edge$detail)
    say(w, " ", sec, ": logLik ", round(as.numeric(stats::logLik(fit$model)), 1), " | gamma ", round(b[["gamma"]], 4),
        " | edge gate ", if (isTRUE(ct$edge$pass)) "PASS" else "FAIL", " - ", ct$edge$detail)
  }
  yaml::write_yaml(selW, file.path(gtmp, basename(pfm:::.pfmSelectedModels(GD))))
  saveRDS(fr, file.path(gtmp, "frontier.rds"))
  for (res in RES) {
    an <- suppressMessages(computeAnchorGap(g, resultsDir = tmp, histData = hist, mapping = anc0[[res]]$mapping,
                                            weights = anc0[[res]]$weights, verbose = FALSE))
    st <- suppressMessages(computeStrengthPath(an, scen, returnCountries = TRUE))
    out$rank[[paste(w, res)]] <- data.frame(weight = w, resolution = res, an$region[, c("sector", "region", "u", "shareObserved")])
    out$strength[[paste(w, res)]] <- data.frame(weight = w, resolution = res, st$strength[, c("sector", "year", "k")])
    if (res == "EU21") {
      out$anchor[[w]] <- data.frame(weight = w, an$country[, c("sector", "region", "basis", "ceilingAnchor", "indexAnchor")])
      cp <- st$countries[st$countries$region == EXAMPLE, c("sector", "year", "feasibleIndex", "ceilingIndex")]
      out$projection[[w]] <- data.frame(weight = w, cp)
      for (sec in SECS) {
        d <- an$designs[[sec]]
        eh <- pfm:::.pfmFrontierEta(d, hist); eh <- eh[eh$region == EXAMPLE, ]
        obs <- fr0$bySector[[sec]]$scores; obs <- obs[obs$region == EXAMPLE, c("year", "observedIndex")]
        S <- obs$observedIndex                                  # observed CAPMF stringency: the same in every variant
        out$series[[paste(w, sec)]] <- data.frame(weight = w, sector = sec, year = obs$year, S = S,
                                                   Sstar = 10 * stats::plogis(eh$eta[match(obs$year, eh$year)]))
      }
    }
    if (w == "none") {
      a0 <- anc0[[res]]$region
      m <- merge(a0[, c("sector", "region", "u")], an$region[, c("sector", "region", "u")], by = c("sector", "region"))
      out$checks[[res]] <- max(abs(m$u.x - m$u.y))
      say("control (unweighted) reproduces the run's u at ", res, " to ", signif(out$checks[[res]], 2))
    }
  }
}
out$fits <- do.call(rbind, out$fits); out$rank <- do.call(rbind, out$rank)
out$coefs <- do.call(rbind, out$coefs); out$anchor <- do.call(rbind, out$anchor); out$projection <- do.call(rbind, out$projection)
rownames(out$coefs) <- rownames(out$anchor) <- rownames(out$projection) <- NULL
out$strength <- do.call(rbind, out$strength); out$series <- do.call(rbind, out$series)
rownames(out$fits) <- rownames(out$rank) <- rownames(out$strength) <- rownames(out$series) <- NULL

# the choice (criteria in the header)
cand <- setdiff(names(WEIGHTS), "none")
ok <- vapply(cand, function(w) all(out$fits$edgePass[out$fits$weight == w]), logical(1))
ll <- vapply(cand, function(w) sum(out$fits$logLik[out$fits$weight == w]), numeric(1))
sp <- vapply(cand, function(w) {
  a <- out$rank[out$rank$weight == "none" & out$rank$resolution == "EU21" & out$rank$sector == "Bulk", ]
  b <- out$rank[out$rank$weight == w & out$rank$resolution == "EU21" & out$rank$sector == "Bulk", ]
  stats::cor(a$u, b$u[match(a$region, b$region)], method = "spearman") }, numeric(1))
pool <- cand[ok]
chosen <- if (!length(pool)) NA_character_ else {
  best <- pool[which.max(ll[pool])]
  close <- pool[abs(ll[pool] - ll[best]) <= 1]
  if (length(close) > 1) close[which.max(sp[close])] else best
}
out$choice <- list(passes = ok, summedLogLik = ll, spearmanBulkEU21 = sp, chosen = chosen)
say("choice: ", chosen, " | gate ", paste(names(ok), ok, collapse = ", "), " | summed logLik ",
    paste(names(ll), round(ll, 1), collapse = ", "), " | Spearman P&I EU21 ", paste(names(sp), round(sp, 2), collapse = ", "))
saveRDS(out, file.path(GD, "interaction-weight-paths.rds"))
say("wrote ", file.path(GD, "interaction-weight-paths.rds"))
