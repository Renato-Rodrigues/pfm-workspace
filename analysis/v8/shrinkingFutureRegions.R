# The shrinking future by region (companion of shrinkingFuture.R): the carbon price each region pays, and the CO2 each
# region emits, on the chain's result (its 2070 step), the one-shot run of the same closure and the no-politics reference.
#   Rscript analysis/v8/shrinkingFutureRegions.R [group] [runsDir]   (repo root; default v8, output/remind-runs/<group>/EU21)
#     -> output/pfm/<group>/coupling/shrinking-future-regions.rds, and three figures in output/pfm/<group>/coupling/
# Read from each run's fulldata.gdx: pm_taxCO2eq (T$/GtC -> $/tCO2), vm_emiAll (CO2, GtC -> GtCO2); phi from pfm-phi-history.rds (the last coupling call's path; the floor = the worse sector per region and
# year). Regional cumulative CO2 2020-2100 = trapezoid over the reported years (annual emissions interpolated linearly);
# the global sum of the differences is checked against pm_actualbudgetco2. Each step's plan is kept too: the regional
# price each step expected for the years after its window. Results to 2100 only (the paper's horizon). EU21 only.
suppressMessages({ library(gdx); library(magclass); library(ggplot2) })
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v8"
RD <- if (length(args) >= 2) args[2] else file.path("output/remind-runs", g, "EU21")
OUT <- file.path("output/pfm", g, "coupling"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
STEPS <- c(2030, 2040, 2050, 2060, 2070)
YRS <- c(2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060, 2070, 2080, 2090, 2100)
TCO2 <- 1000 / (44 / 12)
pre <- "SSP2-EU21-PkBudg1000-PFM-"

pick <- function(title) {
  d <- sort(Sys.glob(file.path(RD, paste0(pre, title, "_*"))), decreasing = TRUE)
  d <- d[file.exists(file.path(d, "fulldata.gdx"))]
  if (!length(d)) stop("missing run: ", title)
  d[1]
}
read1 <- function(key, closure, title, step = NA_integer_) {
  d <- pick(title); f <- file.path(d, "fulldata.gdx")
  tx <- readGDX(f, "pm_taxCO2eq")[, YRS, ] * TCO2
  e <- readGDX(f, "vm_emiAll", field = "l", restore_zeros = FALSE)[, YRS, "co2"] * 44 / 12
  # trapezoid between the reported years (linear interpolation of annual emissions, 2020-2100)
  dy <- diff(YRS); wt <- c(dy, 0) / 2 + c(0, dy) / 2
  reg <- getItems(tx, 1)
  pr <- expand.grid(region = reg, year = YRS, stringsAsFactors = FALSE)
  pr$price <- as.numeric(as.array(tx)[cbind(match(pr$region, reg), match(pr$year, YRS), 1)])
  pr$co2 <- as.numeric(as.array(e)[cbind(match(pr$region, getItems(e, 1)), match(pr$year, YRS), 1)])
  cum <- sapply(reg, function(r) sum(pr$co2[pr$region == r] * wt[match(pr$year[pr$region == r], YRS)]))
  ph <- NULL; hf <- file.path(d, "pfm-phi-history.rds")
  if (file.exists(hf)) {
    h <- readRDS(hf); h <- h[[length(h)]]$phiPath
    if (!is.null(h)) ph <- stats::aggregate(phi ~ region + year, data = h[h$year %in% YRS, ], FUN = min)
  }
  if (!is.null(ph)) pr <- merge(pr, ph, by = c("region", "year"), all.x = TRUE) else pr$phi <- NA_real_
  budget <- as.numeric(readGDX(f, "pm_actualbudgetco2")[, 2100, ])
  list(path = data.frame(key = key, closure = closure, step = step, pr),
       cum = data.frame(key = key, closure = closure, step = step, region = reg, cum2100 = as.numeric(cum)),
       budget = data.frame(key = key, closure = closure, budget2100 = budget))
}
runs <- c(
  list(read1("noPolitics", "hold the price", "noPolitics-holdPrice-v8"),
       read1("noPolitics", "hold the budget", "noPolitics-holdBudget-v8"),
       read1("oneShot", "hold the price", "holdPrice-v8"),
       read1("oneShot", "hold the budget", "holdBudget-v8")),
  lapply(STEPS, function(s) read1(paste0("step", s), "hold the price", paste0("holdPrice-shrinkingFuture", s, "-v8"), s)),
  lapply(STEPS, function(s) read1(paste0("step", s), "hold the budget", paste0("holdBudget-shrinkingFuture", s, "-v8"), s)))
P <- do.call(rbind, lapply(runs, `[[`, "path")); C <- do.call(rbind, lapply(runs, `[[`, "cum"))
B <- do.call(rbind, lapply(runs, `[[`, "budget"))
CHAIN <- paste0("step", max(STEPS))

# ---- prices: each region's price relative to the no-politics reference of the same closure ---------------------------
ref <- P[P$key == "noPolitics", c("closure", "region", "year", "price", "co2")]
names(ref)[4:5] <- c("priceRef", "co2Ref")
P <- merge(P, ref, by = c("closure", "region", "year"))
P$ratio <- P$price / P$priceRef
main <- P[P$key %in% c("oneShot", CHAIN), ]
main$run <- ifelse(main$key == "oneShot", "one-shot run", "chain result")
# the chain against the one-shot run, per region and year (price ratio)
w <- merge(main[main$run == "chain result", c("closure", "region", "year", "price", "ratio", "phi")],
           main[main$run == "one-shot run", c("closure", "region", "year", "price", "ratio", "phi")],
           by = c("closure", "region", "year"), suffixes = c(".chain", ".oneShot"))
w$chainOverOneShot <- w$price.chain / w$price.oneShot

# ---- the plans: what each step expected each region to pay after its window ----------------------------------------
plans <- P[grepl("^step", P$key) & P$year >= P$step + 10 & P$year <= 2100, c("closure", "step", "region", "year", "price", "ratio")]

# ---- regional cumulative CO2 2020-2100, against the no-politics reference ------------------------------------------
cr <- C[C$key == "noPolitics", c("closure", "region", "cum2100")]; names(cr)[3] <- "cumRef"
C <- merge(C, cr, by = c("closure", "region")); C$dcum <- C$cum2100 - C$cumRef
cm <- C[C$key %in% c("oneShot", CHAIN), ]; cm$run <- ifelse(cm$key == "oneShot", "one-shot run", "chain result")
br <- B[B$key == "noPolitics", c("closure", "budget2100")]; names(br)[2] <- "bRef"
chk <- merge(merge(stats::aggregate(dcum ~ closure + key, data = C, FUN = sum), B, by = c("closure", "key")), br, by = "closure")
chk$dBudget <- chk$budget2100 - chk$bRef

# ---- summaries ------------------------------------------------------------------------------------------------------
KY <- c(2030, 2040, 2050, 2060, 2070, 2080, 2100)
tabRatio <- stats::reshape(main[main$year %in% KY, c("closure", "run", "region", "year", "ratio")],
                           idvar = c("closure", "run", "region"), timevar = "year", direction = "wide")
spread <- do.call(rbind, lapply(split(main[main$year %in% KY, ], ~ closure + run + year, drop = TRUE), function(x)
  data.frame(closure = x$closure[1], run = x$run[1], year = x$year[1],
             ratioMin = min(x$ratio), ratioMedian = stats::median(x$ratio), ratioMax = max(x$ratio),
             minRegion = x$region[which.min(x$ratio)], maxRegion = x$region[which.max(x$ratio)],
             priceMin = min(x$price), priceMax = max(x$price), nBelow95 = sum(x$ratio < 0.95))))
spread <- spread[order(spread$closure, spread$run, spread$year), ]
# where the chain gives back the overshoot: the regional share of (one-shot minus chain) cumulative CO2
cw <- stats::reshape(cm[, c("closure", "region", "run", "dcum")], idvar = c("closure", "region"), timevar = "run", direction = "wide")
names(cw) <- sub("dcum.", "", names(cw), fixed = TRUE)
cw$recovered <- cw$`one-shot run` - cw$`chain result`
cw <- do.call(rbind, lapply(split(cw, cw$closure), function(x) { x$shareRecovered <- if (abs(sum(x$recovered)) > 1) x$recovered / sum(x$recovered) else NA_real_;  # hold the budget nets to ~0
   x[order(-x$recovered), ] }))

saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), runsDir = RD, paths = P, chainVsOneShot = w,
             plans = plans, cumulative = C, check = chk, ratios = tabRatio, spread = spread, recovered = cw),
        file.path(OUT, "shrinking-future-regions.rds"))

