# Most of the world has never been measured.
#
# Reproduces ../_archive/_wip/2026-10-01/docs/figures/si-fig2-coverage.svg on the current Run-Group, following the
# original's design decisions rather than reinventing them:
#
#   * THREE provenance groups, not four. observed / donor-matched / rule-placed. The low
#     band and median branches are both "a rule was applied" and splitting them here adds a
#     distinction the figure is not making.
#   * Two horizontal stacked bars: by COUNTRY COUNT and by GDP. Counting countries
#     overstates the problem; GDP understates a different part of it. Neither alone is
#     honest, which is the point of showing both.
#   * The GDP bar is SUBDIVIDED by the largest contributing countries, because the finding
#     is not "coverage is better by GDP" but "what remains uncovered is one very large,
#     very consequential country". A flat GDP bar hides exactly that.
#   * Labels sit INSIDE the segments and country codes are rotated: horizontal text needs
#     roughly 38 px for a three-letter code against ~16 px rotated, and a label overlapping
#     its neighbour is worse than no label.
#
# GDP is a REPORTING weight here only. The coupling itself weights by final energy
# (MODEL.md 5.4) — stated on the figure so the two cannot be confused.

#' Provenance in three groups, with GDP share, for the coverage figure
.pfmCoverageGroups <- function(group, sector = "Bulk", gdpYear = 2022) {
  d <- .pfmEfficiencyByProvenance(group)
  d <- d[d$sector == sector, c("region", "basis")]
  d$grp <- ifelse(d$basis == "observed", "observed",
                  ifelse(d$basis == "donor", "donor", "rule"))

  # GDP LEVELS, and they are NOT in the Run-Group artifacts. The panel carries a
  # transformed GDP (every country compressed into roughly [0.18, 1.0] - Tuvalu at 0.39
  # against China at 0.998), which preserves the ORDERING but destroys the shares, so
  # computing a GDP share from the panel would be silently meaningless.
  #
  # The levels come from the madrat cache instead. That is a deliberate exception to the
  # "figures read only Run-Group artifacts" rule, taken because the alternative is either
  # fabricating shares or dropping the panel that carries the finding. Flagged rather than
  # hidden: if the cache is absent the figure fails loudly rather than falling back.
  # The prepared project cache first, then the caches it is filled from (config.yml `madrat:`):
  # calcGDPPast is read by no pipeline builder, so a prepared cache need not hold it.
  rc <- pfm::pfmResolveConfig(file.path(figuresProjectRoot(), "config.yml"), verbose = FALSE)
  gfs <- file.path(c(rc$cachefolder, rc$madrat$cacheSources), "calcGDPPast.rds")
  gf <- c(gfs[file.exists(gfs)], gfs[1])[1]
  if (!file.exists(gf)) {
    stop("figCoverageThreeWays needs GDP LEVELS, which no Run-Group artifact carries ",
         "(the panel's GDP column is transformed and its shares are meaningless). ",
         "Expected the madrat cache at: ", gf, call. = FALSE)
  }
  gg <- readRDS(gf)
  if (is.list(gg) && !magclass::is.magpie(gg)) gg <- gg$x
  yrs <- magclass::getYears(gg, as.integer = TRUE)
  y <- max(yrs[yrs <= gdpYear])
  v <- as.numeric(gg[, y, 1])
  names(v) <- magclass::getItems(gg, dim = 1)
  d$gdp <- unname(v[d$region])
  d$gdp[!is.finite(d$gdp) | d$gdp < 0] <- 0
  attr(d, "gdpYear") <- y
  d
}

