# Fig 4a — where the ceiling is actually estimated, and where it is not.
#
# The rail governs the whole design: out-of-coverage countries render as ABSENT, never as a
# value. 200 of 248 projected countries are outside the estimation sample, and a choropleth
# that colours all 248 on one scale would present a transferred relative gap as if it were a
# measurement — which is the single most misleading thing this project could publish.
#
# So: estimated countries carry the colour scale; everything else is a flat "no estimate"
# grey with the count stated in the legend. The map's honest message is as much about the
# grey as the colour.
#
# Uses E = S/S*, not projection.rds$implementability (which is S/10 — prohibited, see
# fig-efficiency-distribution.R).

figImplementabilityMap <- function(group = "v5", sector = "Bulk") {
  for (pkg in c("rnaturalearth", "sf")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("figImplementabilityMap needs '", pkg, "'", call. = FALSE)
    }
  }
  d <- .pfmEfficiencyByProvenance(group)
  d <- d[d$sector == sector & is.finite(d$E), ]
  obs <- d[d$basis == "observed", c("region", "E")]

  w <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

  # NOT iso_a3: Natural Earth codes it -99 for France and Norway (disputed-sovereignty
  # handling), which silently dropped both from the map - 46 countries coloured where 48
  # are estimated. iso_a3_eh and adm0_a3 both resolve all 48. Try in order and ASSERT the
  # count, because a country quietly missing from a choropleth is invisible in review.
  iso <- NULL
  for (fld in c("iso_a3_eh", "adm0_a3", "iso_a3")) {
    if (fld %in% names(w) && sum(obs$region %in% w[[fld]]) > sum(obs$region %in% iso)) {
      iso <- w[[fld]]
    }
  }
  matched <- sum(obs$region %in% iso)
  if (matched < nrow(obs)) {
    stop("figImplementabilityMap: only ", matched, " of ", nrow(obs),
         " estimated countries matched the basemap (missing: ",
         paste(setdiff(obs$region, iso), collapse = ", "),
         "). Fix the join rather than shipping a map with countries silently absent.",
         call. = FALSE)
  }
  w$E <- obs$E[match(iso, obs$region)]
  w <- w[!(w$name %in% "Antarctica"), ]

  # COUNTRIES, not polygons: Natural Earth carries several polygons per sovereign state
  # (France plus overseas departments, Norway plus Svalbard), so counting filled polygons
  # reported 50 where 48 countries are estimated.
  nEst <- nrow(obs)
  rng <- range(obs$E)
  p <- ggplot2::ggplot(w) +
    ggplot2::geom_sf(ggplot2::aes(fill = E), colour = "white", linewidth = 0.08) +
    ggplot2::scale_fill_viridis_c(
      option = "mako", direction = -1,
      limits = c(floor(rng[1] * 20) / 20, ceiling(rng[2] * 20) / 20),
      na.value = "grey88",
      name = "E = S / S*",
      guide = ggplot2::guide_colourbar(barheight = grid::unit(0.6, "lines"),
                                       barwidth = grid::unit(7, "lines"),
                                       title.vjust = 0.9)) +
    ggplot2::coord_sf(crs = "+proj=robin", datum = NA, expand = FALSE) +
    ggplot2::labs(
      title = sprintf("The ceiling is estimated for %d countries. Grey is not zero — it is unknown.",
                      nEst),
      subtitle = paste0(sector, " sector. Countries outside the estimation sample carry a ",
                        "TRANSFERRED relative gap,\nnot a measured one, and are deliberately ",
                        "left uncoloured."),
      x = NULL, y = NULL)
  attr(p, "pfmGrid") <- "none"
  pfmStamp(p, group, note = "grey = outside the estimation sample, no ceiling estimated")
}
