# The shrinking future (sequential runs, COUPLING.md 14.1): what each step of the two chains planned, what the chain
# delivered, and how that compares with the one-shot run of the same closure and with the no-politics reference.
#   Rscript analysis/v8/shrinkingFuture.R [group] [runsDir]   (repo root; default v8, output/remind-runs/<group>/EU21)
#     -> output/pfm/<group>/coupling/shrinking-future.rds, and three figures in output/pfm/<group>/coupling/
# Each step tau fixes 2005..tau-5 to the previous step (path_gdx_ref) and caps the price only in [tau, tau+10); after the
# window it plans unconstrained (hold the price: on the no-politics price; hold the budget: whatever meets the budget from
# its fixed past). The chain's result is its last step (2070): its past is the concatenation of every step's window.
# A step's own run is therefore two things: the realised path up to its window's end, and the PLAN it made for the rest
# - the plan the next step revises. Read from each run's fulldata.gdx: vm_emiAll (CO2, GtC -> GtCO2), pm_actualbudgetco2
# (cumulative CO2 from 2020, Gt), pm_taxCO2eq (T$/GtC -> $/tCO2), p45_taxCO2eq_anchor; phi from pfm-phi-history.rds
# (the last coupling call's path). Results to 2100 only (the paper's horizon). EU21 only: the chains were run at EU21.
suppressMessages({ library(gdx); library(magclass); library(ggplot2) })
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v8"
RD <- if (length(args) >= 2) args[2] else file.path("output/remind-runs", g, "EU21")
OUT <- file.path("output/pfm", g, "coupling"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
STEPS <- c(2030, 2040, 2050, 2060, 2070)
YRS <- c(2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060, 2070, 2080, 2090, 2100)
TCO2 <- 1000 / (44 / 12)
pre <- "SSP2-EU21-PkBudg1000-PFM-"

# the newest folder of a title; a run is finished when its log says so (REMIND's own completion line)
pick <- function(title) {
  d <- sort(Sys.glob(file.path(RD, paste0(pre, title, "_*"))), decreasing = TRUE)
  d <- d[file.exists(file.path(d, "fulldata.gdx"))]
  if (!length(d)) return(NULL)
  fin <- any(grepl("Normal completion", readLines(file.path(d[1], "log.txt"), warn = FALSE)))
  list(dir = d[1], finished = fin)
}
read1 <- function(key, closure, title, step = NA_integer_) {
  p <- pick(title); if (is.null(p)) { message("[shrinkingFuture] missing: ", title); return(NULL) }
  f <- file.path(p$dir, "fulldata.gdx")
  e <- readGDX(f, "vm_emiAll", field = "l", restore_zeros = FALSE)[, , "co2"]
  co2 <- as.numeric(dimSums(e, dim = 1)[, YRS, ]) * 44 / 12
  cum <- readGDX(f, "pm_actualbudgetco2"); cum <- as.numeric(cum[, YRS, ])
  tx <- readGDX(f, "pm_taxCO2eq")[, YRS, ] * TCO2
  # emissions-weighted mean price over regions (positive CO2 only; the price that the emitting regions face)
  w <- pmax(e[, YRS, ], 0); w <- w / pmax(dimSums(w, dim = 1), 1e-12)
  pW <- as.numeric(dimSums(tx * w, dim = 1))
  anc <- readGDX(f, "p45_taxCO2eq_anchor", react = "silent"); anc <- if (is.null(anc)) NA else as.numeric(anc[, YRS, ]) * TCO2
  path <- data.frame(key = key, closure = closure, step = step, year = YRS, co2 = co2, cum = cum,
                     priceW = pW, priceMed = apply(as.array(tx), 2, stats::median), anchor = anc)
  # phi: the last coupling call's path, the worse sector (the floor) per region and year
  ph <- NULL; hf <- file.path(p$dir, "pfm-phi-history.rds")
  if (file.exists(hf)) {
    h <- readRDS(hf); h <- h[[length(h)]]$phiPath
    if (!is.null(h)) {
      fl <- stats::aggregate(phi ~ region + year, data = h, FUN = min)
      ph <- data.frame(key = key, closure = closure, step = step, stats::aggregate(phi ~ year, data = fl[fl$year %in% YRS, ],
                                                                                   FUN = stats::median))
    }
  }
  list(path = path, phi = ph, run = data.frame(key = key, closure = closure, step = step, dir = basename(p$dir),
                                               finished = p$finished,
                                               cum2100 = cum[YRS == 2100], peakCum = max(cum[YRS <= 2100]),
                                               peakYear = YRS[which.max(cum[YRS <= 2100])]))
}

runs <- c(
  list(read1("noPolitics", "hold the budget", "noPolitics-holdBudget-v8"),
       read1("noPolitics", "hold the price", "noPolitics-holdPrice-v8"),
       read1("oneShot", "hold the price", "holdPrice-v8"),
       read1("oneShot", "hold the budget", "holdBudget-v8")),
  lapply(STEPS, function(s) read1(paste0("step", s), "hold the price", paste0("holdPrice-shrinkingFuture", s, "-v8"), s)),
  lapply(STEPS, function(s) read1(paste0("step", s), "hold the budget", paste0("holdBudget-shrinkingFuture", s, "-v8"), s)))
runs <- Filter(Negate(is.null), runs)
P <- do.call(rbind, lapply(runs, `[[`, "path")); PH <- do.call(rbind, lapply(runs, `[[`, "phi"))
R <- do.call(rbind, lapply(runs, `[[`, "run"))

# per closure: the plan each step made (cumulative CO2 to 2100 as that step expected it), against the chain's result
# (the last step), the one-shot run and the no-politics reference
summ <- do.call(rbind, lapply(c("hold the price", "hold the budget"), function(cl) {
  r <- R[R$closure == cl, ]; np <- r$cum2100[r$key == "noPolitics"]; os <- r$cum2100[r$key == "oneShot"]
  last <- r[r$key == paste0("step", max(STEPS)), ]
  data.frame(closure = cl, noPolitics = np, oneShot = os, chain = if (nrow(last)) last$cum2100 else NA,
             chainFinished = if (nrow(last)) last$finished else NA,
             oneShotOverNoPolitics = os - np, chainOverNoPolitics = if (nrow(last)) last$cum2100 - np else NA,
             chainOverOneShot = if (nrow(last)) last$cum2100 - os else NA)
}))
plans <- R[grepl("^step", R$key), c("closure", "step", "finished", "cum2100", "peakCum", "peakYear")]
plans <- merge(plans, summ[, c("closure", "noPolitics", "oneShot")], by = "closure")
plans$planOverNoPolitics <- plans$cum2100 - plans$noPolitics
# what each step's window added: cumulative CO2 between tau and tau+10 on the chain's realised path (the last step's
# run carries the whole realised past), against the same window on the one-shot run and the no-politics reference
win <- do.call(rbind, lapply(c("hold the price", "hold the budget"), function(cl) {
  last <- P[P$closure == cl & P$key == paste0("step", max(STEPS)), ]
  os <- P[P$closure == cl & P$key == "oneShot", ]; np <- P[P$closure == cl & P$key == "noPolitics", ]
  if (!nrow(last)) return(NULL)
  do.call(rbind, lapply(STEPS, function(s) {
    e <- if (s == max(STEPS)) 2100 else s + 10
    d <- function(x) x$cum[x$year == e] - x$cum[x$year == s]
    data.frame(closure = cl, window = paste0(s, "-", e), chain = d(last), oneShot = d(os), noPolitics = d(np))
  }))
}))

saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), runsDir = RD, runs = R, paths = P, phi = PH,
             summary = summ, plans = plans, windows = win), file.path(OUT, "shrinking-future.rds"))

