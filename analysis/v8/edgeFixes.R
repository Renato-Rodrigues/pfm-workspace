# v8 quick test (design note 0009 section 7): fixes for the extreme efficiency ratios, offline, on the v7 panel.
#   Rscript analysis/v8/edgeFixes.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-edge-fixes.rds
# The extremes of section 1 have three causes in the form: a linear fossil term at the low edge (Iceland), an
# interaction evaluated outside the joint support (Indonesia, partly Peru and Argentina), and institution main effects
# that are negative and not identified in power & industry (Saudi Arabia). Variants of the selected frontier, refitted
# with frontier::sfa on its own prepared frame (the v7 fit is reproduced first):
#   v7          the selected frontier;
#   clip5       every base driver clipped at the estimation sample's 5th / 95th percentiles before the interactions are
#               formed (a country at the edge is read as the edge of the data, not beyond it);
#   clip10      the same at the 10th / 90th;
#   fosLow      only the two fossil terms clipped, at their 5th percentile (the low edge alone: Iceland);
#   noInstMain  the three institution main effects dropped, the interactions kept (the institutions act only through
#               the interests);
#   noNegMain   only the institution main effects that are negative in v7 dropped (a sign restriction).
# Reported: logLik, BIC (and an LR test for the nested drops), gamma, the fossil main effect, H3 coherence, E in 2023 for
# the extreme and reference countries, the rank correlation of country E with v7, and a covered-countries regional u
# (EU21, final-energy weights). Two coupling-side options on the v7 scores, no refit: the anchor as the 2019-2023 mean
# of E (anchorMean), and country E floored at the covered 10th percentile before the regional aggregation (floorE).
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g)
FOCUS <- c("ISL", "IDN", "PER", "ARG", "RUS", "SAU", "NOR", "CHN", "IND", "USA", "DEU", "MEX")
INST <- c("Government.Effectiveness..WGI.", "Rule.of.Law..VDem.", "Vertical.Accountability..VDem.")
FOS <- c("Incumbent.Power", "Incumbent.Power.pc")
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"); rmap <- stats::setNames(map$RegionCode, map$CountryCode)
uOf <- function(e) { e$r <- rmap[e$region]; e$w <- w[e$region]
  rg <- stats::aggregate(cbind(gw = (1 - E) * w, w) ~ r, e, sum); rg$g <- rg$gw / rg$w
  stats::setNames((rg$g - min(rg$g)) / (max(rg$g) - min(rg$g)), rg$r) }

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfg)))))
  d0 <- ff$data; fml0 <- ff$formula; obs <- ff$outcomeNatural
  ints <- grep("_x_", names(d0), value = TRUE); pr <- do.call(rbind, strsplit(ints, "_x_", fixed = TRUE)); rownames(pr) <- ints
  rebuild <- function(d) { for (k in ints) d[[k]] <- d[[pr[k, 1]]] * d[[pr[k, 2]]] * pfm:::.pfmIwFactor(d, pr[k, 2]); d }
  chk <- max(abs(as.matrix(rebuild(d0)[, ints]) - as.matrix(d0[, ints])), na.rm = TRUE)
  if (chk > 1e-8) stop("the interactions are not rebuilt exactly (", chk, ")")
  base <- unique(c(pr[, 1], pr[, 2], INST))
  clip <- function(d, vars, lo, hi) { for (v in vars) { q <- stats::quantile(d0[[v]], c(lo, hi), na.rm = TRUE)
    d[[v]] <- pmin(pmax(d[[v]], q[[1]]), q[[2]]) }; rebuild(d) }
  b7 <- stats::coef(ff$model)
  negMain <- INST[b7[INST] < 0]
  dropT <- function(f, terms) stats::update(f, stats::as.formula(paste(". ~ . -", paste0("`", terms, "`", collapse = " - "))))
  V <- list(v7 = list(d = d0, f = fml0), clip5 = list(d = clip(d0, base, 0.05, 0.95), f = fml0),
            clip10 = list(d = clip(d0, base, 0.10, 0.90), f = fml0),
            fosLow = list(d = clip(d0, FOS, 0.05, 1), f = fml0),
            noInstMain = list(d = d0, f = dropT(fml0, INST)),
            noNegMain = list(d = d0, f = if (length(negMain)) dropT(fml0, negMain) else fml0))
  out <- lapply(names(V), function(vn) {
    d <- V[[vn]]$d; f <- V[[vn]]$f; t0 <- Sys.time()
    m <- suppressWarnings(frontier::sfa(f, data = d, maxit = 1000))
    message(sprintf("[edge fixes] %s %s: %.0f s, %d iterations", sec, vn, as.numeric(difftime(Sys.time(), t0, units = "secs")), m$nIter %||% NA_integer_))
    b <- stats::coef(m); mm <- stats::model.matrix(f, d); eta <- as.numeric(mm %*% b[colnames(mm)])
    E <- as.numeric(obs[rownames(mm)]) / (10 * stats::plogis(eta))
    sc <- data.frame(region = as.character(d[rownames(mm), "region"]), year = d[rownames(mm), "year"], E = E)
    ll <- as.numeric(stats::logLik(m)); k <- length(b)
    se <- tryCatch(sqrt(diag(stats::vcov(m))), error = function(e) rep(NA_real_, k))
    bb <- b[!names(b) %in% c("sigmaSq", "gamma")]
    list(fit = data.frame(sector = sec, variant = vn, logLik = ll, k = k, BIC = -2 * ll + k * log(nrow(mm)), gamma = b[["gamma"]],
                          fossil = b[["Incumbent.Power"]], fossilZ = b[["Incumbent.Power"]] / se[["Incumbent.Power"]],
                          H3 = pfm:::.pfmTheoryCoherence(bb, d)$share,
                          LRp = if (vn %in% c("noInstMain", "noNegMain") && k < length(b7)) stats::pchisq(2 * (as.numeric(stats::logLik(ff$model)) - ll), length(b7) - k, lower.tail = FALSE) else NA_real_),
         scores = sc, coef = b)
  })
  names(out) <- names(V)
  fit <- do.call(rbind, lapply(out, `[[`, "fit"))
  E23 <- do.call(cbind, lapply(out, function(o) { s <- o$scores[o$scores$year == 2023, ]; stats::setNames(s$E, s$region) }))
  fit$spearmanE <- apply(E23, 2, function(x) stats::cor(x, E23[, "v7"], method = "spearman"))
  U <- sapply(colnames(E23), function(v) uOf(data.frame(region = rownames(E23), E = E23[, v])))
  # coupling-side options on the v7 scores
  s7 <- out$v7$scores
  m5 <- stats::aggregate(E ~ region, s7[s7$year >= 2019, ], mean); m5 <- stats::setNames(m5$E, m5$region)[rownames(E23)]
  fl <- pmax(E23[, "v7"], stats::quantile(E23[, "v7"], 0.10))
  E23 <- cbind(E23, anchorMean = m5, floorE = fl)
  U <- cbind(U, anchorMean = uOf(data.frame(region = names(m5), E = m5)), floorE = uOf(data.frame(region = names(fl), E = fl)))
  list(fit = fit, E = E23, U = U, negMain = negMain, interactionsRebuilt = chk)
})
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), bySector = res), file.path(GD, "v8-edge-fixes.rds"))
options(width = 230)
for (sec in names(res)) { r <- res[[sec]]
  cat("\n==========", sec, "| negative institution main effects in v7:", paste(r$negMain, collapse = ", "), "==========\n")
  print(r$fit, digits = 4, row.names = FALSE)
  cat("E 2023:\n"); print(round(r$E[intersect(FOCUS, rownames(r$E)), ], 2))
  cat("lowest E per variant:", paste(sapply(colnames(r$E), function(v) paste0(v, " ", names(sort(r$E[, v]))[1], " ", round(sort(r$E[, v])[1], 2))), collapse = " | "), "\n")
  cat("regional u (covered countries, EU21):\n"); print(round(r$U[order(-r$U[, "v7"]), ], 2))
  cat("Spearman of u with v7:", paste(colnames(r$U), round(apply(r$U, 2, function(x) stats::cor(x, r$U[, "v7"], method = "spearman")), 2), collapse = " | "), "\n") }
