# The gap-closure institution rule (design note 0008): against PoliClim's SSP2 projections, on the model's own scenario
# panels, in the strength k(t), and beside the literature series the model uses or could use (Andrijevic et al. 2020).
# Every figure reads output/pfm/<group>/institution-rule.rds (analysis/checks/institutionRule.R); nothing is fitted here.

.instCol <- function() c(`PoliClim SSP2` = "#52514e", `gap closure` = pfmAccent(), current = "#C2571A", held = "grey60",
                         history = "grey15")
.instSspCol <- function() c(SSP1 = "#2a78d6", SSP2 = "#eb6834", SSP3 = "#1baf7a", SSP3c = "#1baf7a", SSP4 = "#eda100",
                            SSP4c = "#eda100", SSP5 = "#e87ba4")
.instLab <- function() c(rol = "Rule of law", acc = "Accountability",
                         `Rule of Law (VDem)` = "Rule of law (V-Dem)", `Vertical Accountability (VDem)` = "Vertical accountability (V-Dem)",
                         `Freedom of Expression (VDem)` = "Freedom of expression (the weight)",
                         `Government Effectiveness (WGI)` = "Government effectiveness")
.instModelSeries <- function() c("Rule of Law (VDem)", "Vertical Accountability (VDem)", "Freedom of Expression (VDem)",
                                  "Government Effectiveness (WGI)")
.instCountries <- function() c(CHN = "China", RUS = "Russia", SAU = "Saudi Arabia", IND = "India", IDN = "Indonesia",
                               BRA = "Brazil", ZAF = "South Africa", USA = "United States", DEU = "Germany")
.instBand <- function(d, by) {
  q <- stats::aggregate(stats::as.formula(paste("v ~", paste(by, collapse = " + "))), d,
                        function(z) c(m = mean(z), lo = unname(stats::quantile(z, .1)), hi = unname(stats::quantile(z, .9))))
  data.frame(q[, by, drop = FALSE], q$v)
}

# 1. PoliClim against the two rules: the cross-country distribution over time
figInstPoliclimPaths <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); d <- x$part1
  d$source[d$source == "history"] <- "PoliClim SSP2"
  hist <- d[d$source == "PoliClim SSP2" & d$year <= 2025, ]
  d <- rbind(d, transform(hist, source = "gap closure"), transform(hist, source = "current"))
  q <- .instBand(d, c("indicator", "source", "year")); q$indicator <- factor(.instLab()[q$indicator], levels = .instLab()[c("rol", "acc")])
  q$source <- factor(q$source, levels = c("PoliClim SSP2", "gap closure", "current"))
  r <- x$rates
  p <- ggplot2::ggplot(q, ggplot2::aes(year, m, colour = source)) +
    ggplot2::geom_vline(xintercept = 2025, colour = "grey70", linewidth = 0.3) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_line(ggplot2::aes(y = lo), linewidth = 0.3, linetype = "22") + ggplot2::geom_line(ggplot2::aes(y = hi), linewidth = 0.3, linetype = "22") +
    ggplot2::facet_wrap(~indicator) + ggplot2::scale_colour_manual(values = .instCol(), name = NULL) +
    ggplot2::labs(title = "A consistency check: the gap-closure rule against PoliClim's SSP2",
                  subtitle = sprintf(paste("Cross-country mean (solid) and 10th / 90th percentile (dashed), %d countries, PoliClim's own indicators.",
                                           "\nGap closure: %.1f%% of the distance to the best observed value closed each year (declared, not fitted to PoliClim)."),
                                     length(unique(x$part1$c)), 100 * r$rate[1]),
                  x = NULL, y = "index (0-1)")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "institution-rule.rds (part 1)")
}

