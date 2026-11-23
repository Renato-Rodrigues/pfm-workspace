# The mechanism behind the expectation effect (the NCC paper's claim C7; design note 0012 sec. 5):
#   Rscript analysis/v8/expectationsMechanism.R [group]   (repo root; default v8)
#   -> output/pfm/<group>/coupling/expectations-mechanism.rds
# With the price path held, the decade chain (each decade expecting the political limit to lift after it) adds about half
# the CO2 of the one-shot run (the same limit known to last) at nearly the same prices paid (shrinking-future.rds). The
# claim to test: the chain builds the low-carbon energy system earlier. Compared here, world totals over the EU21 regions,
# 2025-2060, the chain's realised path (its last step, whose past is fixed to the earlier steps) against the one-shot run
# and the no-politics reference, all hold the price:
#   - electricity capacity by group (vm_cap, summed over grades), TW, and new capacity (vm_deltaCap), TW a year;
#   - the electricity share of final energy (vm_prodFe), and final energy itself, EJ a year.
# An accounting of the model's response, not a causal statement about investors. Offline; reads the runs' fulldata.gdx.
suppressMessages({ library(gdx); library(magclass) })
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
CPL <- file.path("output/pfm", g, "coupling")
say <- function(...) message("[expectations-mechanism:", g, "] ", ...)
sf <- readRDS(file.path(CPL, "shrinking-future.rds"))
R <- sf$runs; RD <- sf$runsDir
pick <- function(key) { d <- R$dir[R$key == key & R$closure == "hold the price"]; if (length(d) != 1) stop("no unique run for ", key); file.path(RD, d, "fulldata.gdx") }
RUNS <- c("no-politics reference" = pick("noPolitics"), "one-shot (limit known to last)" = pick("oneShot"),
          "chain (limit expected to lift)" = pick("step2070"))
YRS <- c(2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060)
TW2GW <- 1000; TWa2EJ <- 31.536
# electricity technologies by group (REMIND names); anything else producing seel is "other"
GROUPS <- list(
  "wind and solar" = c("spv", "csp", "windon", "windoff", "wind"),
  "other low-carbon" = c("hydro", "tnrs", "fnrs", "geohdr", "bioigccc", "biochp", "bioigcc", "biohp"),
  "fossil with CCS" = c("igccc", "pcc", "pco", "ngccc", "gasccc"),
  "fossil" = c("pc", "coalchp", "igcc", "ngcc", "ngt", "gaschp", "dot", "oilchp", "coalhp", "gashp"))
grp <- function(te) { out <- rep(NA_character_, length(te)); for (n in names(GROUPS)) out[te %in% GROUPS[[n]]] <- n; out }

one <- function(lab, f) {
  if (!file.exists(f)) stop("missing ", f)
  cap <- readGDX(f, "vm_cap", field = "l", restore_zeros = FALSE); dc <- readGDX(f, "vm_deltaCap", field = "l", restore_zeros = FALSE)
  yrs <- intersect(YRS, getYears(cap, as.integer = TRUE))
  tes <- getItems(cap, dim = 3.1); tes <- tes[!is.na(grp(tes))]
  rows <- list()
  for (te in tes) {
    c1 <- dimSums(cap[, yrs, te], dim = c(1, 3)); d1 <- dimSums(dc[, yrs, te], dim = c(1, 3))
    rows[[te]] <- data.frame(run = lab, te = te, group = grp(te), year = yrs, capTW = as.numeric(c1), addTWyr = as.numeric(d1))
  }
  cap <- do.call(rbind, rows)
  fe <- readGDX(f, "vm_prodFe", field = "l", restore_zeros = FALSE)
  feYrs <- intersect(YRS, getYears(fe, as.integer = TRUE))
  ent <- getItems(fe, dim = 3.2)
  feTot <- as.numeric(dimSums(fe[, feYrs, ], dim = c(1, 3))) * TWa2EJ
  feEl <- as.numeric(dimSums(fe[, feYrs, ent[ent == "feels"]], dim = c(1, 3))) * TWa2EJ
  list(cap = cap, fe = data.frame(run = lab, year = feYrs, feEJ = feTot, elecEJ = feEl, elecShare = feEl / feTot))
}
res <- lapply(names(RUNS), function(l) { say("reading ", basename(dirname(RUNS[[l]]))); one(l, RUNS[[l]]) })
cap <- do.call(rbind, lapply(res, `[[`, "cap")); fe <- do.call(rbind, lapply(res, `[[`, "fe"))
byGroup <- stats::aggregate(cbind(capTW, addTWyr) ~ run + group + year, data = cap, FUN = sum)
# the chain against the one-shot run, by group and year
w <- reshape(byGroup[, c("run", "group", "year", "capTW")], idvar = c("group", "year"), timevar = "run", direction = "wide")
names(w) <- sub("^capTW\\.", "", names(w))
w$chainMinusOneShotGW <- (w[["chain (limit expected to lift)"]] - w[["one-shot (limit known to last)"]]) * TW2GW
fw <- reshape(fe[, c("run", "year", "elecShare")], idvar = "year", timevar = "run", direction = "wide")
names(fw) <- sub("^elecShare\\.", "", names(fw))
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), runs = RUNS, groups = GROUPS, capacity = byGroup, byTechnology = cap,
            finalEnergy = fe, chainMinusOneShot = w[order(w$group, w$year), ], electricityShare = fw,
            note = paste("World totals over the EU21 regions; hold the price, theta 0.50, fading limit. The chain's path is its last step",
                         "(2070), whose past is fixed to the earlier steps. vm_cap summed over grades (TW), vm_deltaCap (TW a year),",
                         "vm_prodFe (TWa a year -> EJ). An accounting of the model's response, not a causal claim."))
saveRDS(out, file.path(CPL, "expectations-mechanism.rds")); say("wrote ", file.path(CPL, "expectations-mechanism.rds"))
options(width = 200)
cat("\n== electricity capacity, chain minus one-shot, GW ==\n")
print(stats::xtabs(chainMinusOneShotGW ~ group + year, data = out$chainMinusOneShot), digits = 3)
cat("\n== electricity share of final energy ==\n"); print(out$electricityShare, digits = 3, row.names = FALSE)
