# The proposed institution rule against PoliClim's SSP2 projections, and what it does to the model's own series.
#   Rscript analysis/checks/institutionRuleCharts.R [group] [PoliClim folder]   (repo root; default v7)
#   -> output/checks/institution-rule/fig1..fig6 (png) and institution-rule.rds
#
# The rule ("gap closure"): every country closes a fixed share of its distance to the top of the scale each year,
#   x(t) = 1 - (1 - x_s) exp(-lambda (t - t_s)),
# lambda from PoliClim's SSP2 country paths (analysis/checks/policlimRuleFit.R): rule of law 0.94% a year, accountability
# 0.53% a year. Compared with the current SSP2 rule (logistic convergence to the 2025 75th percentile, half by 2080,
# complete by 2150, no decline; DATA.md §5.4) and with PoliClim itself.
#   Part 1 (fig1-fig3): on PoliClim's own indicators and 2025 values: like with like.
#   Part 2 (fig4-fig6): on the model's series (V-Dem rule of law, vertical accountability; the freedom-of-expression
#     weight held at the higher of its 2025 value and its 2016-2025 mean), on the panel's normalised scale (0 = worst,
#     1 = best observed), with the panel's five-year average to 2023 and the scenario harmonised to it, the offset
#     fading linearly to 2040 (DATA.md §5.5). PoliClim is shown as its SSP2 change added to the model's own 2025 value.
suppressMessages({ library(ggplot2); library(mrpfm) })
a <- commandArgs(trailingOnly = TRUE)
g <- if (length(a) > 0) a[1] else "v7"
pcDir <- if (length(a) > 1) a[2] else "../PoliClim projections"
OUT <- file.path("output/checks", "institution-rule"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
LAMBDA <- c(rol = 0.0094, acc = 0.0053)
T0 <- 2025; YP <- 2025:2100
COL <- c(PoliClim = "#52514e", `gap closure` = "#eb6834", `current rule` = "#2a78d6")
INK <- "#0b0b0b"; INK2 <- "#52514e"; GRID <- "#e6e5e1"
th <- theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = GRID),
  plot.title = element_text(face = "bold", colour = INK), plot.subtitle = element_text(colour = INK2),
  plot.background = element_rect(fill = "#fcfcfb", colour = NA), legend.position = "top", legend.title = element_blank(),
  strip.text = element_text(face = "bold", colour = INK))
save <- function(p, f, w = 9, h = 5) ggsave(file.path(OUT, f), p, width = w, height = h, dpi = 150, bg = "#fcfcfb")

gap <- function(x0, t, lam, t0 = T0) 1 - (1 - x0) * exp(-lam * (t - t0))
current <- function(x0, t, q75, t0 = T0) {   # mrpfm::toolProjectScenario, SSP2 = rule (a)
  k <- log(99) / (2150 - 2080); L <- function(y) 1 / (1 + exp(-k * (y - 2080)))
  w <- pmin((L(t) - L(t0)) / (L(2150) - L(t0)), 1); x0 <- rep_len(x0, length(t))
  ifelse(x0 >= q75, x0, x0 + w * (q75 - x0))
}

# ---- Part 1: PoliClim's indicators ----------------------------------------------------------------------------------
pc <- read.csv2(file.path(pcDir, "pol_institutions_forecast.csv"), stringsAsFactors = FALSE, dec = ".")
IND <- c(rol = "f_Rule_of_law", acc = "f_acc"); LAB <- c(rol = "rule of law (PoliClim: v2xcl_rol)", acc = "accountability (PoliClim: overall)")
for (k in IND) pc[[k]] <- suppressWarnings(as.numeric(pc[[k]]))
s2 <- pc[pc$scenario == "SSP2" & pc$year >= 2000, ]
p1 <- do.call(rbind, lapply(names(IND), function(k) {
  x <- s2[, c("countrycode", "year", IND[[k]])]; names(x) <- c("c", "year", "v"); x <- x[is.finite(x$v), ]
  x0 <- x[x$year == T0, ]; q75 <- stats::quantile(x0$v, 0.75)
  proj <- do.call(rbind, lapply(seq_len(nrow(x0)), function(i) data.frame(c = x0$c[i], year = YP,
    `gap closure` = gap(x0$v[i], YP, LAMBDA[[k]]), `current rule` = current(x0$v[i], YP, q75), check.names = FALSE)))
  m <- merge(proj, x[x$year >= T0, c("c", "year", "v")], by = c("c", "year")); names(m)[names(m) == "v"] <- "PoliClim"
  hist <- x[x$year < T0, ]; hist <- data.frame(c = hist$c, year = hist$year, PoliClim = hist$v, `gap closure` = hist$v,
                                              `current rule` = hist$v, check.names = FALSE)
  cbind(indicator = k, rbind(hist, m[, names(hist)]))
}))
long1 <- do.call(rbind, lapply(names(COL), function(s) data.frame(p1[, c("indicator", "c", "year")], source = s, v = p1[[s]])))
long1$source <- factor(long1$source, levels = names(COL)); long1$indicator <- factor(LAB[long1$indicator], levels = LAB)