# 2. country by country: the change 2025-2100, rule against PoliClim
figInstPoliclimChange <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); d <- x$part1
  w <- function(s, y) { z <- d[d$source == s & d$year == y, ]; stats::setNames(z$v, paste(z$indicator, z$c)) }
  x0 <- w("PoliClim SSP2", 2025); dp <- w("PoliClim SSP2", 2100) - x0
  sc <- do.call(rbind, lapply(c("gap closure", "current"), function(s) {
    dr <- w(s, 2100)[names(dp)] - x0[names(dp)]
    data.frame(indicator = sub(" .*$", "", names(dp)), rule = s, policlim = dp, rule.change = dr)
  }))
  sc <- sc[is.finite(sc$policlim) & is.finite(sc$rule.change), ]
  f <- x$fit1; f$txt <- sprintf("%s: R² %.2f", f$rule, f$r2Change); f$y <- ifelse(f$rule == "gap closure", 0.62, 0.55)
  for (z in c("sc", "f")) { v <- get(z); v$indicator <- factor(.instLab()[v$indicator], levels = .instLab()[c("rol", "acc")]); assign(z, v) }
  p <- ggplot2::ggplot(sc, ggplot2::aes(policlim, rule.change, colour = rule)) +
    ggplot2::geom_abline(colour = "grey50", linewidth = 0.3) +
    ggplot2::geom_point(size = 1.2, alpha = 0.7) +
    ggplot2::geom_text(data = f, ggplot2::aes(x = -0.12, y = y, label = txt), hjust = 0, size = 2.8, show.legend = FALSE) +
    ggplot2::facet_wrap(~indicator) + ggplot2::scale_colour_manual(values = .instCol(), name = NULL) + ggplot2::coord_equal() +
    ggplot2::labs(title = "Country by country, gap closure reproduces most of PoliClim's SSP2 change",
                  subtitle = "Change 2025-2100 in each country. On the diagonal the rule matches PoliClim. Left of zero: PoliClim projects a decline.",
                  x = "PoliClim SSP2: change 2025-2100", y = "rule: change 2025-2100")
  attr(p, "pfmGrid") <- "both"
  pfmStamp(p, group, note = "institution-rule.rds (part 1)")
}

# 3. selected countries, one indicator
figInstPoliclimCountries <- function(group = "v7", indicator = "rol") {
  x <- pfmArtifact(group, "institution-rule.rds"); d <- x$part1[x$part1$indicator == indicator & x$part1$c %in% names(.instCountries()), ]
  d$source[d$source == "history"] <- "PoliClim SSP2"
  d$country <- factor(.instCountries()[d$c], levels = .instCountries())
  d$source <- factor(d$source, levels = c("PoliClim SSP2", "gap closure", "current"))
  p <- ggplot2::ggplot(d, ggplot2::aes(year, v, colour = source)) +
    ggplot2::geom_vline(xintercept = 2025, colour = "grey70", linewidth = 0.3) + ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::facet_wrap(~country, ncol = 3) + ggplot2::scale_colour_manual(values = .instCol(), name = NULL) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(title = paste0(.instLab()[[indicator]], ": selected countries"),
                  subtitle = "PoliClim SSP2 against the two rules, each from the country's 2025 value (PoliClim's indicator).",
                  x = NULL, y = "index (0-1)")
  attr(p, "pfmGrid") <- "y"; attr(p, "pfmHeightScale") <- 1.5
  pfmStamp(p, group, note = "institution-rule.rds (part 1)")
}
figInstPoliclimCountriesRol <- function(group = "v7") figInstPoliclimCountries(group, "rol")
figInstPoliclimCountriesAcc <- function(group = "v7") figInstPoliclimCountries(group, "acc")

