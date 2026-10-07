# The v6 variant Run-Groups through the v6 formulation, offline (design note 0005 Phase 5 wave 2 inputs).
#   Rscript analysis/v6/variantGroups.R          (repo root; after analysis/v6/phase1.R and the variants'
#                                                 exports in output/remind-inputs/<group>)
# For every exported v6* group with an anchor artifact: its spec, frontier gamma, the assignment basis
# of the uncovered countries, the anchor-year ranking u (EU21) against v6's, and k_s(t) and phi(t) at
# theta = 0.50 on the registry's NPi and PkBudg1000 energy systems (analysis/v6/bases.R). Every group is
# evaluated on the SAME scenario panels, so differences are the group's own (spec, curve shape,
# assignment). OFFLINE: fixed REMIND energy systems, not coupled fixed points - label every number so.
# v6-annual is estimated on the annual panel; its anchor is evaluated on the same (moving-average v6)
# scenario panels, a like-for-like reading of its frontier, not of its harmonisation.
# Output: output/pfm/v6/phase1/variant-groups.rds and a printed summary.
suppressMessages({ library(pfm); library(madrat) })
`%||%` <- function(a, b) if (is.null(a)) b else a
rc <- pfmResolveConfig("config.yml", group = "v6", verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)
P1 <- "output/pfm/v6/phase1"
scen <- lapply(c(NPi = "NPi", PkBudg1000 = "PkBudg1000"), function(k) v6ScenPanel(P1, k, BASES[[k]]))
THETA <- 0.5; YRS <- c(2035, 2050, 2070, 2100)

groups <- basename(Sys.glob("output/remind-inputs/v6*"))
groups <- groups[file.exists(file.path("output/remind-inputs", groups, "phi-anchor.rds"))]
groups <- c("v6", setdiff(sort(groups), "v6"))
message("[variants] bases: REMIND ", remindVersion(BASES[["PkBudg1000"]]), "; groups: ", paste(groups, collapse = ", "))

one <- function(g) {
  art <- readRDS(file.path("output/remind-inputs", g, "phi-anchor.rds"))
  fr <- readRDS(file.path("output/pfm", g, "frontier.rds"))
  anc <- pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")
  basis <- table(art$country$basis[art$country$sector == "Bulk"])
  res <- lapply(names(scen), function(run) {
    s <- pfmV6Shares(anc, scen[[run]], theta = THETA)
    list(k = cbind(run = run, s$strength[s$strength$year %in% YRS, c("sector", "year", "k")]),
         phi = cbind(run = run, s$shares[s$shares$year %in% YRS, c("sector", "region", "year", "u", "phi")]))
  })
  list(group = g, spec = art$spec[["Bulk"]], created = art$created,
       gamma = sapply(c("Bulk", "Diffuse"), function(x) fr$bySector[[x]]$gamma),
       basis = basis, k = do.call(rbind, lapply(res, `[[`, "k")), phi = do.call(rbind, lapply(res, `[[`, "phi")))
}
out <- lapply(stats::setNames(groups, groups), one)

# the v6 reading must reproduce Phase 1 exactly, else the comparison is not on the Phase 1 footing
st <- readRDS(file.path(P1, "strength.rds")); st <- st[st$resolution == "EU21" & st$run %in% names(scen), ]
chk <- merge(out$v6$k, st[, c("run", "sector", "year", "k")], by = c("run", "sector", "year"))
stopifnot(nrow(chk) > 0, max(abs(chk$k.x - chk$k.y)) < 1e-9)

ref <- out$v6$phi
summ <- do.call(rbind, lapply(out, function(o) {
  kk <- function(run, sec, y) o$k$k[o$k$run == run & o$k$sector == sec & o$k$year == y]
  u <- unique(o$phi[o$phi$run == "PkBudg1000", c("sector", "region", "u")])
  u0 <- unique(ref[ref$run == "PkBudg1000", c("sector", "region", "u")])
  m <- merge(u, u0, by = c("sector", "region"))
  rho <- sapply(c("Bulk", "Diffuse"), function(x) with(m[m$sector == x, ], stats::cor(u.x, u.y, method = "spearman")))
  p <- merge(o$phi[o$phi$run == "PkBudg1000" & o$phi$year == 2050, ], ref[ref$run == "PkBudg1000" & ref$year == 2050, ],
             by = c("run", "sector", "region", "year"))
  floor <- sapply(c("Bulk", "Diffuse"), function(x) { z <- u[u$sector == x, ]; z$region[which.max(z$u)] })
  data.frame(group = o$group,
             spec = sub(" WGIge.*?(sat[A-Za-z]+)( \\[.*\\])?$", " \\1\\2", o$spec),
             gammaB = round(o$gamma[["Bulk"]], 4), gammaD = round(o$gamma[["Diffuse"]], 4),
             donor = as.integer(o$basis["donor"] %||% 0), low = as.integer(o$basis["lowBand"] %||% 0),
             median = as.integer(o$basis["median"] %||% 0),
             kB2050 = kk("PkBudg1000", "Bulk", 2050), kB2100 = kk("PkBudg1000", "Bulk", 2100),
             kD2050 = kk("PkBudg1000", "Diffuse", 2050), kD2100 = kk("PkBudg1000", "Diffuse", 2100),
             kB2050npi = kk("NPi", "Bulk", 2050),
             rhoB = rho[["Bulk"]], rhoD = rho[["Diffuse"]], floorB = floor[["Bulk"]], floorD = floor[["Diffuse"]],
             maxDphi2050 = max(abs(p$phi.x - p$phi.y)), medDphi2050 = stats::median(abs(p$phi.x - p$phi.y)),
             stringsAsFactors = FALSE)
}))
num <- vapply(summ, is.numeric, NA); summ[num] <- lapply(summ[num], function(x) round(x, 3))
saveRDS(list(summary = summ, groups = out, theta = THETA, bases = BASES, remind = remindVersion(BASES[["PkBudg1000"]]),
             label = "offline: fixed REMIND energy systems, theta 0.50, EU21"),
        file.path(P1, "variant-groups.rds"))
options(width = 200)
cat("\n== v6 variant groups, offline, EU21, theta 0.50, PkBudg1000 energy system unless marked (REMIND",
    remindVersion(BASES[["PkBudg1000"]]), "bases)\n")
print(summ, row.names = FALSE)

# where the ranking moves: regions whose u changes by more than 0.1 against v6, per group
cat("\n== regions whose anchor-year ranking u moves by more than 0.10 against v6 (EU21)\n")
u0 <- unique(ref[ref$run == "PkBudg1000", c("sector", "region", "u")])
for (g in setdiff(names(out), "v6")) {
  u <- unique(out[[g]]$phi[out[[g]]$phi$run == "PkBudg1000", c("sector", "region", "u")])
  m <- merge(u, u0, by = c("sector", "region")); m$d <- m$u.x - m$u.y
  big <- m[abs(m$d) > 0.1, ]
  cat(sprintf("  %-13s %s\n", g, if (nrow(big)) paste(sprintf("%s %s %+.2f", substr(big$sector, 1, 1), big$region, big$d), collapse = ", ") else "none"))
}