# fig1: the cross-country distribution over time
q <- stats::aggregate(v ~ indicator + source + year, long1, function(z) c(m = mean(z), lo = unname(stats::quantile(z, .1)),
                                                                      hi = unname(stats::quantile(z, .9))))
q <- data.frame(q[, 1:3], q$v)
f1 <- ggplot(q, aes(year, m, colour = source, fill = source)) +
  geom_ribbon(data = q[q$year >= T0, ], aes(ymin = lo, ymax = hi), alpha = 0.10, colour = NA) +
  geom_line(linewidth = 0.8) + geom_line(aes(y = lo), linewidth = 0.3, linetype = "22") + geom_line(aes(y = hi), linewidth = 0.3, linetype = "22") +
  geom_vline(xintercept = T0, colour = INK2, linewidth = 0.3) +
  facet_wrap(~indicator) + scale_colour_manual(values = COL) + scale_fill_manual(values = COL) +
  labs(title = "Gap closure follows PoliClim's SSP2 mean; the current rule is slow early and fast late",
       subtitle = sprintf("Cross-country mean (solid) and 10th / 90th percentile (dashed), %d countries; history to 2025, SSP2 after.",
                          length(unique(p1$c))), x = NULL, y = "index (0-1)") + th
save(f1, "fig1-distribution.png")

# fig2: each country's change 2025-2100, rule against PoliClim
e <- p1[p1$year %in% c(T0, 2100), ]
w0 <- e[e$year == T0, ]; w1 <- e[e$year == 2100, ]; w <- merge(w0, w1, by = c("indicator", "c"), suffixes = c(".0", ".1"))
sc <- rbind(data.frame(indicator = w$indicator, c = w$c, source = "gap closure",
                       policlim = w$PoliClim.1 - w$PoliClim.0, rule = w$`gap closure.1` - w$`gap closure.0`),
            data.frame(indicator = w$indicator, c = w$c, source = "current rule",
                       policlim = w$PoliClim.1 - w$PoliClim.0, rule = w$`current rule.1` - w$`current rule.0`))
r2 <- stats::aggregate(cbind(policlim, rule) ~ indicator + source, sc, function(z) z)
r2lab <- do.call(rbind, lapply(split(sc, list(sc$indicator, sc$source)), function(d)
  data.frame(indicator = d$indicator[1], source = d$source[1],
             r2 = 1 - sum((d$rule - d$policlim)^2) / sum((d$policlim - mean(d$policlim))^2))))
sc$indicator <- factor(LAB[sc$indicator], levels = LAB); r2lab$indicator <- factor(LAB[r2lab$indicator], levels = LAB)
r2lab$txt <- sprintf("%s: R² %.2f", r2lab$source, r2lab$r2); r2lab$y <- ifelse(r2lab$source == "gap closure", 0.62, 0.55)
f2 <- ggplot(sc, aes(policlim, rule, colour = source)) + geom_abline(colour = INK2, linewidth = 0.3) +
  geom_hline(yintercept = 0, colour = GRID) + geom_vline(xintercept = 0, colour = GRID) +
  geom_point(size = 1.3, alpha = 0.7) + geom_text(data = r2lab, aes(x = -0.12, y = y, label = txt), hjust = 0, size = 3, show.legend = FALSE) +
  facet_wrap(~indicator) + scale_colour_manual(values = COL[-1]) + coord_equal() +
  labs(title = "Country by country: change 2025-2100, rule against PoliClim SSP2",
       subtitle = "On the diagonal the rule reproduces PoliClim. Points below zero on the x axis: PoliClim projects a decline.",
       x = "PoliClim SSP2: change 2025-2100", y = "rule: change 2025-2100") + th
save(f2, "fig2-country-change.png", w = 9, h = 5)

# fig3: selected countries
CTY <- c(CHN = "China", RUS = "Russia", SAU = "Saudi Arabia", IND = "India", IDN = "Indonesia", BRA = "Brazil",
         ZAF = "South Africa", USA = "United States", DEU = "Germany")