# ---- figures ------------------------------------------------------------------------------------------------------
cap <- paste0("Model version ", g, "; REMIND EU21, SSP2, 1000 Gt budget, theta 0.50. The chain's result is its 2070 step;\n",
              "each step fixes the past to the step before and caps the price only in its own 10-year window. Prices: the floor
",
              "every market pays (pm_taxCO2eq); the markup of the less constrained sector is not included.")
thm <- theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.grid.minor = element_blank(),
                                             plot.caption = element_text(hjust = 0, size = 8))
col <- c("no-politics reference" = "grey45", "one-shot run" = "#C2571A", "chain result" = "#1B6CA8")
ordR <- with(main[main$closure == "hold the price" & main$run == "one-shot run" & main$year == 2050, ], region[order(ratio)])

# 1. regional price paths, hold the price, small multiples
pp <- rbind(transform(P[P$key == "noPolitics", ], run = "no-politics reference"), main)
pp <- pp[pp$closure == "hold the price", ]; pp$region <- factor(pp$region, levels = ordR)
pp$run <- factor(pp$run, levels = names(col))
f1 <- ggplot(pp, aes(year, price, colour = run)) + geom_line(linewidth = 0.7) + facet_wrap(~region, ncol = 7) +
  scale_colour_manual(values = col, name = NULL) + scale_x_continuous(breaks = c(2030, 2060, 2090)) +
  labs(x = NULL, y = "carbon price, US$ per t CO2", title = "Hold the price: the carbon price in each region",
       caption = paste0(cap, "\nRegions ordered by the one-shot run's 2050 price relative to the reference (lowest first). Where the one-shot run's\nline is not visible it lies under the chain's: the two prices are equal to within about 1%, except REF in 2045-2055.")) + thm