# 4. the model's own series under each rule
figInstModelSeries <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); d <- x$part2[is.finite(x$part2$v) & x$part2$year >= 2000 & x$part2$year <= 2100, ]
  d$rule[d$year <= 2023] <- "history"
  d <- d[!duplicated(d[, c("rule", "series", "c", "year")]), ]
  q <- .instBand(d, c("series", "rule", "year")); q$series <- factor(.instLab()[q$series], levels = .instLab()[.instModelSeries()])
  q$rule <- factor(q$rule, levels = c("history", "gap closure", "current", "held"))
  p <- ggplot2::ggplot(q, ggplot2::aes(year, m, colour = rule)) +
    ggplot2::geom_vline(xintercept = 2023, colour = "grey70", linewidth = 0.3) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_line(ggplot2::aes(y = lo), linewidth = 0.3, linetype = "22") + ggplot2::geom_line(ggplot2::aes(y = hi), linewidth = 0.3, linetype = "22") +
    ggplot2::facet_wrap(~series, ncol = 4) + ggplot2::scale_colour_manual(values = .instCol(), name = NULL) +
    ggplot2::labs(title = "What the frontier reads: the model's institution series under each rule",
                  subtitle = paste("Scenario panel, 1000 Gt hold-the-price energy system (EU21), all countries; 0 = worst, 1 = best observed.",
                                   "\nGovernment effectiveness: Andrijevic SSP2 under every rule. Weight: held, or its 2016-2025 level (gap closure)."),
                  x = NULL, y = "normalised index")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "institution-rule.rds (part 2)")
}

# 5. the switch from history to projection, selected countries
figInstModelSeam <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds")
  keep <- c("Rule of Law (VDem)", "Vertical Accountability (VDem)")
  d <- x$part2[x$part2$c %in% names(.instCountries()) & x$part2$year >= 2025 & x$part2$year <= 2050 & x$part2$series %in% keep, ]
  # history: the panel the frontier was fitted on (annual, five-year mean, to 2023), not the scenario's early periods
  h <- x$history[x$history$c %in% names(.instCountries()) & x$history$series %in% keep, ]
  d <- rbind(d[, c("rule", "series", "c", "year", "v")], data.frame(rule = "history", h[, c("series", "c", "year", "v")]))
  d$country <- factor(.instCountries()[d$c], levels = .instCountries())
  d$series <- factor(.instLab()[d$series], levels = .instLab()[.instModelSeries()[1:2]])
  d$rule <- factor(d$rule, levels = c("history", "gap closure", "current", "held"))
  p <- ggplot2::ggplot(d, ggplot2::aes(year, v, colour = rule, linetype = series)) +
    ggplot2::geom_vline(xintercept = 2023, colour = "grey70", linewidth = 0.3) +
    ggplot2::geom_vline(xintercept = 2040, colour = "grey70", linewidth = 0.3, linetype = "22") +
    ggplot2::geom_line(linewidth = 0.6) + ggplot2::facet_wrap(~country, ncol = 3, scales = "free_y") +
    ggplot2::scale_colour_manual(values = .instCol(), name = NULL) + ggplot2::scale_linetype_manual(values = c("solid", "42"), name = NULL) +
    ggplot2::labs(title = "No step into the projection: the switch from history, 2010-2050",
                  subtitle = paste("Model scenario panel, REMIND periods. Solid line: the panel's last year (2023); dashed: the offset reaches zero (2040).",
                                   "\nUnder gap closure the offset fades along a half cosine: no kink at either end."),
                  x = NULL, y = "normalised index")
  attr(p, "pfmGrid") <- "y"; attr(p, "pfmHeightScale") <- 1.5
  pfmStamp(p, group, note = "institution-rule.rds (part 2)")
}

# 6. the strength k(t) on each rule's scenario panel
figInstStrength <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); s <- x$strength
  s$rule <- factor(s$rule, levels = c("gap closure", "current", "held"))
  s$sector <- factor(s$sector, levels = c("Bulk", "Diffuse"), labels = c("Power & industry", "Buildings & transport"))
  end <- s[s$year == 2100, ]; end$lab <- sprintf("%.2f", end$k)
  # labels spread apart within a sector (at least 0.035), in the order of the lines
  end <- do.call(rbind, lapply(split(end, end$sector), function(e) { e <- e[order(e$k), ]; y <- e$k
    for (i in seq_along(y)[-1]) y[i] <- max(y[i], y[i - 1] + 0.035); e$ky <- y; e }))
  p <- ggplot2::ggplot(s[s$year <= 2100, ], ggplot2::aes(year, k, colour = rule)) +
    ggplot2::geom_hline(yintercept = 1, colour = "grey70", linewidth = 0.3) + ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_text(data = end, ggplot2::aes(y = ky, label = lab), hjust = -0.2, size = 2.6, show.legend = FALSE) +
    ggplot2::facet_wrap(~sector) + ggplot2::scale_colour_manual(values = .instCol(), name = NULL) +
    ggplot2::scale_x_continuous(limits = c(2025, 2108), breaks = c(2025, 2050, 2075, 2100)) +
    ggplot2::labs(title = "The institution rule barely moves the strength of the constraint",
                  subtitle = "Strength k(t), theta = 0.50, 1000 Gt hold-the-price energy system (EU21), on each rule's scenario panel. Offline.",
                  x = NULL, y = "strength k(t)")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "institution-rule.rds (part 3)")
}

