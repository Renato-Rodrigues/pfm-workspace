# How far would the United States' feasibility share move under each coverage branch? (GP-3)
#
#   Rscript analysis/checks/usaBranchPhi.R [group]
#
# WHY. The United States is a one-country REMIND region with no measured ceiling. Its efficiency
# ratio is set by the documented override basisOverride = c(USA = "median") (MODEL.md 5.4), so its
# share is an assumption, and the paper has to say how much that assumption matters. The band rule
# offers three branches - donor blend, low band, median - and this script re-derives the USA's
# offline share under each.
#
# HOW, and why it is exact for the USA. The offline bound (coupling-summary.rds) builds each
# region's relative gap g = 1 - E per sector at the tier year, min-max normalises it across
# regions, u = (g - gmin)/(gmax - gmin), and delivers phi = 1 - theta * max_s u_s (the most
# constrained sector). For a region that is a single uncovered country, g is that country's
# assigned 1 - E, so phi_USA follows from the per-sector gMin/gMax stored in anchorDerivation.
# The script first REPRODUCES the deployed (median) value from those quantities and stops if it
# cannot - so the other two branches are computed by a formula that has just been checked.
#
# The one non-trivial case: a branch that puts the USA OUTSIDE [gmin, gmax] makes it the new
# endpoint. Its u is then 1 (or 0) by construction, and every other region's u in that sector
# shifts. The USA value is still exact; the shift of the others is reported as a flag, not
# computed, because per-region per-sector gaps are not stored in the artifact.
#
# Donor branch. The override replaced a donor blend flagged `far`; the blend is rebuilt from the
# stored donors and weights and each donor's own seed-year ratio, and the rebuild is validated on
# a country that IS donor-assigned before it is applied to the USA.

args <- commandArgs(trailingOnly = TRUE)
group <- if (length(args)) args[1] else "v5"
G <- file.path("output/pfm", group)

cs <- readRDS(file.path(G, "coupling", "coupling-summary.rds"))
fr <- readRDS(file.path(G, "frontier.rds"))
ad <- cs$anchorDerivation
theta <- cs$anchorTheta
seed <- cs$weights$baseYear

eCovered <- function(sec) {
  x <- fr$bySector[[sec]]$scores
  x <- x[x$year == seed, ]
  setNames(x$efficiencyRatio, as.character(x$region))
}
blend <- function(row, eCov) {
  dn <- strsplit(row$donors, ",")[[1]]; w <- as.numeric(strsplit(row$donorWeights, ",")[[1]])
  sum(w * eCov[dn]) / sum(w)
}

res <- list(); check <- list()
for (sec in c("Bulk", "Diffuse")) {
  da <- readRDS(file.path(G, sprintf("donor-assignment-band-%s.rds", sec)))
  eCov <- eCovered(sec)
  # validate the blend on the donor-assigned country with the most weight spread
  dd <- da[da$basis == "donor", ]
  errs <- vapply(seq_len(nrow(dd)), function(i) abs(blend(dd[i, ], eCov) - dd$efficiencyRatio[i]), numeric(1))
  check[[sec]] <- c(nDonorAssigned = nrow(dd), maxAbsErr = max(errs))
  # 1e-3, not 1e-6: the artifact stores donor weights rounded to 2-3 decimals ("0.38,0.34,0.28"),
  # which alone produces errors of ~2e-4. Anything larger means the blend is not the one used.
  if (max(errs) > 1e-3) stop("donor blend does not reproduce the artifact in ", sec,
                             " (max error ", signif(max(errs), 3), ") - the donor branch would be wrong")
  lowBand <- unique(da$efficiencyRatio[da$basis == "lowBand"])
  median  <- unique(da$efficiencyRatio[da$basis == "median" & da$region != "USA"])
  u <- da[da$region == "USA", ]
  res[[sec]] <- data.frame(sector = sec,
    branch = c("donor", "lowBand", "median"),
    E = c(blend(u, eCov), lowBand[1], if (length(median)) median[1] else u$efficiencyRatio),
    donors = u$donors, donorQuality = u$donorQuality, stringsAsFactors = FALSE)
}
b <- do.call(rbind, res)
b$g <- 1 - b$E
b$gMin <- ad$gapMin[match(b$sector, ad$sector)]; b$gMax <- ad$gapMax[match(b$sector, ad$sector)]
b$uRaw <- (b$g - b$gMin) / (b$gMax - b$gMin)
b$newEndpoint <- b$uRaw > 1 | b$uRaw < 0
b$u <- pmin(pmax(b$uRaw, 0), 1)

phi <- do.call(rbind, lapply(split(b, b$branch), function(x)
  data.frame(branch = x$branch[1], uBulk = x$u[x$sector == "Bulk"], uDiffuse = x$u[x$sector == "Diffuse"],
             bindingSector = x$sector[which.max(x$u)], phi = 1 - theta * max(x$u),
             newEndpoint = any(x$newEndpoint), EBulk = x$E[x$sector == "Bulk"], EDiffuse = x$E[x$sector == "Diffuse"])))

deployed <- unique(cs$boundAnchor$phi[cs$boundAnchor$region == "USA"])
rep <- phi$phi[phi$branch == "median"]
if (abs(rep - deployed) > 1e-4) stop("the median branch gives ", round(rep, 4), " but the artifact carries ",
                                      round(deployed, 4), " - the formula is not the one the bound uses")

cat(sprintf("USA offline feasibility share, %s, tier year %d, severity %.2f\n", group, cs$weights$year, theta))
cat(sprintf("  deployed (median) reproduced: %.4f vs artifact %.4f\n", rep, deployed))
print(phi, row.names = FALSE, digits = 4)
out <- list(branches = b, phi = phi, deployed = deployed, theta = theta, tierYear = cs$weights$year,
            seedYear = seed, blendCheck = check, group = group,
            note = "offline bound (coupling-summary.rds), not a coupled run; a branch flagged newEndpoint shifts every other region's u in that sector")
saveRDS(out, file.path(G, "usa-branch-phi.rds"))
cat("wrote", file.path(G, "usa-branch-phi.rds"), "\n")