ggsave(file.path(OUT, "fig-shrinking-future-regional-prices.png"), f1, width = 11, height = 6.4, dpi = 200)

# 2. heat map: price relative to the no-politics reference, region x year, both runs and both closures
hm <- main[main$year %in% KY, ]; hm$region <- factor(hm$region, levels = ordR)
hm$run <- factor(hm$run, levels = c("one-shot run", "chain result"))
hm$closure <- factor(hm$closure, levels = c("hold the price", "hold the budget"))
f2 <- ggplot(hm, aes(factor(year), region, fill = ratio)) + geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%.2f", ratio)), size = 2.1) +
  scale_fill_gradient2(low = "#B2182B", mid = "grey96", high = "#2166AC", midpoint = 1, name = "price / reference price") +
  facet_grid(~closure + run) +
  labs(x = NULL, y = NULL, title = "Each region's carbon price relative to the no-politics reference", caption = cap) +
  thm + theme(panel.grid = element_blank(), legend.key.width = unit(1.4, "cm"))
ggsave(file.path(OUT, "fig-shrinking-future-regional-price-ratio.png"), f2, width = 12, height = 6, dpi = 200)

# 3. regional cumulative CO2 2020-2100 above the reference
cb <- cm; cb$region <- factor(cb$region, levels = cw$region[cw$closure == "hold the price"])
cb$run <- factor(cb$run, levels = c("one-shot run", "chain result"))
cb$closure <- factor(cb$closure, levels = c("hold the price", "hold the budget"))
f3 <- ggplot(cb, aes(dcum, region, fill = run)) + geom_vline(xintercept = 0, colour = "grey60") +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) + facet_wrap(~closure) +
  scale_fill_manual(values = col[c("one-shot run", "chain result")], name = NULL) +
  labs(x = "cumulative CO2 2020-2100 above the no-politics reference, Gt", y = NULL,
       title = "Where the extra CO2 is emitted, and where the chain gives it back", caption = cap) + thm
