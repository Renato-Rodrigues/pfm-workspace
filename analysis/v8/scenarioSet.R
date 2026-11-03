# One closure's set of coupled runs, world and regions: the headline, θ and the sensitivity runs of the v8 batch against
# the no-politics reference of the same closure (docs/SCENARIOS.md 2.3, 4.2a-4.9). The shrinking-future chains are
# analysed apart (shrinkingFuture.R, shrinkingFutureRegions.R).
#   Rscript analysis/v8/scenarioSet.R <price|budget> [group]     (repo root; default v8)
#     -> output/pfm/<group>/coupling/scenario-set-<closure>.rds and the figures fig-set-<closure>-*.png beside it
# Read from each run's fulldata.gdx: vm_emiAll (CO2, GtC -> GtCO2), pm_actualbudgetco2 (cumulative CO2 from 2020, Gt),
# pm_taxCO2eq (T$/GtC -> $/tCO2), p45_taxCO2eq_anchor; phi from pfm-phi-history.rds (the last coupling call; the floor =
# the worse sector per region and year); GDP and consumption from coupled-costs.json (coupledCostsAndAbatement.R).
# Regional cumulative CO2 2020-2100 = trapezoid over the reported years (checked against pm_actualbudgetco2).
# Relocated CO2 = half the sum over regions of |regional change|. Results to 2100 only (the paper's horizon).
suppressMessages({ library(gdx); library(magclass); library(ggplot2) })
args <- commandArgs(trailingOnly = TRUE)
CL <- if (length(args)) match.arg(args[1], c("price", "budget")) else "price"
g <- if (length(args) >= 2) args[2] else "v8"
RR <- file.path("output/remind-runs", g); OUT <- file.path("output/pfm", g, "coupling")
YRS <- c(2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060, 2070, 2080, 2090, 2100)
TCO2 <- 1000 / (44 / 12)
closureTitle <- c(price = "holdPrice", budget = "holdBudget")[[CL]]
closureLabel <- c(price = "hold the price", budget = "hold the budget")[[CL]]
costKey <- c(price = "levelBfix", budget = "levelC")[[CL]]

# the set: label, family, title suffix, cost-json suffix, resolutions
V <- data.frame(stringsAsFactors = FALSE, rbind(
  c("θ 0.325", "severity", "-theta325", "Th325", "EU21 H12"),
  c("central (θ 0.50)", "central", "", "", "EU21 H12"),
  c("θ 0.675", "severity", "-theta675", "Th675", "EU21 H12"),
  c("growing limit", "persistence", "-growingLimit", "-backslide", "EU21"),
  c("constant limit", "persistence", "-constantLimit", "-Ehold", "EU21"),
  c("historical erosion", "persistence", "-erosionHistorical", "-kappaHist", "EU21"),
  c("historical erosion (v8 rates)", "persistence", "-erosionHistoricalV8", "-kappaHistV8", "EU21"),
  c("erosion 2%", "persistence", "-erosion2", "-kappa02", "EU21"),
  c("erosion 2.7%", "persistence", "-erosion2p7", "-kappa", "EU21 H12"),
  c("erosion 5%", "persistence", "-erosion5", "-kappa05", "EU21"),
  c("common strength", "strength and rents", "-commonStrength", "-common", "EU21 H12"),
  c("gap first", "strength and rents", "-gapFirst", "-gapfirst", "EU21"),
  c("world-price rents", "strength and rents", "-rentsWorldPrice", "-rentsWorld", "EU21 H12"),
  c("institutions held", "institutions", "-institutionsHeld", "-held", "EU21 H12"),
  c("Andrijevic institutions", "institutions", "-institutionsAndrijevic", "-gcA", "EU21 H12"),
  c("storyline institutions", "institutions", "-institutionsStoryline", "-story", "EU21")))
names(V) <- c("label", "family", "suffix", "costSuffix", "res")
OPTIONAL <- "historical erosion (v8 rates)"   # added 2026-11-03 (V8KAPPAEU21): skipped until it has run
FAM <- c("severity", "persistence", "strength and rents", "institutions")