for (k in names(IND)) {
  d <- long1[long1$c %in% names(CTY) & long1$indicator == LAB[[k]], ]; d$country <- factor(CTY[d$c], levels = CTY)
  f3 <- ggplot(d, aes(year, v, colour = source)) + geom_line(linewidth = 0.7) + geom_vline(xintercept = T0, colour = INK2, linewidth = 0.3) +
    facet_wrap(~country, ncol = 3) + scale_colour_manual(values = COL) + scale_y_continuous(limits = c(0, 1)) +
    labs(title = paste0("Selected countries: ", LAB[[k]]), subtitle = "PoliClim SSP2 against the two rules, from each country's 2025 value.",
         x = NULL, y = "index (0-1)") + th
  save(f3, paste0("fig3-countries-", k, ".png"), w = 9, h = 7)
}

# ---- Part 2: the model's own series -----------------------------------------------------------------------------------
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE)
q2 <- function(expr) suppressWarnings(suppressMessages(expr))
vd <- q2(calcOutput("VDem", aggregate = FALSE)); dem <- q2(calcOutput("VDem", subtype = "democracy", aggregate = FALSE))
SER <- c(rol = "Rule of Law (VDem)", acc = "Vertical Accountability (VDem)", w = "Freedom of Expression (VDem)")
LAB2 <- c(rol = "rule of law (V-Dem v2x_rule)", acc = "vertical accountability (V-Dem)", w = "freedom of expression (the weight)")
raw <- function(s) { x <- if (s == "w") dem[, , SER[[s]]] else vd[, , SER[[s]]]; a <- as.array(x)[, , 1]
  colnames(a) <- sub("^y", "", colnames(a)); a }
yrs <- as.integer(colnames(raw("rol")))
STITCH <- 2023; FADE <- 2040; HY <- 2000:2023
part2 <- do.call(rbind, lapply(names(SER), function(s) {
  A <- raw(s); mn <- min(A, na.rm = TRUE); mx <- max(A, na.rm = TRUE); N <- (A - mn) / (mx - mn)   # the panel's [0, 1] scale
  N <- N[, as.character(1995:2025)]; N <- N[rowSums(is.finite(N[, as.character(2016:2025)])) == 10, , drop = FALSE]
  ma <- t(apply(N, 1, function(r) vapply(seq_along(r), function(i) mean(r[max(1, i - 2):min(length(r), i + 2)], na.rm = TRUE), 0)))
  dimnames(ma) <- dimnames(N); x25 <- N[, "2025"]; x23 <- ma[, "2023"]
  q75 <- stats::quantile(x25, 0.75, na.rm = TRUE)
  harm <- function(path) {   # path over YP from the raw 2025 value -> shifted to the 2023 panel value, fading to 2040
    at23 <- x25 + (path[, 1] - x25)   # the rule's value at its start (2025): the 2023 offset uses the raw 2025 value
    off <- x23 - at23; wt <- pmax(0, pmin(1, (FADE - YP) / (FADE - STITCH))); sweep(path, 2, 0, "+") + outer(off, wt)
  }
  rule <- if (s == "w") { lvl <- pmax(x25, rowMeans(N[, as.character(2016:2025)], na.rm = TRUE)); outer(lvl, rep(1, length(YP))) }
          else outer(x25, YP, function(x, t) gap(x, t, LAMBDA[[s]]))
  cur <- if (s == "w") outer(x25, rep(1, length(YP))) else outer(x25, YP, function(x, t) current(x, t, q75))
  out <- rbind(
    data.frame(series = s, c = rownames(ma), year = rep(HY, each = nrow(ma)), source = "history (5-year mean)", v = as.vector(ma[, as.character(HY)])),
    data.frame(series = s, c = rownames(ma), year = rep(YP, each = nrow(ma)),
               source = if (s == "w") "held at max(2025, 2016-2025 mean)" else "gap closure", v = as.vector(harm(rule))),
    data.frame(series = s, c = rownames(ma), year = rep(YP, each = nrow(ma)),
               source = if (s == "w") "held at 2025 (current)" else "current rule", v = as.vector(harm(cur))))
  if (s != "w") {   # PoliClim's SSP2 change added to the model's own 2025 value (nearest indicator)
    pk <- s2[, c("countrycode", "year", IND[[s]])]; names(pk) <- c("c", "year", "v")
    p0 <- pk[pk$year == T0, c("c", "v")]; names(p0)[2] <- "v0"; pk <- merge(pk[pk$year >= T0, ], p0)
    pk$v <- x25[pk$c] + (pk$v - pk$v0); pk <- pk[is.finite(pk$v), ]
    pk$v <- pk$v + (x23[pk$c] - x25[pk$c]) * pmax(0, pmin(1, (FADE - pk$year) / (FADE - STITCH)))
    out <- rbind(out, data.frame(series = s, c = pk$c, year = pk$year, source = "PoliClim change", v = pk$v))
  }
  out
}))
COL2 <- c(`history (5-year mean)` = INK, `PoliClim change` = "#52514e", `gap closure` = "#eb6834", `current rule` = "#2a78d6",
          `held at max(2025, 2016-2025 mean)` = "#eb6834", `held at 2025 (current)` = "#2a78d6")
