# The report figures (medium `doc`): the charts of the written reports (ELEVATE D3.3), drawn in the
# report style (style.R) so they match the PowerPoint schematics of pptx/.
#
# They show the frontier with its interest x institution interactions weighted by a V-Dem
# democracy index — the formulation considered for v7, applied offline to a Run-Group's data by
# analysis/checks/interactionWeightPaths.R (artifact interaction-weight-paths.rds). The weight is
# the one that artifact chose by its declared rule ($choice$chosen). No value is printed on these
# charts: the reports quote no results, and the charts carry "Preliminary results".

docWeightPaths <- function(group) {
  W <- pfmArtifact(group, "interaction-weight-paths.rds")
  w <- W$choice$chosen
  if (is.null(w) || is.na(w)) stop("interaction-weight-paths.rds has no chosen weight", call. = FALSE)
  attr(W, "weight") <- w
  W
}

# readable term names, in the order the coefficient chart shows them
docTermLabel <- function(raw) {
  # the names the reports' text uses (D3.3 Section 3.3), so a chart and the prose say the same thing
  x <- pfmPrettyTerm(raw)
  repl <- c("Incumbent pc" = "Fossil-fuel interest per capita", "Incumbent" = "Fossil-fuel dependence",
            "Innovator" = "Clean-energy development", "Gov. Effectiveness" = "State capability",
            "Rule of Law" = "Rule of law", "Vertical Acc." = "Vertical accountability",
            "GDP p.c. (Q-centred)" = "Income (GDP per capita)", "Population (log)" = "Population",
            "Hydro/nuclear share" = "Hydro, nuclear and geothermal share", "Logistic time trend" = "Common time trend",
            "FE: OECD non-EU" = "Country group: OECD outside the EU", "FE: other" = "Country group: other countries")
  for (k in names(repl)) x <- gsub(k, repl[[k]], x, fixed = TRUE)
  x
}
docTermKind <- function(raw) {
  ifelse(pfmIsInteraction(raw), "interactions",
  ifelse(grepl("Power", raw), "interests",
  ifelse(grepl("WGI|VDem", raw), "institutions", "controls, trend, groups")))
}

#' Coefficients of the frontier, scaled: beta x SD(term) in the estimation data (logits per SD)
figDocCoefficients <- function(group = "v6") {
  W <- docWeightPaths(group); w <- attr(W, "weight")
  d <- W$coefs[W$coefs$weight == w & !W$coefs$term %in% c("(Intercept)", "sigmaSq", "gamma"), ]
  d$scaled <- d$estimate * d$sdX
  d$p <- 2 * stats::pnorm(-abs(d$estimate / d$se))
  d$sig <- is.finite(d$p) & d$p < 0.05
  d$kind <- factor(docTermKind(d$term), levels = c("interests", "institutions", "interactions", "controls, trend, groups"))
  d$label <- docTermLabel(d$term)
  # order: kind, then the order of the first sector's terms
  ord <- unique(d$label[order(d$kind, match(d$term, unique(d$term)))])
  d$label <- factor(d$label, levels = rev(ord))
  cols <- c(interests = docColour("teal"), institutions = docColour("slate"), interactions = docColour("deep"),
            `controls, trend, groups` = docColour("light"))
  lim <- max(abs(d$scaled), na.rm = TRUE) * 1.05
  p <- ggplot2::ggplot(d, ggplot2::aes(x = scaled, y = label, fill = kind, alpha = sig)) +
    ggplot2::geom_vline(xintercept = 0, colour = docColour("muted"), linewidth = 0.35) +
    ggplot2::geom_col(width = 0.72) +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_fill_manual(values = cols, drop = FALSE) +
    ggplot2::scale_alpha_manual(values = c(`TRUE` = 1, `FALSE` = 0.3), guide = "none") +
    ggplot2::scale_x_continuous(limits = c(-lim, lim), breaks = c(-0.5, 0, 0.5)) +
    ggplot2::guides(fill = ggplot2::guide_legend(nrow = 1, override.aes = list(alpha = 1))) +
    ggplot2::labs(x = "scaled coefficient (pale: p ≥ 0.05); main effects are conditional on the interactions", y = NULL)
  attr(p, "pfmTheme") <- theme_doc(grid = "x") + ggplot2::theme(panel.spacing = ggplot2::unit(1.6, "lines"))
  attr(p, "pfmHeightScale") <- 1.45
  docPreliminary(p)
}