pick <- function(res, title) {
  d <- sort(Sys.glob(file.path(RR, res, paste0(title, "_*"))), decreasing = TRUE)
  d <- d[file.exists(file.path(d, "fulldata.gdx"))]
  if (!length(d)) stop("missing run: ", res, " ", title)
  d[1]
}
prefix <- function(res) if (res == "EU21") "SSP2-EU21-PkBudg1000-PFM-" else "SSP2-PkBudg1000-PFM-"
dy <- diff(YRS); wt <- c(dy, 0) / 2 + c(0, dy) / 2
read1 <- function(res, label, family, title) {
  d <- pick(res, title); f <- file.path(d, "fulldata.gdx")
  tx <- readGDX(f, "pm_taxCO2eq")[, YRS, ] * TCO2
  e <- readGDX(f, "vm_emiAll", field = "l", restore_zeros = FALSE)[, YRS, "co2"] * 44 / 12
  reg <- getItems(tx, 1)
  rg <- expand.grid(region = reg, year = YRS, stringsAsFactors = FALSE)
  rg$price <- as.numeric(as.array(tx)[cbind(match(rg$region, reg), match(rg$year, YRS), 1)])
  rg$co2 <- as.numeric(as.array(e)[cbind(match(rg$region, getItems(e, 1)), match(rg$year, YRS), 1)])
  ph <- NULL; hf <- file.path(d, "pfm-phi-history.rds")
  if (file.exists(hf)) { h <- readRDS(hf); h <- h[[length(h)]]$phiPath
    if (!is.null(h)) ph <- stats::aggregate(phi ~ region + year, data = h[h$year %in% YRS, ], FUN = min) }
  rg <- if (!is.null(ph)) merge(rg, ph, by = c("region", "year"), all.x = TRUE) else transform(rg, phi = NA_real_)
  cum <- tapply(seq_len(nrow(rg)), rg$region, function(i) sum(rg$co2[i] * wt[match(rg$year[i], YRS)]))
  glob <- stats::aggregate(co2 ~ year, data = rg, FUN = sum)
  w <- pmax(rg$co2, 0); ws <- tapply(w, rg$year, sum)
  glob$priceW <- as.numeric(tapply(rg$price * w, rg$year, sum) / ws)[match(glob$year, as.numeric(names(ws)))]
  glob$cum <- as.numeric(readGDX(f, "pm_actualbudgetco2")[, YRS, ])
  anc <- readGDX(f, "p45_taxCO2eq_anchor", react = "silent")
  glob$anchor <- if (is.null(anc)) NA_real_ else as.numeric(anc[, YRS, ]) * TCO2
  list(regions = data.frame(res = res, label = label, family = family, rg),
       cum = data.frame(res = res, label = label, family = family, region = names(cum), cum2100 = as.numeric(cum)),
       world = data.frame(res = res, label = label, family = family, glob), dir = basename(d))
}

runs <- list()
for (res in c("EU21", "H12")) {
  pre <- prefix(res)
  runs[[length(runs) + 1]] <- read1(res, "no-politics reference", "reference", paste0(pre, "noPolitics-", closureTitle, "-v8"))
  for (i in seq_len(nrow(V))) if (grepl(res, V$res[i])) {
    r <- tryCatch(read1(res, V$label[i], V$family[i], paste0(pre, closureTitle, V$suffix[i], "-v8")),
                  error = function(e) if (V$label[i] %in% OPTIONAL) { message("[scenarioSet] skipped (not run yet): ", V$label[i]); NULL } else stop(e))
    if (!is.null(r)) runs[[length(runs) + 1]] <- r
  }
}
RG <- do.call(rbind, lapply(runs, `[[`, "regions")); CU <- do.call(rbind, lapply(runs, `[[`, "cum"))
WO <- do.call(rbind, lapply(runs, `[[`, "world"))
dirs <- data.frame(res = sapply(runs, function(r) r$world$res[1]), label = sapply(runs, function(r) r$world$label[1]),
                   dir = sapply(runs, `[[`, "dir"))