# ---- figures ------------------------------------------------------------------------------------------------------
col <- c("no-politics reference" = "grey45", "one-shot run" = "#C2571A", "chain result (2070 step)" = "#1B6CA8")
lab <- function(k, s) ifelse(k == "noPolitics", "no-politics reference", ifelse(k == "oneShot", "one-shot run",
                                                                                   ifelse(s == max(STEPS), "chain result (2070 step)", "plan of an earlier step")))
P$role <- lab(P$key, P$step)
P$role <- factor(P$role, levels = c("no-politics reference", "one-shot run", "plan of an earlier step", "chain result (2070 step)"))
P$closure <- factor(P$closure, levels = c("hold the price", "hold the budget"))
cap <- paste0("Model version ", g, "; REMIND EU21, SSP2, 1000 Gt budget, theta 0.50.\nEach step fixes the past to the step ",
              "before and caps the price only in its own 10-year window.")
thm <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank(),
                                             plot.caption = element_text(hjust = 0, size = 8.5))
# emissions as the difference from the no-politics reference of the same closure: the levels are within a few Gt of
# each other on a 40 Gt scale, so the differences are what can be read
ref <- P[P$key == "noPolitics", c("closure", "year", "co2")]; names(ref)[3] <- "co2ref"
P <- merge(P, ref, by = c("closure", "year")); P$dco2 <- P$co2 - P$co2ref
P <- P[order(P$closure, P$key, P$year), ]
plans1 <- P[P$role == "plan of an earlier step" & P$year >= P$step, ]
lines1 <- P[P$role != "plan of an earlier step", ]
p1 <- ggplot() + geom_hline(yintercept = 0, colour = "grey70") +
  geom_line(data = plans1, aes(year, dco2, group = step), colour = "#1B6CA8", alpha = 0.45, linewidth = 0.6, linetype = "22") +
  geom_line(data = lines1[lines1$role != "no-politics reference", ], aes(year, dco2, colour = role), linewidth = 0.9) +
  facet_wrap(~closure) + scale_colour_manual(values = col, name = NULL) +
  labs(x = NULL, y = "CO2 emissions above the\nno-politics reference, Gt per year",
       caption = paste0(cap, " Dashed: the plan each earlier step made for its future.")) + thm
