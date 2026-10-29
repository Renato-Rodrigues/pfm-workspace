# Fig 4a-full — every projected country, with provenance made visible.
#
# The companion to fig-implementability-map, which shows ONLY the 48 estimated countries and
# leaves the rest grey. This one shows what the coupling actually uses: all 248, including
# the transferred values.
#
# The rail does not go away, it changes form. Colouring a transferred gap on the same scale
# as an estimated one presents an assumption as a measurement — so the transferred countries
# are drawn on the SAME colour scale but at reduced saturation, with a hatch-equivalent
# (white stipple border) and a legend that names the three transfer rules. The reader must be
# able to see, without reading the caption, which countries the model measured.
#
# Use fig-implementability-map for the paper where the honest claim is "this is what we
# know"; use this one where the question is "what does the coupling feed REMIND".

figImplementabilityMapFull <- function(group = "v5", sector = "Bulk") {
  for (pkg in c("rnaturalearth", "sf")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("figImplementabilityMapFull needs '", pkg, "'", call. = FALSE)
    }
  }
  d <- .pfmEfficiencyByProvenance(group)
  d <- d[d$sector == sector & is.finite(d$E), c("region", "E", "basis")]

  w <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
  iso <- NULL
  for (fld in c("iso_a3_eh", "adm0_a3", "iso_a3")) {
    if (fld %in% names(w) && sum(d$region %in% w[[fld]]) > sum(d$region %in% iso)) {
      iso <- w[[fld]]
    }
  }
  i <- match(iso, d$region)
  w$E <- d$E[i]
  w$basis <- d$basis[i]
  w <- w[!(w$name %in% "Antarctica"), ]

  # estimated countries keep full opacity; transferred ones are visibly lighter
  w$alpha <- ifelse(is.na(w$basis), NA_real_,
                    ifelse(w$basis == "observed", 1, 0.45))
  nBy <- table(d$basis)
  # a count by basis that is 0 when the basis does not occur (v8 has only "median": design note 0009 section 6.3)
  nOf <- function(b) if (b %in% names(nBy)) as.integer(nBy[[b]]) else 0L
  rule <- if (nOf("donor") + nOf("lowBand") == 0) "at the covered median" else "through the donor and band rules"

  sub <- sprintf(paste0("%s sector, all %d projected countries. %d ESTIMATED (full colour); ",
                        "%d transferred\n", rule, " (faded) — ",
                        "assumptions with a stated rule, not measurements."),
                 sector, nrow(d), sum(d$basis == "observed"), sum(d$basis != "observed"))

  p <- ggplot2::ggplot(w) +
    ggplot2::geom_sf(ggplot2::aes(fill = E, alpha = alpha), colour = "white",
                     linewidth = 0.08) +
    ggplot2::scale_fill_viridis_c(
      option = "mako", direction = -1, na.value = "grey92", name = "E = S / S*",
      guide = ggplot2::guide_colourbar(barheight = grid::unit(0.6, "lines"),
                                       barwidth = grid::unit(7, "lines"),
                                       title.vjust = 0.9)) +
    ggplot2::scale_alpha_identity() +
    ggplot2::coord_sf(crs = "+proj=robin", datum = NA, expand = FALSE) +
    ggplot2::labs(
      title = sprintf("What the coupling actually uses: %d measured, %d transferred",
                      sum(d$basis == "observed"), sum(d$basis != "observed")),
      subtitle = sub, x = NULL, y = NULL)
  attr(p, "pfmGrid") <- "none"
  attr(p, "pfmTheme") <- ggplot2::theme(
    axis.text = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank())
  pfmStamp(p, group,
           note = sprintf("faded = transferred (donor %d / low band %d / median %d)",
                          nOf("donor"), nOf("lowBand"), nOf("median")))
}