# ---- against the reference of the same closure and resolution ---------------------------------------------------------
ref <- RG[RG$label == "no-politics reference", c("res", "region", "year", "price", "co2")]; names(ref)[4:5] <- c("priceRef", "co2Ref")
RG <- merge(RG, ref, by = c("res", "region", "year")); RG$ratio <- RG$price / RG$priceRef; RG$dco2 <- RG$co2 - RG$co2Ref
cr <- CU[CU$label == "no-politics reference", c("res", "region", "cum2100")]; names(cr)[3] <- "cumRef"
CU <- merge(CU, cr, by = c("res", "region")); CU$dcum <- CU$cum2100 - CU$cumRef
wr <- WO[WO$label == "no-politics reference", c("res", "year", "co2", "priceW", "cum", "anchor")]
names(wr)[3:6] <- c("co2Ref", "priceWRef", "cumRef", "anchorRef")
WO <- merge(WO, wr, by = c("res", "year")); WO$dco2 <- WO$co2 - WO$co2Ref
WO$priceRatio <- WO$priceW / WO$priceWRef; WO$anchorRatio <- WO$anchor / WO$anchorRef

# ---- the summary table, one row per run ---------------------------------------------------------------------------
costs <- jsonlite::fromJSON(file.path(OUT, "coupled-costs.json"), simplifyVector = FALSE)
cget <- function(res, lab, k) {
  if (lab == "no-politics reference") return(NA_real_)
  v <- costs[[res]][[paste0(costKey, V$costSuffix[V$label == lab])]][[k]]; if (is.null(v)) NA_real_ else as.numeric(v)
}
S <- do.call(rbind, lapply(split(WO, ~ res + label, drop = TRUE), function(x) {
  r <- x$res[1]; l <- x$label[1]; y <- function(yr, k) x[[k]][x$year == yr]
  cu <- CU[CU$res == r & CU$label == l, ]
  data.frame(res = r, label = l, family = x$family[1], cum2100 = y(2100, "cum"), dcum2100 = y(2100, "cum") - y(2100, "cumRef"),
             dcumPct = 100 * (y(2100, "cum") - y(2100, "cumRef")) / y(2100, "cumRef"),
             e2050 = y(2050, "co2"), e2050Pct = 100 * (y(2050, "co2") / y(2050, "co2Ref") - 1), e2100 = y(2100, "co2"),
             cumMax = max(x$cum[x$year <= 2100]), peakCumYear = x$year[which.max(x$cum)],
             priceW2050 = y(2050, "priceW"), priceRatio2050 = y(2050, "priceRatio"), priceRatio2100 = y(2100, "priceRatio"),
             anchorRatio2050 = y(2050, "anchorRatio"), anchorRatio2100 = y(2100, "anchorRatio"),
             relocated = sum(abs(cu$dcum)) / 2, regionsMore = sum(cu$dcum > 0.5), regionsLess = sum(cu$dcum < -0.5),
             sumRegional = sum(cu$dcum),
             gdpPct = cget(r, l, "gdpChangePct"), consPct = cget(r, l, "consumptionChangePct"))
}))
S$label <- factor(S$label, levels = c("no-politics reference", V$label)); S <- S[order(S$res, S$label), ]
S$label <- as.character(S$label)
chk <- S[, c("res", "label", "dcum2100", "sumRegional")]

# regional summaries, EU21: the range over the set (the reference excluded)
RS <- CU[CU$res == "EU21" & CU$label != "no-politics reference", ]
regRange <- do.call(rbind, lapply(split(RS, RS$region), function(x) data.frame(region = x$region[1],
  central = x$dcum[x$label == "central (θ 0.50)"], min = min(x$dcum), max = max(x$dcum),
  minLabel = x$label[which.min(x$dcum)], maxLabel = x$label[which.max(x$dcum)], median = stats::median(x$dcum))))