ggsave(file.path(OUT, "fig-shrinking-future-regional-co2.png"), f3, width = 10, height = 6, dpi = 200)

# 4. the range over regions: price relative to the reference, median line, interquartile band (dark) and min-max band
#    (light), the one-shot run and the chain, with the regions at the two ends named in 2100
rs <- main[main$year >= 2025, ]
band <- do.call(rbind, lapply(split(rs, ~ closure + run + year, drop = TRUE), function(x) {
  q <- stats::quantile(x$ratio, c(0, 0.25, 0.5, 0.75, 1), names = FALSE)
  data.frame(closure = x$closure[1], run = x$run[1], year = x$year[1], lo = q[1], q1 = q[2], med = q[3], q3 = q[4], hi = q[5],
             loR = x$region[which.min(x$ratio)], hiR = x$region[which.max(x$ratio)])
}))
band$closure <- factor(band$closure, levels = c("hold the price", "hold the budget"))
band$run <- factor(band$run, levels = c("one-shot run", "chain result"))
ends <- band[band$year == 2100, ]
f4 <- ggplot(band, aes(year)) + geom_hline(yintercept = 1, colour = "grey55", linetype = "22") +
  geom_ribbon(aes(ymin = lo, ymax = hi, fill = run), alpha = 0.13) +
  geom_ribbon(aes(ymin = q1, ymax = q3, fill = run), alpha = 0.30) +
  geom_line(aes(y = med, colour = run), linewidth = 0.9) +
  geom_text(data = ends, aes(x = 2101, y = lo, label = loR, colour = run), hjust = 0, size = 2.6,
            position = position_nudge(y = ifelse(ends$run == "chain result", -0.02, 0.02)), show.legend = FALSE) +
  geom_text(data = ends, aes(x = 2101, y = hi, label = hiR, colour = run), hjust = 0, size = 2.6,
            position = position_nudge(y = ifelse(ends$run == "chain result", 0.02, -0.02)), show.legend = FALSE) +
  facet_wrap(~closure) + scale_colour_manual(values = col, name = NULL, aesthetics = c("colour", "fill")) +
  scale_x_continuous(limits = c(2025, 2108), breaks = seq(2030, 2100, 10)) +
  labs(x = NULL, y = "carbon price relative to the\nno-politics reference",
       title = "The 21 regions' carbon price relative to the reference: median, interquartile range and full range",
       caption = paste0(cap, "\nLine: median over regions; dark band: interquartile range; light band: lowest to highest region ",
                        "(named in 2100). Under hold the price the two runs' bands coincide.")) + thm
ggsave(file.path(OUT, "fig-shrinking-future-regional-price-range.png"), f4, width = 10, height = 4.8, dpi = 200)