#' Observed stringency against the estimated ceiling, 2023, countries with observed stringency
figDocFrontierFit <- function(group = "v6", nLabel = 3) {
  W <- docWeightPaths(group); w <- attr(W, "weight")
  d <- W$anchor[W$anchor$weight == w & W$anchor$basis == "observed", ]
  # labels (author, 2026-10-16): per sector, the n countries closest to their ceiling and the n furthest below it
  d$ratio <- d$indexAnchor / d$ceilingAnchor
  lab <- do.call(rbind, lapply(split(d, d$sector), function(x) {
    x <- x[order(x$ratio), ]; rbind(utils::head(x, nLabel), utils::tail(x, nLabel)) }))
  p <- ggplot2::ggplot(d, ggplot2::aes(x = ceilingAnchor, y = indexAnchor)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = docColour("ink"), linewidth = 0.45) +
    ggplot2::geom_segment(ggplot2::aes(xend = ceilingAnchor, yend = ceilingAnchor), colour = docColour("grid"), linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(colour = sector), size = 1.6, alpha = 0.9) +
    ggrepel::geom_text_repel(data = lab, ggplot2::aes(label = region), size = figureStyle()$size$tiny / ggplot2::.pt,
                             family = figureStyle()$font$body, colour = docColour("ink"), min.segment.length = 0,
                             segment.colour = docColour("faint"), segment.size = 0.3, box.padding = 0.35, seed = 1,
                             max.overlaps = Inf) +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_colour_manual(values = docSectorColours(), guide = "none") +
    ggplot2::scale_x_continuous(limits = c(0, 10), breaks = seq(0, 10, 2.5), labels = c("0", "2.5", "5", "7.5", "10"), expand = c(0.01, 0)) +
    ggplot2::scale_y_continuous(limits = c(0, 10), breaks = seq(0, 10, 2.5), labels = c("0", "2.5", "5", "7.5", "10"), expand = c(0.01, 0)) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "estimated ceiling S* (CAPMF stringency, 0–10)", y = "observed stringency S")
  attr(p, "pfmTheme") <- theme_doc(grid = "both") + ggplot2::theme(panel.spacing = ggplot2::unit(1.4, "lines"))
  attr(p, "pfmHeightScale") <- 1.05
  docPreliminary(p)
}

#' Feasibility share by region and sector group at the start of the projection (central severity)
figDocShares <- function(group = "v6", theta = 0.5) {
  W <- docWeightPaths(group); w <- attr(W, "weight")
  r <- W$rank[W$rank$weight == w & W$rank$resolution == "EU21", ]
  r$phi <- 1 - theta * r$u
  nm <- c(CAZ = "Canada, Australia, NZ", CHA = "China", DEU = "Germany", ECE = "EU Central-East", ECS = "EU Central-South",
          ENC = "EU North-Central", ESC = "EU South-Central", ESW = "EU South-West", EWN = "EU West-North", FRA = "France",
          IND = "India", JPN = "Japan", LAM = "Latin America", MEA = "Middle East & N. Africa", NEN = "Non-EU North Europe",
          NES = "Non-EU South Europe", OAS = "Other Asia", REF = "Russia & reforming econ.", SSA = "Sub-Saharan Africa",
          UKI = "UK & Ireland", USA = "United States")
  obs <- tapply(r$shareObserved, r$region, min)
  lab <- paste0(nm[names(obs)], ifelse(obs < 0.5, " *", "")); names(lab) <- names(obs)
  mn <- tapply(r$phi, r$region, mean)
  r$lab <- factor(lab[r$region], levels = lab[names(sort(mn))])
  seg <- do.call(rbind, lapply(split(r, r$region), function(x) data.frame(lab = x$lab[1], lo = min(x$phi), hi = max(x$phi))))
  p <- ggplot2::ggplot(r) +
    ggplot2::geom_segment(data = seg, ggplot2::aes(x = lo, xend = hi, y = lab, yend = lab), colour = docColour("grid"), linewidth = 1) +
    ggplot2::geom_point(ggplot2::aes(phi, lab, colour = sector, shape = sector), size = 2.2) +
    ggplot2::scale_colour_manual(values = docSectorColours()) +
    ggplot2::scale_shape_manual(values = c(Bulk = 16, Diffuse = 17)) +
    ggplot2::scale_x_continuous(limits = c(1 - theta - 0.02, 1.01), breaks = seq(0.5, 1, 0.1),
                                labels = c("0.5\nmost\nconstrained", "0.6", "0.7", "0.8", "0.9", "1.0\nleast\nconstrained")) +
    ggplot2::labs(x = "feasibility share", y = NULL)
  attr(p, "pfmTheme") <- theme_doc(grid = "x")
  attr(p, "pfmHeightScale") <- 1.35
  docPreliminary(p)
}

#' The data of the gap figure (an editable PowerPoint chart, pptx/fig-gap.js), written as JSON:
#' one country's observed stringency and ceiling, 2001-2023, and its projection on the energy
#' system of the coupled hold-the-price central run, 2025-2100; the dotted path applies a declared
#' yearly erosion kappa of the gap from 2025 (the coupling's (1 - kappa)^(t - 2025), ADR 0050).
docGapData <- function(group = "v6", sector = "Bulk", kappa = 0.027, file) {
  W <- docWeightPaths(group); w <- attr(W, "weight")
  h <- W$series[W$series$weight == w & W$series$sector == sector, c("year", "S", "Sstar")]
  pr <- W$projection[W$projection$weight == w & W$projection$sector == sector & W$projection$year >= 2025 &
                       W$projection$year <= 2100, c("year", "feasibleIndex", "ceilingIndex")]
  pr <- pr[order(pr$year), ]
  g <- 1 - pr$feasibleIndex / pr$ceilingIndex
  Sk <- pr$ceilingIndex * (1 - g * (1 - kappa)^(pr$year - 2025))
  out <- list(group = group, weight = w, sector = sector, kappa = kappa,
              hist = list(year = h$year, S = round(h$S, 4), Sstar = round(h$Sstar, 4)),
              proj = list(year = pr$year, S = round(pr$feasibleIndex, 4), Sstar = round(pr$ceilingIndex, 4), Sk = round(Sk, 4)))
  jsonlite::write_json(out, file, auto_unbox = TRUE, pretty = TRUE, digits = NA)
  invisible(file)
}