# 7. government effectiveness: Andrijevic et al. (2020) by SSP, with the WGI history
figGeSsp <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); d <- x$part4[x$part4$indicator == "ge", ]
  a <- d[d$source == "Andrijevic et al. 2020" & d$year >= 2000 & d$year <= 2100, ]
  h <- d[d$source == "WGI (observed)", ]; h$ssp <- "WGI (observed)"
  q <- rbind(.instBand(a, c("ssp", "year")), .instBand(h, c("ssp", "year")))
  col <- c(.instSspCol()[paste0("SSP", 1:5)], `WGI (observed)` = "grey15")
  p <- ggplot2::ggplot(q, ggplot2::aes(year, m, colour = ssp)) + ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_line(data = q[q$ssp %in% c("SSP2", "WGI (observed)"), ], ggplot2::aes(y = lo), linewidth = 0.3, linetype = "22") +
    ggplot2::geom_line(data = q[q$ssp %in% c("SSP2", "WGI (observed)"), ], ggplot2::aes(y = hi), linewidth = 0.3, linetype = "22") +
    ggplot2::scale_colour_manual(values = col, name = NULL) +
    ggplot2::labs(title = "Government effectiveness in the SSPs: Andrijevic et al. (2020)",
                  subtitle = paste("Cross-country mean by SSP (dashed: SSP2 and WGI 10th / 90th percentile), normalised as in the model.",
                                   "\nA panel regression on income, education and its gender gap; in SSP2 country effects converge by 2250."),
                  x = NULL, y = "normalised index")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "institution-rule.rds (part 4)")
}

# 8. government effectiveness: how the model adapts the literature series, selected countries
figGeAdaptation <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); d <- x$part4[x$part4$indicator == "ge" & x$part4$c %in% names(.instCountries()), ]
  d <- d[(d$source %in% c("WGI (observed)", "model (SSP2, harmonised)") | d$ssp == "SSP2") & d$year >= 2000 & d$year <= 2100, ]
  d$source[d$source == "PoliClim"] <- "PoliClim SSP2"
  d$source[d$source == "Andrijevic et al. 2020"] <- "Andrijevic et al. 2020, SSP2"
  d$country <- factor(.instCountries()[d$c], levels = .instCountries())
  col <- c(`WGI (observed)` = "grey15", `Andrijevic et al. 2020, SSP2` = "#eb6834", `model (SSP2, harmonised)` = pfmAccent(),
           `PoliClim SSP2` = "#52514e")
  p <- ggplot2::ggplot(d, ggplot2::aes(year, v, colour = source, linetype = source)) + ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::geom_vline(xintercept = 2023, colour = "grey70", linewidth = 0.3) +
    ggplot2::facet_wrap(~country, ncol = 3) + ggplot2::scale_colour_manual(values = col, name = NULL) +
    ggplot2::scale_linetype_manual(values = c(`WGI (observed)` = "solid", `Andrijevic et al. 2020, SSP2` = "22",
                                              `model (SSP2, harmonised)` = "solid", `PoliClim SSP2` = "42"), name = NULL) +
    ggplot2::labs(title = "Government effectiveness: Andrijevic's change, anchored to the WGI level",
                  subtitle = paste("Each series on its own normalised range. The model starts from the WGI panel value in 2023 and joins",
                                   "\nAndrijevic's SSP2 path by 2040, when the offset has faded. PoliClim for comparison, not used."),
                  x = NULL, y = "normalised index")
  attr(p, "pfmGrid") <- "y"; attr(p, "pfmHeightScale") <- 1.5
  pfmStamp(p, group, note = "institution-rule.rds (part 4)")
}