# 5. box and whisker: the distribution over regions of the price relative to the reference, by year
bx <- main[main$year %in% KY, ]
bx$closure <- factor(bx$closure, levels = c("hold the price", "hold the budget"))
bx$run <- factor(bx$run, levels = c("one-shot run", "chain result"))
f5 <- ggplot(bx, aes(factor(year), ratio, fill = run, colour = run)) + geom_hline(yintercept = 1, colour = "grey55", linetype = "22") +
  geom_boxplot(alpha = 0.25, width = 0.7, outlier.shape = NA, position = position_dodge(width = 0.8), linewidth = 0.45) +
  geom_point(position = position_jitterdodge(jitter.width = 0.12, dodge.width = 0.8, seed = 1), size = 0.9, alpha = 0.7) +
  facet_wrap(~closure) + scale_colour_manual(values = col, name = NULL, aesthetics = c("colour", "fill")) +
  labs(x = NULL, y = "carbon price relative to the\nno-politics reference",
       title = "Each region's carbon price relative to the reference: the distribution over the 21 regions",
       caption = paste0(cap, "\nBox: interquartile range and median; whiskers: up to 1.5 times the interquartile range; points: the regions.")) + thm
ggsave(file.path(OUT, "fig-shrinking-future-regional-price-box.png"), f5, width = 10, height = 4.6, dpi = 200)

# 6. box and whisker: regional cumulative CO2 2020-2100 above the reference, the regions beyond 2 Gt named
cb2 <- cm; cb2$closure <- factor(cb2$closure, levels = c("hold the price", "hold the budget"))
cb2$run <- factor(cb2$run, levels = c("one-shot run", "chain result"))
f6 <- ggplot(cb2, aes(run, dcum, colour = run, fill = run)) + geom_hline(yintercept = 0, colour = "grey55") +
  geom_line(aes(group = region), colour = "grey75", linewidth = 0.35) +
  geom_boxplot(alpha = 0.2, width = 0.45, outlier.shape = NA, linewidth = 0.45) +
  geom_point(size = 1.4, alpha = 0.8) +
  ggrepel::geom_text_repel(data = cb2[abs(cb2$dcum) > 2 & cb2$run == "one-shot run", ], aes(label = region), size = 2.5,
                           show.legend = FALSE, nudge_x = -0.3, direction = "y", hjust = 1, segment.size = 0.2, min.segment.length = 0) +
  ggrepel::geom_text_repel(data = cb2[abs(cb2$dcum) > 2 & cb2$run == "chain result", ], aes(label = region), size = 2.5,
                           show.legend = FALSE, nudge_x = 0.3, direction = "y", hjust = 0, segment.size = 0.2, min.segment.length = 0) +
  facet_wrap(~closure) + scale_colour_manual(values = col, name = NULL, aesthetics = c("colour", "fill")) +
  labs(x = NULL, y = "cumulative CO2 2020-2100 above the\nno-politics reference, Gt",
       title = "Regional cumulative CO2 above the reference: each region on the one-shot run and on the chain",
       caption = paste0(cap, "\nGrey lines join a region's two values; regions beyond 2 Gt are named.")) + thm +
  theme(legend.position = "none")
ggsave(file.path(OUT, "fig-shrinking-future-regional-co2-box.png"), f6, width = 9, height = 5, dpi = 200)

options(width = 220)
cat("\n== check: sum of regional differences vs pm_actualbudgetco2 differences (Gt) ==\n"); print(chk, row.names = FALSE, digits = 5)
cat("\n== spread of the price ratio over regions ==\n"); print(spread, row.names = FALSE, digits = 3)
cat("\n== price ratio to the reference, by region ==\n"); print(tabRatio[order(tabRatio$closure, tabRatio$run, tabRatio$region), ], row.names = FALSE, digits = 3)
cat("\n== regional cumulative CO2 above the reference, and the part the chain gives back ==\n"); print(cw, row.names = FALSE, digits = 3)
cat("\n== chain over one-shot price, median over regions by year ==\n")
print(stats::aggregate(chainOverOneShot ~ closure + year, data = w[w$year %in% KY, ], FUN = function(x) round(c(min = min(x), med = stats::median(x), max = max(x)), 3)))