ggsave(file.path(OUT, "fig-shrinking-future-emissions.png"), p1, width = 9, height = 4.6, dpi = 200)

pl <- plans; pl$closure <- factor(pl$closure, levels = c("hold the price", "hold the budget"))
p2 <- ggplot(pl, aes(step, planOverNoPolitics)) + geom_hline(yintercept = 0, colour = "grey70") +
  geom_col(fill = "#1B6CA8", width = 6) +
  geom_hline(data = transform(summ, closure = factor(closure, levels = levels(pl$closure))),
             aes(yintercept = oneShotOverNoPolitics), colour = "#C2571A", linewidth = 0.8) +
  facet_wrap(~closure) + scale_x_continuous(breaks = STEPS) +
  labs(x = "step (start year of its window)", y = "planned cumulative CO2 2020-2100\nabove the no-politics reference, Gt",
       caption = paste0(cap, "\nBars: what each step planned; the last bar is the chain's result. Orange line: the one-shot run.")) + thm
ggsave(file.path(OUT, "fig-shrinking-future-plans.png"), p2, width = 9, height = 4.4, dpi = 200)

pr <- P[P$role != "plan of an earlier step", ]
p3 <- ggplot(pr, aes(year, priceW, colour = role)) + geom_line(linewidth = 0.9) +
  facet_wrap(~closure) + scale_colour_manual(values = col, name = NULL) +
  labs(x = NULL, y = "carbon price, US$ per t CO2\n(emissions-weighted mean over regions)", caption = cap) + thm
ggsave(file.path(OUT, "fig-shrinking-future-prices.png"), p3, width = 9, height = 4.6, dpi = 200)

options(width = 200)
cat("\n== runs ==\n"); print(R[, c("closure", "key", "finished", "cum2100", "peakCum", "peakYear", "dir")], row.names = FALSE, digits = 5)
cat("\n== summary (cumulative CO2 2020-2100, Gt) ==\n"); print(summ, row.names = FALSE, digits = 5)
cat("\n== plans ==\n"); print(plans, row.names = FALSE, digits = 5)
cat("\n== windows (cumulative CO2 in each step's window, Gt) ==\n"); print(win, row.names = FALSE, digits = 4)
cat("\n== phi (median over regions of the floor share) ==\n")
print(stats::reshape(PH[PH$year %in% c(2030, 2040, 2050, 2060, 2070, 2080), ], idvar = c("closure", "key"), timevar = "year",
                     direction = "wide", drop = "step"), row.names = FALSE, digits = 3)