# 9. government effectiveness: the two literature projections disagree
figGeLiteratures <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); d <- x$part4[x$part4$indicator == "ge", ]
  w <- function(src, y) { z <- d[d$source == src & d$ssp == "SSP2" & d$year == y, ]; stats::setNames(z$v, z$c) }
  a0 <- w("Andrijevic et al. 2020", 2025); a1 <- w("Andrijevic et al. 2020", 2099)   # the published series ends in 2099
  p0 <- w("PoliClim", 2025); p1 <- w("PoliClim", 2100); cc <- intersect(names(a0), names(p0))
  sc <- data.frame(c = cc, level = p0[cc], andrijevic = a1[cc] - a0[cc], policlim = p1[cc] - p0[cc])
  sc <- sc[stats::complete.cases(sc), ]
  long <- rbind(data.frame(sc[, c("c", "level")], source = "Andrijevic et al. 2020", change = sc$andrijevic),
                data.frame(sc[, c("c", "level")], source = "PoliClim", change = sc$policlim))
  r <- sprintf("countries declining: Andrijevic %d%%, PoliClim %d%% of %d", round(100 * mean(sc$andrijevic < 0)),
               round(100 * mean(sc$policlim < 0)), nrow(sc))
  p <- ggplot2::ggplot(long, ggplot2::aes(level, change, colour = source)) + ggplot2::geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
    ggplot2::geom_point(size = 1.2, alpha = 0.7) + ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = FALSE, linewidth = 0.6) +
    ggplot2::scale_colour_manual(values = c(`Andrijevic et al. 2020` = "#eb6834", PoliClim = "#52514e"), name = NULL) +
    ggplot2::labs(title = "Government effectiveness, SSP2: Andrijevic rises everywhere, PoliClim reverts to the mean",
                  subtitle = paste0("Change 2025-2100 against the 2025 level (normalised WGI scale). ", r, ".\n",
                                    "PoliClim is fitted on the yearly re-standardised WGI, so it learns convergence to the mean."),
                  x = "2025 level (PoliClim, normalised)", y = "change 2025-2100 (Andrijevic: to 2099)")
  attr(p, "pfmGrid") <- "both"
  pfmStamp(p, group, note = "institution-rule.rds (part 4)")
}

# 10. rule of law: the gap-closure rule beside both literature projections, as the change since 2025
figRolLiterature <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds")
  m <- x$part2[x$part2$series == "Rule of Law (VDem)" & x$part2$rule %in% c("gap closure", "current") & x$part2$year >= 2025 & x$part2$year <= 2100, ]
  m$source <- paste0("model: ", m$rule, " (V-Dem v2x_rule)")
  a <- x$part4[x$part4$indicator == "rol" & x$part4$source == "Andrijevic et al. 2020" & x$part4$year >= 2025 & x$part4$year <= 2100, ]
  a$source <- paste0("Andrijevic et al. 2020, ", a$ssp)
  p1 <- x$part1[x$part1$indicator == "rol" & x$part1$source == "PoliClim SSP2" & x$part1$year >= 2025, ]; p1$source <- "PoliClim SSP2 (v2xcl_rol)"
  d <- rbind(m[, c("source", "c", "year", "v")], a[, c("source", "c", "year", "v")], p1[, c("source", "c", "year", "v")])
  base <- d[d$year == 2025, c("source", "c", "v")]; names(base)[3] <- "v0"
  d <- merge(d, base, by = c("source", "c")); d$dv <- d$v - d$v0
  q <- stats::aggregate(dv ~ source + year, d, mean)
  col <- c(`model: gap closure (V-Dem v2x_rule)` = pfmAccent(), `model: current (V-Dem v2x_rule)` = "#C2571A",
           `PoliClim SSP2 (v2xcl_rol)` = "#52514e", `Andrijevic et al. 2020, SSP1` = "#2a78d6",
           `Andrijevic et al. 2020, SSP2` = "#eb6834", `Andrijevic et al. 2020, SSP3` = "#1baf7a")
  p <- ggplot2::ggplot(q, ggplot2::aes(year, dv, colour = source)) + ggplot2::geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.3) +
    ggplot2::geom_line(linewidth = 0.8) + ggplot2::scale_colour_manual(values = col, name = NULL) +
    ggplot2::guides(colour = ggplot2::guide_legend(ncol = 2)) +
    ggplot2::labs(title = "Rule of law: on the model's series, gap closure rises faster than both published SSP2 paths",
                  subtitle = paste("Cross-country mean change since 2025, each series on its own normalised scale.",
                                   "\nAndrijevic's Rule-of-Law Index (SSP1-3) and PoliClim are references; the model reads V-Dem's v2x_rule."),
                  x = NULL, y = "mean change since 2025")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "institution-rule.rds (parts 1, 2, 4)")
}