figCoverageThreeWays <- function(group = "v5", sector = "Bulk", minShare = 0.02) {
  d <- .pfmCoverageGroups(group, sector)
  gy <- attr(d, "gdpYear")

  lev  <- c("observed", "donor", "rule")
  NAME <- c(observed = "Observed", donor = "Donor-matched", rule = "Rule-placed")
  COL  <- c(observed = "#2a78d6", donor = "#eb6834", rule = "#1baf7a")
  DIV  <- c(observed = "#1c5cab", donor = "#c14a22", rule = "#14855c")

  # ── panel 1: country count ──────────────────────────────────────────────────
  cnt <- vapply(lev, function(k) sum(d$grp == k), integer(1))
  segs <- data.frame(panel = "count", grp = lev, w = cnt / sum(cnt),
                     n = cnt, stringsAsFactors = FALSE)
  segs$x1 <- cumsum(c(0, head(segs$w, -1)))
  segs$x2 <- cumsum(segs$w)
  segs$lab1 <- as.character(segs$n)
  segs$lab2 <- ifelse(segs$w > 0.11, NAME[segs$grp], "")

  # ── panel 2: GDP share, subdivided by the largest contributors ──────────────
  tot <- sum(d$gdp)
  gs <- vapply(lev, function(k) sum(d$gdp[d$grp == k]) / tot, numeric(1))
  gseg <- data.frame(panel = "gdp", grp = lev, w = gs, n = NA_integer_,
                     stringsAsFactors = FALSE)
  gseg$x1 <- cumsum(c(0, head(gseg$w, -1)))
  gseg$x2 <- cumsum(gseg$w)
  gseg$lab1 <- sprintf("%.0f%%", 100 * gseg$w)
  gseg$lab2 <- ifelse(gseg$w > 0.11, NAME[gseg$grp], "")

  sub <- do.call(rbind, lapply(lev, function(k) {
    x <- d[d$grp == k, ]
    x$share <- x$gdp / tot
    x <- x[order(-x$share), ]
    big <- x[x$share >= minShare, , drop = FALSE]
    if (!nrow(big)) return(NULL)
    off <- gseg$x1[gseg$grp == k]
    data.frame(grp = k, region = big$region, share = big$share,
               x1 = off + cumsum(c(0, head(big$share, -1))),
               x2 = off + cumsum(big$share), stringsAsFactors = FALSE)
  }))

  bars <- rbind(segs, gseg)
  bars$panel <- factor(bars$panel, levels = c("count", "gdp"),
                       labels = c(sprintf("By COUNTRY COUNT — %d countries", sum(cnt)),
                                  sprintf("By GDP — share of world output %d, subdivided by contributors above %.0f%%",
                                          gy, 100 * minShare)))
  sub$panel <- levels(bars$panel)[2]
  # alternate the darker step within each group so adjacent countries stay distinguishable
  sub$alt <- unlist(lapply(split(seq_len(nrow(sub)), sub$grp),
                           function(i) seq_along(i) %% 2 == 1), use.names = FALSE)
  obsCount <- segs$w[segs$grp == "observed"]
  obsGdp   <- gseg$w[gseg$grp == "observed"]

  p <- ggplot2::ggplot() +
    ggplot2::geom_rect(data = bars,
                       ggplot2::aes(xmin = x1, xmax = x2, ymin = 0, ymax = 1, fill = grp),
                       colour = "white", linewidth = 0.5) +
    # country subdivisions: a darker step of the segment's OWN hue, alternating, so the
    # block still reads as one whole rather than as separate bars. A surface-coloured rule
    # would cut it into what look like separate segments.
    ggplot2::geom_rect(data = sub[sub$alt, , drop = FALSE],
                       ggplot2::aes(xmin = x1, xmax = x2, ymin = 0, ymax = 1,
                                    fill = paste0(grp, "_dark")),
                       colour = NA, show.legend = FALSE) +
    ggplot2::geom_rect(data = sub,
                       ggplot2::aes(xmin = x1, xmax = x2, ymin = 0, ymax = 1),
                       fill = NA, colour = "white", linewidth = 0.3,
                       show.legend = FALSE) +
    ggplot2::geom_text(data = sub, ggplot2::aes(x = (x1 + x2) / 2, y = 0.5,
                                                label = region),
                       angle = 90, size = 2.1, colour = "white", fontface = "bold") +
    ggplot2::geom_text(data = bars[bars$lab1 != "", ],
                       ggplot2::aes(x = x1 + 0.006, y = 0.80, label = lab1),
                       hjust = 0, size = 2.9, colour = "white", fontface = "bold") +
    ggplot2::geom_text(data = bars[bars$lab2 != "", ],
                       ggplot2::aes(x = x1 + 0.006, y = 0.20, label = lab2),
                       hjust = 0, size = 2.3, colour = "white", alpha = 0.9) +
    ggplot2::facet_wrap(~ panel, ncol = 1) +
    ggplot2::scale_fill_manual(
      values = c(COL, stats::setNames(DIV, paste0(names(DIV), "_dark"))),
      labels = NAME, breaks = lev) +
        ggplot2::scale_x_continuous(labels = function(x) paste0(round(100 * x), "%"),
                                expand = ggplot2::expansion(mult = 0.004)) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = 0)) +
    ggplot2::labs(
      title = "Most of the world has never been measured",
      subtitle = sprintf(paste("Counting countries overstates the problem: %.0f%% are",
                               "observed, but they are %.0f%% of world GDP.\nCounting GDP",
                               "hides a different one — what remains uncovered is a few",
                               "very large economies."),
                         100 * obsCount, 100 * obsGdp),
      x = NULL, y = NULL)
  attr(p, "pfmGrid") <- "none"
  attr(p, "pfmTheme") <- ggplot2::theme(
    axis.text.y = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(hjust = 0, size = ggplot2::rel(0.85),
                                       colour = "grey30"),
    panel.spacing.y = grid::unit(1.1, "lines"))
  pfmStamp(p, group,
           note = "GDP is a REPORTING weight only - the coupling weights by final energy")
}
