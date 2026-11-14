# An exogenous, governance-indexed cap in the same coupling (design note 0010 section 3.5, run R3; the model paper's
# gap plan GP-2): the comparator that shows what the ESTIMATED ranking and the ENDOGENOUS strength each change.
#   Rscript analysis/v8/exogenousCap.R [group]          workstation: the governance rankings -> analysis/v8/exogenous-cap-ranking.csv
#                                                        (tracked) and output/pfm/<group>/exogenous-cap.rds (the comparison)
#   Rscript analysis/v8/exogenousCap.R [group] stage    anywhere (the cluster): the variant Run-Groups, from the tracked csv:
#                                                        output/remind-inputs/<group>-gov6 and -govGE, copies of the group's
#                                                        export whose anchor carries the governance ranking in both sectors
# The literature caps carbon prices by a governance index (Bertram et al. 2024, on the index of Andrijevic et al. 2020,
# a composite of the Worldwide Governance Indicators). Here the same idea enters the PFM's own coupling: only the regional
# ranking u (0 = least constrained, 1 = most) is replaced, by
#   gov6   the mean of the six Worldwide Governance Indicators (the composite), final-energy-weighted to regions
#   govGE  government effectiveness alone
# each at 2025, min-max over regions like the model's u, the region with the weakest governance at 1. Everything else of
# the export (the frontier, the country distances, the staged madrat cache, the manifest's panel) is the group's. With
# pfmPhiHold = ratio (the constant limit) the cap is fixed over time: an exogenous cap. With the default (the fading
# limit) the governance ranking moves with the estimated ceilings: a mixed case that separates the ranking from the dynamics.
# Nothing in the group or the package changes.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
args <- commandArgs(trailingOnly = TRUE); STAGE <- "stage" %in% args; args <- setdiff(args, "stage")
g <- if (length(args)) args[1] else "v8"; GD <- file.path("output/pfm", g); EXP <- file.path("output/remind-inputs", g)
say <- function(...) message("[exogenous-cap:", g, "] ", ...)
CSV <- "analysis/v8/exogenous-cap-ranking.csv"
VARIANTS <- c(gov6 = "the mean of the six Worldwide Governance Indicators", govGE = "government effectiveness (WGI)")
x0 <- readRDS(file.path(EXP, "phi-anchor.rds")); stopifnot(identical(x0$format, "pfm-anchor/1"))

if (STAGE) {
  rk <- utils::read.csv(CSV, stringsAsFactors = FALSE); rk <- rk[rk$group == g, ]
  if (!nrow(rk)) stop("no ranking for group ", g, " in ", CSV, " - run without 'stage' on the workstation and commit the csv")
  for (v in names(VARIANTS)) {
    ng <- paste0(g, "-", v); dst <- file.path("output/remind-inputs", ng)
    if (!dir.exists(dst)) { dir.create(dst, recursive = TRUE)
      ok <- file.copy(list.files(EXP, full.names = TRUE, all.files = TRUE, no.. = TRUE), dst, recursive = TRUE); stopifnot(all(ok)) }
    x <- x0
    for (res in names(x$byResolution)) {
      r <- x$byResolution[[res]]$region; u <- rk[rk$resolution == res & rk$variant == v, ]
      miss <- setdiff(unique(r$region), u$region); if (length(miss)) stop(ng, " ", res, ": no governance ranking for ", paste(miss, collapse = ", "))
      r$uModel <- r$u; r$u <- u$u[match(r$region, u$region)]     # the same ranking in both sectors
      x$byResolution[[res]]$region <- r
    }
    x$group <- ng; x$exogenousRanking <- list(variant = v, what = VARIANTS[[v]], from = CSV, base = g)
    saveRDS(x, file.path(dst, "phi-anchor.rds"))
    chk <- pfm:::pfmAnchorFor(dst, names(x$byResolution)[1])$region
    stopifnot(max(abs(chk$u - chk$uModel)) > 0.05)             # the variant must differ from the base
    say("staged ", dst, " (", VARIANTS[[v]], "); rank correlation with the model's u, ", names(x$byResolution)[1], ": ",
        paste(sprintf("%s %.2f", unique(chk$sector), vapply(unique(chk$sector), function(s) stats::cor(chk$u[chk$sector == s], chk$uModel[chk$sector == s], method = "spearman"), numeric(1))), collapse = ", "))
  }
  quit(status = 0)
}