regRange <- regRange[order(-regRange$central), ]
P50 <- RG[RG$res == "EU21" & RG$label != "no-politics reference" & RG$year %in% c(2050, 2100), ]
priceRange <- do.call(rbind, lapply(split(P50, ~ region + year, drop = TRUE), function(x) data.frame(region = x$region[1],
  year = x$year[1], central = x$ratio[x$label == "central (θ 0.50)"], min = min(x$ratio), max = max(x$ratio),
  minLabel = x$label[which.min(x$ratio)], maxLabel = x$label[which.max(x$ratio)])))

saveRDS(list(group = g, closure = closureLabel, made = format(Sys.time(), "%Y-%m-%d %H:%M"), variants = V, dirs = dirs,
             summary = S, world = WO, regions = RG, cumulative = CU, regionalRange = regRange, priceRange = priceRange,
             check = chk), file.path(OUT, paste0("scenario-set-", CL, ".rds")))

# ---- figures ------------------------------------------------------------------------------------------------------
fp <- function(n) file.path(OUT, paste0("fig-set-", CL, "-", n, ".png"))
cap <- paste0("Model version ", g, "; REMIND SSP2, 1000 Gt budget, ", closureLabel, ". Each run against the no-politics ",
              "reference (θ = 0) of the same closure and resolution.
Prices: the floor every market pays (pm_taxCO2eq); ",
              "the markup of the less constrained sector is not included.")
thm <- theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.grid.minor = element_blank(),
                                             plot.caption = element_text(hjust = 0, size = 8))
famCol <- c(central = "#1F2A33", severity = "#0F4C5C", persistence = "#D9541E", "strength and rents" = "#1F8A7E",
            institutions = "#7A5BA6")
resCol <- c(EU21 = "#1B6CA8", H12 = "#B07D2B")

# W1 the headline quantity per run, grouped by family, both resolutions
w1 <- S[S$label != "no-politics reference", ]
w1$label <- factor(w1$label, levels = rev(V$label))
w1$family <- factor(ifelse(w1$family == "central", "severity", w1$family), levels = FAM)
ylab1 <- if (CL == "price") "cumulative CO2 2020-2100 above the no-politics reference, Gt" else
  "CO2 moved between regions 2020-2100, Gt (half the sum of the regional changes)"
w1$val <- if (CL == "price") w1$dcum2100 else w1$relocated
cen <- w1[w1$label == "central (θ 0.50)", c("res", "val")]
f1 <- ggplot(w1, aes(val, label, colour = res)) + geom_vline(xintercept = 0, colour = "grey70") +
  geom_vline(data = cen, aes(xintercept = val, colour = res), linetype = "22", linewidth = 0.4, show.legend = FALSE) +
  geom_point(size = 2.2, position = position_dodge(width = 0.5)) +
  geom_text(aes(label = sprintf("%.1f", val)), size = 2.5, hjust = -0.35, position = position_dodge(width = 0.5), show.legend = FALSE) +
  facet_grid(family ~ ., scales = "free_y", space = "free_y") + scale_colour_manual(values = resCol, name = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.12))) +
  labs(x = ylab1, y = NULL, caption = paste0(cap, "\nDashed: the central run.")) + thm +
  theme(strip.text.y = element_text(angle = 0, hjust = 0))
ggsave(fp("headline"), f1, width = 9, height = 6, dpi = 200)

# W2, W3 world paths by family: every run of the family as a line, the family's range shaded, the central run in black
fam <- function(df) {
  out <- do.call(rbind, lapply(FAM, function(fm) {
    x <- df[df$family %in% c(fm, "central") | (fm == "severity" & df$family == "central"), ]
    x <- x[x$family == fm | x$label == "central (θ 0.50)", ]; x$panel <- fm; x
  }))
  out$panel <- factor(out$panel, levels = FAM); out
}
W <- WO[WO$res == "EU21" & WO$label != "no-politics reference" & WO$year >= 2020, ]
WF <- fam(W)
bandOf <- function(d, k) do.call(rbind, lapply(split(d, ~ panel + year, drop = TRUE), function(x)
  data.frame(panel = x$panel[1], year = x$year[1], lo = min(x[[k]]), hi = max(x[[k]]))))
