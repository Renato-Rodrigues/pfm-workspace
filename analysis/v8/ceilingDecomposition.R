# What sets each country's 2023 ceiling? (GMD paper, review v02 M3; gap plan GP-35 (b))
#   Rscript analysis/v8/ceilingDecomposition.R [group]   (repo root; default v8)
#   -> output/pfm/<group>/ceiling-decomposition.rds
# The ceiling is eta = x'beta on the logit scale (Smax * logistic(eta) on the index). With the deployed frontier
# coefficients of frontier.rds and the selected specification's design (pfm:::.pfmAnchorDesign, as the coupling builds
# it), each country's 2023 eta is split into the contributions x_j * beta_j of its terms, grouped as: intercept, trend,
# group effect (OECD / other against the EU), sectoral interests (main terms), institutions (main terms), interactions
# (sectoral interests x institutions) and controls. No refit: the coefficients are the stored ones. The script checks
# that the rebuilt eta reproduces frontier.rds$bySector$<s>$scores$frontierIndex for the 48 estimation countries in 2023
# and stops if it does not. Offline; nothing in the package or the Run-Group changes.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g)
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [ceiling-decomposition:", g, "] ", ...)
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE); pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability", "fossilRents"), names(pd))])
panel <- .panelForGroup(g)
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD)); fr <- readRDS(file.path(GD, "frontier.rds"))
YEAR <- 2023
groupOf <- function(term) {
  ifelse(term == "(Intercept)", "intercept",
  ifelse(grepl("TimeTrend", term), "trend",
  ifelse(startsWith(term, "regionFE"), "group effect",
  ifelse(grepl("_x_", term), "interactions",
  ifelse(term %in% c("Innovator.Power", "Incumbent.Power", "Incumbent.Power.pc"), "sectoral interests",
  ifelse(grepl("WGI|VDem", term), "institutions", "controls"))))))
}
out <- list(); terms <- list(); check <- list()
for (sec in c("Bulk", "Diffuse")) {
  say(sec)
  cfg <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  ct <- fr$bySector[[sec]]$coefTable
  beta <- stats::setNames(ct$estimate, ct$term)
  des <- pfm:::.pfmAnchorDesign(cfg, sec, panel, beta, modelDir = NULL, indexMax = 10,
                                slackScaling = fr$bySector[[sec]]$driverScaling)
  r <- pfm:::.pfmFrontierEta(des, panel, returnDesign = TRUE)
  keep <- r$frame$year == YEAR & is.finite(r$frame$eta)
  mm <- r$mm[keep, , drop = FALSE]; fr23 <- r$frame[keep, ]
  b <- des$beta[colnames(mm)]
  contrib <- sweep(mm, 2, b, `*`)
  grp <- groupOf(colnames(contrib))
  byGroup <- sapply(unique(grp), function(k) rowSums(contrib[, grp == k, drop = FALSE]))
  sc <- fr$bySector[[sec]]$scores; sc <- sc[sc$year == YEAR, ]
  ceil <- 10 * stats::plogis(fr23$eta)
  m <- match(sc$region, fr23$region)
  dev <- max(abs(ceil[m] - sc$frontierIndex), na.rm = TRUE)
  say(sec, ": rebuilt 2023 ceiling against frontier.rds for ", sum(!is.na(m)), " countries, largest difference ", signif(dev, 3))
  if (!is.finite(dev) || dev > 1e-3) stop("the rebuilt ceiling does not reproduce frontier.rds (", dev, ")")
  df <- data.frame(sector = sec, region = fr23$region, estimationCountry = fr23$region %in% sc$region, eta = fr23$eta, ceiling = ceil,
                   byGroup, check.names = FALSE, stringsAsFactors = FALSE)
  df$observed <- sc$observedIndex[match(df$region, sc$region)]
  out[[sec]] <- df
  terms[[sec]] <- data.frame(sector = sec, region = rep(fr23$region, ncol(contrib)), term = rep(colnames(contrib), each = nrow(contrib)),
                             group = rep(grp, each = nrow(contrib)), x = as.numeric(mm), beta = rep(b, each = nrow(contrib)),
                             contribution = as.numeric(contrib), stringsAsFactors = FALSE)
  check[[sec]] <- c(countries = sum(!is.na(m)), maxAbsDiff = dev)
}
res <- list(group = g, year = YEAR, made = format(Sys.time(), "%Y-%m-%d %H:%M"),
            note = "eta = x'beta split by term groups; contributions on the logit scale; ceiling = 10 * logistic(eta); estimation countries checked against frontier.rds",
            byCountry = do.call(rbind, out), byTerm = do.call(rbind, terms), check = check)
f <- file.path(GD, "ceiling-decomposition.rds"); saveRDS(res, f); say("wrote ", f)
