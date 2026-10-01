# Fig 5c — the mechanism is not an artefact of assuming high ambition.
#
# The NPi twins run every mechanism on the CURRENT-POLICIES pathway. If the coupled effect
# only appeared under an ambitious budget, a referee would rightly say the result is a
# property of high ambition rather than of politics. All six bars point the same way, so it
# is not.
#
# The figure also has to carry the methodological point that makes it honest: the effect is
# measured against the theta = 0 null, and measuring it against the UNCOUPLED baseline
# instead flips the sign. That confound is 4-45x the size of the signal, so it is drawn to
# scale as a separate marker rather than described in the caption where nobody reads it.
#
# Form: horizontal bars of the EFFECT (a difference), faceted by resolution. Faceting rather
# than colour-by-resolution deliberately: pfmSectorColours() is reserved for Bulk/Diffuse
# semantics across every other figure in this set, and reusing those hues for EU21/H12 would
# make hue mean two different things in one document.

figCoupledNpiTwins <- function(group = "v5") {
  a <- pfmArtifact(group, "coupling/coupled-runs.rds")
  r <- a$runs

  cum <- function(scen, res) {
    v <- r$cum2100[r$scenario == scen & r$resolution == res]
    if (!length(v)) NA_real_ else v[1]
  }

  mech <- c(PFMratio = "R — ratio\n(politics redistributes)",
            PFMlevel = "L — level cap\n(politics limits)",
            PFMmildProg = "M — mild progression\n(momentum only)")

  rows <- list()
  for (res in c("EU21", "H12")) {
    pre  <- if (identical(res, "EU21")) "SSP2-EU21-" else "SSP2-"
    null <- cum(paste0(pre, "NPi2025-PFMgate"), res)
    base <- cum(paste0(pre, "NPi2025"), res)          # the WRONG null
    for (m in names(mech)) {
      rows[[length(rows) + 1]] <- data.frame(
        resolution = res, mech = mech[[m]], key = m,
        effect = cum(paste0(pre, "NPi2025-", m), res) - null,
        stringsAsFactors = FALSE)
    }
    rows[[length(rows) + 1]] <- data.frame(
      resolution = res, mech = "the CONFOUND\n(regiDiff 6 → 11 alone)", key = "confound",
      effect = null - base, stringsAsFactors = FALSE)
  }
  d <- do.call(rbind, rows)

  # Every bar is a DIFFERENCE, so a missing twin renders as an absent bar rather than an
  # error: on 2026-09-14 this figure was rebuilt on a Run-Group whose batch carried no NPi
  # twins at all and it drew an empty panel under a headline asserting "all six bars point
  # the same way". Refuse instead. Same contract as figMarkupCounterfactual and
  # figCoupledConvergence: a builder that cannot find its runs says so.
  miss <- d$key[!is.finite(d$effect)]
  if (length(miss)) {
    stop("figCoupledNpiTwins: ", length(miss), " of ", nrow(d),
         " bars have no run in group ", group, " (", paste(unique(miss), collapse = ", "),
         "). The NPi twins and their -NPi2025-PFMgate null must be in the batch.",
         call. = FALSE)
  }

  d$mech <- factor(d$mech, levels = rev(c(unname(unlist(mech)),
                                          "the CONFOUND\n(regiDiff 6 → 11 alone)")))
  d$isConfound <- d$key == "confound"

  p <- ggplot2::ggplot(d, ggplot2::aes(x = effect, y = mech, fill = isConfound)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.4) +
    ggplot2::geom_col(width = 0.62) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%+.0f", effect),
                                    hjust = ifelse(effect < 0, 1.12, -0.12)),
                       size = 2.6, colour = "grey20") +
    ggplot2::scale_fill_manual(values = c(`FALSE` = pfmAccent(), `TRUE` = pfmRail()),
                               guide = "none") +
    ggplot2::facet_wrap(~ resolution, ncol = 2) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.22, 0.22))) +
    ggplot2::labs(
      title = "On current policies too, politics raises emissions — and the control decides the sign",
      subtitle = paste0(
        "Change in cumulative CO₂ to 2100 against the correct θ = 0 null, current-policies ",
        "pathway. All six blue bars point\nthe same way, so the mechanism is not an artefact ",
        "of assuming high ambition. The red bar is the effect of switching\n",
        "cm_taxCO2_regiDiff alone — measure against the uncoupled baseline instead and that ",
        "confound swamps the signal."),
      x = "Δ cumulative CO₂ to 2100, Gt", y = NULL)
  attr(p, "pfmGrid") <- "x"

  pfmStamp(p, group, note = "θ = 0.50; NPi twins, read against -NPi2025-PFMgate")
}