pathFig <- function(k, ylab, ttl, file, hline = NULL, note = "") {
  b <- bandOf(WF, k); vr <- WF[WF$label != "central (θ 0.50)", ]; ce <- WF[WF$label == "central (θ 0.50)", ]
  p <- ggplot() + { if (!is.null(hline)) geom_hline(yintercept = hline, colour = "grey60", linetype = "22") } +
    geom_ribbon(data = b, aes(year, ymin = lo, ymax = hi), fill = "#0F4C5C", alpha = 0.13) +
    geom_line(data = vr, aes(year, .data[[k]], group = label, colour = label), linewidth = 0.6) +
    geom_line(data = ce, aes(year, .data[[k]]), colour = "black", linewidth = 1) +
    ggrepel::geom_text_repel(data = vr[vr$year == 2100, ], aes(2100, .data[[k]], label = label, colour = label), size = 2.4,
                             hjust = 0, nudge_x = 3, direction = "y", segment.size = 0.2, min.segment.length = 0, show.legend = FALSE) +
    facet_wrap(~panel, nrow = 1) + scale_x_continuous(limits = c(2020, 2135), breaks = c(2030, 2060, 2090)) +
    guides(colour = "none") +
    labs(x = NULL, y = ylab, title = ttl, caption = paste0(cap, " EU21.\nBlack: the central run (θ 0.50, fading limit); ",
                                                           "coloured: the family's other runs; shaded: the family's range.", note)) + thm
  ggsave(fp(file), p, width = 11, height = 4.4, dpi = 200)
}
pathFig("dco2", "global CO2 emissions above the\nno-politics reference, Gt per year",
        "Global CO2 emissions above the no-politics reference, by family of runs", "world-emissions", hline = 0)
pathFig("priceRatio", "carbon price relative to the reference\n(emissions-weighted mean over regions)",
        "The carbon price relative to the no-politics reference, by family of runs", "world-price", hline = 1,
        note = paste0("\nThe mean is weighted by each region's positive CO2 emissions: as global emissions approach zero late ",
                      "in the century, it is set by the few regions still emitting."))
if (CL == "budget")
  pathFig("anchorRatio", "anchor (cost-optimal price path)\nrelative to the reference",
          "How far the anchor rises to hold the budget, by family of runs", "world-anchor", hline = 1)

# R1 regional cumulative CO2 above the reference: the range over the set per region (box), each run a point, central marked
R1 <- RS; R1$region <- factor(R1$region, levels = regRange$region)
R1$family <- factor(R1$family, levels = c("central", FAM))
f4 <- ggplot(R1, aes(dcum, region)) + geom_vline(xintercept = 0, colour = "grey60") +
  geom_boxplot(outlier.shape = NA, fill = "grey92", colour = "grey55", width = 0.6, linewidth = 0.35) +
  geom_point(aes(colour = family), position = position_jitter(height = 0.15, width = 0, seed = 2), size = 1.3, alpha = 0.85) +
  geom_point(data = R1[R1$label == "central (θ 0.50)", ], shape = 23, size = 2.6, fill = "white", colour = "black", stroke = 0.9) +
  scale_colour_manual(values = famCol, name = NULL) +
  labs(x = "cumulative CO2 2020-2100 above the no-politics reference, Gt", y = NULL,
       title = "Each region's cumulative CO2 above the reference, over the runs of the set",
       caption = paste0(cap, " EU21.\nBox: interquartile range and median over the 15 runs; points: the runs, by family; ",
                        "diamond: the central run. Regions ordered by the central run.")) + thm
ggsave(fp("regional-co2-box"), f4, width = 9, height = 6.4, dpi = 200)

