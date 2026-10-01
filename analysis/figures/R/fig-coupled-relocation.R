# Fig 5d — where the abatement goes.
#
# The panel behind claims C36 and C37, adopted 2026-09-18. Everything else in Fig 5 is a global
# number; this is the only panel that says WHO. Two contrasts on one axis, because the pair is
# the finding:
#
#   budget held (-PFMratio vs -PFMgate)          net ~0, but 72-81 Gt changes region
#   price path held (-PFMlevelBfix vs -PFMgateBfix)  net +168 / +174, concentrated in the
#                                                     regions the ceiling binds hardest
#
# Regions are ordered by phi, most constrained at the top, so the correlation the claims report
# (Spearman -0.76 budget-held, -0.45 price-held at EU21) is visible as a shape rather than
# asserted as a number: the bars lengthen towards the top.
#
# 🔴 NOT a cost figure. vm_co2eq is emissions; the GDP and consumption numbers live in the
# claims with their no-damages caveat and are deliberately NOT drawn here - a GDP bar next to
# an emissions bar invites exactly the reading REMIND cannot support (it carries no climate
# damages, so less abatement always looks richer).

figCoupledRelocation <- function(group = "v5", resolutions = c("EU21", "H12")) {
  cc <- pfmArtifact(group, "coupling/coupled-costs.json")

  lab <- c(ratio = "budget held (mode R)", levelBfix = "price path held (the cap)")

  d <- do.call(rbind, lapply(resolutions, function(res) {
    do.call(rbind, lapply(names(lab), function(k) {
      b <- cc[[res]][[k]]$byRegion
      if (is.null(b) || !nrow(b)) return(NULL)
      data.frame(resolution = res, contrast = lab[[k]], region = b$region, phi = b$phi,
                 delta = b$deltaGtCO2eq, stringsAsFactors = FALSE)
    }))
  }))
  if (is.null(d) || !nrow(d)) {
    stop("figCoupledRelocation: no byRegion rows in coupled-costs.json - re-run ",
         "analysis/coupled/coupledCostsAndAbatement.R", call. = FALSE)
  }
  d$contrast <- factor(d$contrast, levels = unname(lab))

  # order regions by phi WITHIN each resolution, most constrained first
  ord <- unique(d[, c("resolution", "region", "phi")])
  ord <- ord[order(ord$resolution, -ord$phi), ]
  d$key <- paste(d$resolution, d$region)
  d$key <- factor(d$key, levels = paste(ord$resolution, ord$region))

  # the headline numbers, computed from the same rows the bars are drawn from
  net <- stats::aggregate(delta ~ resolution + contrast, d, sum)
  gross <- stats::aggregate(delta ~ resolution + contrast, d, function(x) sum(abs(x)) / 2)
  say <- function(cn) {
    i <- net$contrast == cn
    paste0(net$resolution[i], " ", sprintf("%+.0f", net$delta[i]), " Gt net / ",
           sprintf("%.0f", gross$delta[gross$contrast == cn]), " Gt moved", collapse = ", ")
  }

  p <- ggplot2::ggplot(d, ggplot2::aes(x = delta, y = key, fill = contrast)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.75), width = 0.7) +
    ggplot2::facet_grid(resolution ~ ., scales = "free_y", space = "free_y") +
    ggplot2::scale_y_discrete(labels = function(x) sub("^[A-Za-z0-9]+ ", "", x)) +
    ggplot2::scale_fill_manual(values = stats::setNames(
      c(pfmMuted(), pfmAccent()), levels(d$contrast))) +
    ggplot2::labs(
      title = "Politics moves abatement between regions, and moves it towards the constrained ones",
      subtitle = paste0(
        "Change in cumulative CO₂eq 2020-2100 against each run's matched θ = 0 null, by region, ",
        "θ = 0.50.\nRegions are ordered by their feasibility share φ - most constrained at the top.\n",
        "Budget held: ", say(levels(d$contrast)[1]), "\n",
        "Price path held: ", say(levels(d$contrast)[2])),
      x = "change in cumulative CO₂eq, Gt", y = NULL, fill = NULL)
  attr(p, "pfmGrid") <- "x"
  attr(p, "pfmTheme") <- ggplot2::theme(
    legend.position = "bottom",
    axis.text.y = ggplot2::element_text(size = ggplot2::rel(0.75)))
  pfmStamp(p, group,
           note = "emissions only; the GDP effect is not drawn - REMIND carries no climate damages (C37)")
}