# ---- the rankings, from the coupled hold-the-price panel's institution series at t0 ---------------------------------------
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, ".rds")))
WGI <- c("Voice and Accountability (WGI)", "Political Stability (WGI)", "Regulatory Quality (WGI)", "Rule of Law (WGI)",
         "Government Effectiveness (WGI)", "Control of Corruption (WGI)")
stopifnot(all(WGI %in% getNames(scen))); t0 <- x0$t0; w <- x0$weights
val <- function(v) { z <- scen[, t0, v]; stats::setNames(as.numeric(z), getItems(z, 1)) }
z <- function(v) { s <- val(v); (s - stats::weighted.mean(s, w[names(s)], na.rm = TRUE)) / stats::sd(s, na.rm = TRUE) }
country <- list(gov6 = rowMeans(sapply(WGI, z), na.rm = TRUE), govGE = z("Government Effectiveness (WGI)"))
rows <- list(); cmp <- list()
for (res in names(x0$byResolution)) {
  b <- x0$byResolution[[res]]; map <- pfm:::.pfmResolveCountryMap(b$mapping)
  for (v in names(country)) {
    s <- country[[v]]; cc <- intersect(names(s)[is.finite(s)], names(map)); ww <- w[cc]; ww[!is.finite(ww)] <- 0
    reg <- tapply(s[cc] * ww, map[cc], sum) / tapply(ww, map[cc], sum)
    u <- (max(reg) - reg) / diff(range(reg))
    rows[[paste(res, v)]] <- data.frame(group = g, resolution = res, variant = v, region = names(u), governance = round(as.numeric(reg), 4), u = round(as.numeric(u), 4))
    for (sec in unique(b$region$sector)) { m <- b$region[b$region$sector == sec, ]
      cmp[[paste(res, v, sec)]] <- data.frame(resolution = res, variant = v, sector = sec, rankCorrelation = stats::cor(u[m$region], m$u, method = "spearman"),
        meanU = stats::weighted.mean(u[m$region], m$weight), meanUModel = stats::weighted.mean(m$u, m$weight),
        mostConstrainedGov = names(u)[which.max(u)], mostConstrainedModel = m$region[which.max(m$u)]) }
  }
}
rk <- do.call(rbind, rows); rownames(rk) <- NULL; cmp <- do.call(rbind, cmp); rownames(cmp) <- NULL
old <- if (file.exists(CSV)) utils::read.csv(CSV, stringsAsFactors = FALSE) else NULL
utils::write.csv(rbind(old[old$group != g, ], rk), CSV, row.names = FALSE)
side <- do.call(rbind, lapply(names(x0$byResolution), function(res) { m <- x0$byResolution[[res]]$region
  d <- stats::reshape(m[, c("sector", "region", "u")], idvar = "region", timevar = "sector", direction = "wide")
  for (v in names(country)) d[[paste0("u.", v)]] <- rk$u[rk$resolution == res & rk$variant == v][match(d$region, rk$region[rk$resolution == res & rk$variant == v])]
  cbind(resolution = res, d) }))
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), t0 = t0, variants = VARIANTS, ranking = rk, comparison = cmp, sideBySide = side,
             note = "u: 0 least constrained, 1 most; governance z-scores at t0 from the coupled hold-the-price panel, final-energy-weighted to regions"),
        file.path(GD, "exogenous-cap.rds"))
say("wrote ", CSV, " and ", file.path(GD, "exogenous-cap.rds"))
options(width = 200); cat("\n== the governance rankings against the model's ==\n"); print(cmp, row.names = FALSE, digits = 2)
cat("\n== EU21, side by side (u: 1 = most constrained) ==\n"); s <- side[side$resolution == "EU21", -1]; print(s[order(-s$u.gov6), ], row.names = FALSE, digits = 2)