# 11. government effectiveness under the gap-closure rule (a test): the model's series under each variant
.geVarCol <- function() c(`Andrijevic SSP2 (the model)` = "#eb6834", `gap closure, rate fitted to Andrijevic SSP2` = pfmAccent(),
                          `gap closure, shared rate` = "#2a78d6", `held at 2023` = "grey60", history = "grey15")
figGeRuleSeries <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); p5 <- x$part5
  d <- p5$series[is.finite(p5$series$v) & p5$series$year >= 2025 & p5$series$year <= 2100, ]
  h <- x$history[x$history$series == "Government Effectiveness (WGI)", ]
  d <- rbind(d, data.frame(variant = "history", h[, c("c", "year", "v")]))
  q <- .instBand(d, c("variant", "year")); q$variant <- factor(q$variant, levels = names(.geVarCol()))
  lab <- sprintf("Rates: shared %.2f%%, fitted to Andrijevic SSP2 %.2f%% a year.", 100 * p5$rates[[2]], 100 * p5$rates[[3]])
  p <- ggplot2::ggplot(q, ggplot2::aes(year, m, colour = variant)) +
    ggplot2::geom_vline(xintercept = 2023, colour = "grey70", linewidth = 0.3) + ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_line(ggplot2::aes(y = lo), linewidth = 0.3, linetype = "22") + ggplot2::geom_line(ggplot2::aes(y = hi), linewidth = 0.3, linetype = "22") +
    ggplot2::scale_colour_manual(values = .geVarCol(), name = NULL) + ggplot2::guides(colour = ggplot2::guide_legend(ncol = 2)) +
    ggplot2::labs(title = "Government effectiveness under the gap-closure rule: slower than Andrijevic's SSP2",
                  subtitle = paste("The model's series (normalised, all countries): mean (solid), 10th / 90th percentile (dashed).", lab),
                  x = NULL, y = "normalised index")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "institution-rule.rds (part 5)")
}

# 12. ... and the strength k(t) on each
figGeRuleStrength <- function(group = "v7") {
  x <- pfmArtifact(group, "institution-rule.rds"); s <- x$part5$strength; s <- s[s$year <= 2100, ]
  s$variant <- factor(s$variant, levels = names(.geVarCol())[1:4])
  s$sector <- factor(s$sector, levels = c("Bulk", "Diffuse"), labels = c("Power & industry", "Buildings & transport"))
  end <- s[s$year == 2100, ]; end$lab <- sprintf("%.2f", end$k)
  end <- do.call(rbind, lapply(split(end, end$sector), function(e) { e <- e[order(e$k), ]; y <- e$k
    for (i in seq_along(y)[-1]) y[i] <- max(y[i], y[i - 1] + 0.035); e$ky <- y; e }))
  p <- ggplot2::ggplot(s, ggplot2::aes(year, k, colour = variant)) +
    ggplot2::geom_hline(yintercept = 1, colour = "grey70", linewidth = 0.3) + ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_text(data = end, ggplot2::aes(y = ky, label = lab), hjust = -0.2, size = 2.6, show.legend = FALSE) +
    ggplot2::facet_wrap(~sector) + ggplot2::scale_colour_manual(values = .geVarCol(), name = NULL) +
    ggplot2::guides(colour = ggplot2::guide_legend(ncol = 2)) +
    ggplot2::scale_x_continuous(limits = c(2025, 2108), breaks = c(2025, 2050, 2075, 2100)) +
    ggplot2::labs(title = "Government effectiveness moves the strength, through terms that are not identified",
                  subtitle = paste("Strength k(t), theta = 0.50, 1000 Gt hold-the-price energy system (EU21), gap-closure panel with each",
                                   "\ngovernment-effectiveness variant. Offline. Slower improvement lowers power & industry k and raises buildings & transport k."),
                  x = NULL, y = "strength k(t)")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "institution-rule.rds (part 5)")
}