part2$label <- factor(LAB2[part2$series], levels = LAB2)

# fig4: distributions of the model's series
q <- stats::aggregate(v ~ label + source + year, part2, function(z) c(m = mean(z), lo = unname(stats::quantile(z, .1)), hi = unname(stats::quantile(z, .9))))
q <- data.frame(q[, 1:3], q$v)
f4 <- ggplot(q, aes(year, m, colour = source)) + geom_line(linewidth = 0.8) +
  geom_line(aes(y = lo), linewidth = 0.3, linetype = "22") + geom_line(aes(y = hi), linewidth = 0.3, linetype = "22") +
  geom_vline(xintercept = STITCH, colour = INK2, linewidth = 0.3) + facet_wrap(~label) +
  scale_colour_manual(values = COL2) + guides(colour = guide_legend(nrow = 2)) +
  labs(title = "The model's institution series under the proposed rules",
       subtitle = "Panel scale (0 = worst, 1 = best observed). Mean (solid), 10th / 90th percentile (dashed). Harmonised to the 2023 panel value, offset fading to 2040.",
       x = NULL, y = "normalised index") + th
save(f4, "fig4-model-series.png", w = 10, h = 5)

# fig5: the seam, 2015-2045, selected countries
d <- part2[part2$c %in% names(CTY) & part2$year >= 2015 & part2$year <= 2045, ]; d$country <- factor(CTY[d$c], levels = CTY)
for (s in names(SER)) {
  f5 <- ggplot(d[d$series == s, ], aes(year, v, colour = source)) + geom_line(linewidth = 0.7) +
    geom_vline(xintercept = STITCH, colour = INK2, linewidth = 0.3) + geom_vline(xintercept = FADE, colour = INK2, linewidth = 0.3, linetype = "22") +
    facet_wrap(~country, ncol = 3, scales = "free_y") + scale_colour_manual(values = COL2) + guides(colour = guide_legend(nrow = 2)) +
    labs(title = paste0("From history to projection: ", LAB2[[s]]),
         subtitle = "2015-2045. Solid line: the panel's last year (2023); dashed: the harmonisation offset reaches zero (2040).",
         x = NULL, y = "normalised index") + th
  save(f5, paste0("fig5-seam-", s, ".png"), w = 9, h = 7)
}

# the seam in numbers: the largest year-on-year step 2023-2030 against history's 95th percentile of annual changes
seam <- do.call(rbind, lapply(names(SER), function(s) {
  h <- part2[part2$series == s & part2$source == "history (5-year mean)", ]
  hc <- unlist(lapply(split(h, h$c), function(z) abs(diff(z$v[order(z$year)]))))
  do.call(rbind, lapply(setdiff(unique(part2$source[part2$series == s]), "history (5-year mean)"), function(src) {
    p <- part2[part2$series == s & part2$source == src & part2$year <= 2030, ]
    h23 <- h[h$year == 2023, c("c", "v")]; names(h23)[2] <- "v23"
    st <- unlist(lapply(split(p, p$c), function(z) { z <- z[order(z$year), ]; v0 <- h23$v23[h23$c == z$c[1]]
      if (!length(v0)) return(NULL); abs(diff(c(v0, z$v[z$year >= 2024]))) }))
    data.frame(series = s, source = src, histP95 = unname(stats::quantile(hc, .95, na.rm = TRUE)),
               stepMedian = stats::median(st, na.rm = TRUE), stepP95 = unname(stats::quantile(st, .95, na.rm = TRUE)),
               stepMax = max(st, na.rm = TRUE))
  }))
}))
saveRDS(list(group = g, lambda = LAMBDA, part1 = p1, part2 = part2, r2 = r2lab, seam = seam,
             made = format(Sys.time(), "%Y-%m-%d %H:%M")), file.path(OUT, "institution-rule.rds"))
options(width = 160); print(r2lab[, c("indicator", "source", "r2")], row.names = FALSE, digits = 3)
cat("\nseam: year-on-year step 2023-2030 (panel scale) against history's 95th percentile of annual changes\n")
print(seam, row.names = FALSE, digits = 3); cat("figures in", OUT, "\n")