# R2 regional price relative to the reference, 2050 and 2100, over the set
R2 <- RG[RG$res == "EU21" & RG$label != "no-politics reference" & RG$year %in% c(2050, 2100), ]
ordP <- with(R2[R2$label == "central (θ 0.50)" & R2$year == 2050, ], region[order(ratio)])
R2$region <- factor(R2$region, levels = ordP); R2$family <- factor(R2$family, levels = c("central", FAM))
f5 <- ggplot(R2, aes(ratio, region)) + geom_vline(xintercept = 1, colour = "grey60", linetype = "22") +
  geom_boxplot(outlier.shape = NA, fill = "grey92", colour = "grey55", width = 0.6, linewidth = 0.35) +
  geom_point(aes(colour = family), position = position_jitter(height = 0.15, width = 0, seed = 2), size = 1.2, alpha = 0.85) +
  geom_point(data = R2[R2$label == "central (θ 0.50)", ], shape = 23, size = 2.4, fill = "white", colour = "black", stroke = 0.9) +
  facet_wrap(~year) + scale_colour_manual(values = famCol, name = NULL) +
  labs(x = "carbon price relative to the no-politics reference", y = NULL,
       title = "Each region's carbon price relative to the reference, over the runs of the set",
       caption = paste0(cap, " EU21.\nBox: interquartile range and median over the 15 runs; diamond: the central run. ",
                        "Regions ordered by the central run's 2050 ratio.")) + thm
ggsave(fp("regional-price-box"), f5, width = 10, height = 6.4, dpi = 200)

# R3 each region's emissions above the reference over time: the set's range shaded, the central run as a line
R3 <- RG[RG$res == "EU21" & RG$label != "no-politics reference" & RG$year >= 2020, ]
b3 <- do.call(rbind, lapply(split(R3, ~ region + year, drop = TRUE), function(x) {
  q <- stats::quantile(x$dco2, c(0, 0.25, 0.75, 1), names = FALSE)
  data.frame(region = x$region[1], year = x$year[1], lo = q[1], q1 = q[2], q3 = q[3], hi = q[4],
             central = x$dco2[x$label == "central (θ 0.50)"])
}))
b3$region <- factor(b3$region, levels = regRange$region)
f6 <- ggplot(b3, aes(year)) + geom_hline(yintercept = 0, colour = "grey60") +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#0F4C5C", alpha = 0.15) +
  geom_ribbon(aes(ymin = q1, ymax = q3), fill = "#0F4C5C", alpha = 0.3) +
  geom_line(aes(y = central), colour = "black", linewidth = 0.7) + facet_wrap(~region, ncol = 7) +
  scale_x_continuous(breaks = c(2030, 2060, 2090)) +
  labs(x = NULL, y = "CO2 emissions above the no-politics reference, Gt per year",
       title = "Each region's CO2 emissions above the reference: the central run and the range over the set",
       caption = paste0(cap, " EU21.\nLine: the central run; dark band: interquartile range over the 15 runs; light band: ",
                        "lowest to highest run. Regions ordered by the central run's cumulative CO2.")) + thm
ggsave(fp("regional-emissions-range"), f6, width = 11, height = 6.4, dpi = 200)

# R4 heat map, region x run: cumulative CO2 above the reference
H <- RS; H$region <- factor(H$region, levels = rev(regRange$region)); H$label <- factor(H$label, levels = V$label)
lim <- max(abs(H$dcum))
f7 <- ggplot(H, aes(label, region, fill = dcum)) + geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = sub("^-0.0$", "0.0", sprintf("%.1f", dcum), fixed = FALSE)), size = 2) +
  scale_fill_gradient2(low = "#2166AC", mid = "grey97", high = "#B2182B", midpoint = 0, limits = c(-lim, lim),
                       name = "Gt CO2 above the reference") +
  labs(x = NULL, y = NULL, title = "Cumulative CO2 2020-2100 above the reference, by region and run", caption = paste0(cap, " EU21.")) +
  thm + theme(panel.grid = element_blank(), axis.text.x = element_text(angle = 40, hjust = 1), legend.key.width = unit(1.4, "cm"))
ggsave(fp("regional-heat"), f7, width = 10.5, height = 6.6, dpi = 200)

options(width = 220)
cat("\n== summary (", closureLabel, ") ==\n"); print(S[, setdiff(names(S), "family")], row.names = FALSE, digits = 4)
cat("\n== regional range over the set (EU21, cumulative CO2 above the reference) ==\n"); print(regRange, row.names = FALSE, digits = 3)