# 13. where the rate comes from: V-Dem history and the published SSP assumptions, against the declared 0.6% a year
figInstRateJustification <- function(group = "v7") {
  x <- pfmArtifact(group, "gap-closure-history.rds"); r <- pfmArtifact(group, "institution-rule.rds")$rates$rate[1]
  h <- x$history; h$label <- sub("^window ", "", sub("^pooled 1900-2025, ", "1900-2025, ", h$sample))
  h$series <- .instLab()[h$series]
  an <- x$anchors
  a2 <- an[grepl("SSP2: linear", an$anchor), ]; a1 <- an[grepl("SSP1", an$anchor), ]; cr <- an[grepl("current rule", an$anchor), ]
  pub <- data.frame(label = c("Andrijevic SSP2", "Andrijevic SSP1", "current rule (SSP2)"),
                    lo = c(a2$lambdaSameShare, min(a1$lambdaSameShare, a1$lambdaSameHalfway), min(cr$lambdaSameShare, cr$lambdaSameHalfway)),
                    hi = c(a2$lambdaSameHalfway, max(a1$lambdaSameShare, a1$lambdaSameHalfway), max(cr$lambdaSameShare, cr$lambdaSameHalfway)))
  lev <- c(rev(unique(h$label)), rev(pub$label))
  h$label <- factor(h$label, levels = lev); pub$label <- factor(pub$label, levels = lev)
  h$group <- "V-Dem history (the rule fitted to every country)"; pub$group <- "published and current assumptions"
  p <- ggplot2::ggplot() +
    ggplot2::geom_vline(xintercept = 100 * r, colour = pfmAccent(), linewidth = 0.8) +
    ggplot2::geom_segment(data = pub, ggplot2::aes(x = 100 * lo, xend = 100 * hi, y = label, yend = label), linewidth = 2.2, colour = "grey45") +
    ggplot2::geom_point(data = h, ggplot2::aes(100 * lambda, label, colour = series, shape = series), size = 2.4) +
    ggplot2::facet_grid(group ~ ., scales = "free_y", space = "free_y") +
    ggplot2::scale_colour_manual(values = c(`Rule of law (V-Dem)` = "#eb6834", `Vertical accountability (V-Dem)` = "#2a78d6"), name = NULL) +
    ggplot2::scale_shape_manual(values = c(`Rule of law (V-Dem)` = 16, `Vertical accountability (V-Dem)` = 17), name = NULL) +
    ggplot2::annotate("text", x = 100 * r, y = Inf, label = sprintf("declared: %.1f%% a year", 100 * r), hjust = -0.05, vjust = 1.3,
                      size = 2.7, colour = pfmAccent()) +
    ggplot2::labs(title = "Where the rate comes from: V-Dem history and Andrijevic et al.'s SSP2 assumption",
                  subtitle = paste("Share of the distance to the best observed value closed a year. History: x(s+h) = 1 - (1 - x(s)) exp(-lambda h),",
                                   "\nfitted over every country. Bars: exponential rates matching a linear convergence (2100 share / half-way year)."),
                  x = "rate (% of the remaining gap a year)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  attr(p, "pfmTheme") <- ggplot2::theme(strip.text.y = ggplot2::element_text(angle = 0, hjust = 0, face = "bold"))
  pfmStamp(p, group, note = "gap-closure-history.rds")
}
