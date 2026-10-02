# Compare phi between two Run-Groups that differ ONLY in the pinned specification.
#
# The full-data counterpart to analysis/testSectorSpecificSpec.R. That script approximates the
# region step on a laptop; this one reads what the real pipeline produced - final-energy
# weights, the projected tier year, the out-of-coverage transfer, and all 21 regions including
# the USA, which the laptop test cannot see at all because it is 0% covered.
#
# Usage, after both groups have run pfm-coupling-bound:
#   Rscript analysis/checks/compareSpecVariantPhi.R v1 v1-specalt

`%||%` <- function(x, y) if (is.null(x)) y else x

compareSpecVariantPhi <- function(a = "v1", b = "v1-specalt", resultsDir = "output/pfm",
                                  theta = 0.50, verbose = TRUE, save = TRUE) {
  say <- function(...) if (isTRUE(verbose)) cat(..., "\n", sep = "")
  rd <- function(g) {
    p <- file.path(resultsDir, g, "coupling", "coupling-summary.rds")
    if (!file.exists(p)) {
      stop("compareSpecVariantPhi: ", p, " not found - has pfm-coupling-bound run for '",
           g, "'?")
    }
    readRDS(p)
  }
  A <- rd(a); B <- rd(b)

  # NORMALISE TO A COMMON THETA, always. anchorTheta is a property of the ARTIFACT, not of the
  # project: a group written before an anchor correction carries the old value, and comparing
  # the phi columns directly then measures the DIAL, not the specification. The first run of
  # this script did exactly that and reported max |dphi| 0.287 for France when the true figure
  # was 0.156 - the tell was that each group's floor regions sat at exactly 1-theta of its OWN
  # theta. Both groups now carry 0.50 and the renormalisation is a no-op, which is precisely
  # why it stays: it costs nothing and it is the only thing standing between a future anchor
  # change and a wrong answer.
  #
  # u = (1 - phi)/theta is the min-max position of the region's gap and is theta-INVARIANT, so
  # recovering it and re-applying one theta makes the two comparable exactly.
  uOf <- function(cs) {
    d <- unique(cs$boundAnchor[, c("region", "phi")])
    d$u <- (1 - d$phi) / cs$anchorTheta
    d[, c("region", "u")]
  }
  ua <- uOf(A); names(ua)[2] <- "u_a"
  ub <- uOf(B); names(ub)[2] <- "u_b"
  m <- merge(ua, ub, by = "region")
  m$phi_a <- 1 - theta * m$u_a
  m$phi_b <- 1 - theta * m$u_b
  m$d <- m$phi_b - m$phi_a
  m <- m[order(m$phi_a), ]

  if (!isTRUE(all.equal(A$anchorTheta, B$anchorTheta))) {
    say("NOTE: the groups were written at different theta (", a, " = ", A$anchorTheta,
        ", ", b, " = ", B$anchorTheta, ").")
    say("      Both have been renormalised to theta = ", theta,
        " via the theta-invariant u = (1-phi)/theta.")
    say("      Comparing the stored phi columns directly would measure the DIAL, not the spec.")
  }

  say("=== phi, full pipeline, renormalised to a COMMON theta = ", theta, " ===")
  say(sprintf("%-6s %8s %8s %9s", "regi", a, b, "delta"))
  for (i in seq_len(nrow(m))) {
    say(sprintf("%-6s %8.3f %8.3f %+9.3f", m$region[i], m$phi_a[i], m$phi_b[i], m$d[i]))
  }

  fl <- function(x, p) x$region[abs(p - min(p)) < 1e-9]
  say("\nSpearman of phi      : ", sprintf("%.4f", stats::cor(m$phi_a, m$phi_b, method = "spearman")))
  say("median |delta phi|   : ", sprintf("%.4f", stats::median(abs(m$d))))
  say("max    |delta phi|   : ", sprintf("%.4f", max(abs(m$d))), "  (",
      m$region[which.max(abs(m$d))], ")")
  say("floor region(s)      : ", a, " = ", paste(fl(m, m$phi_a), collapse = ","),
      "  |  ", b, " = ", paste(fl(m, m$phi_b), collapse = ","))
  r1 <- rank(m$phi_a); r2 <- rank(m$phi_b)
  say("median |rank shift|  : ", sprintf("%.1f", stats::median(abs(r2 - r1))), " of ", nrow(m))
  # Regions the alternative cannot touch are those where the OTHER sector binds, so the
  # min() absorbs the change entirely. Reporting the count separates "the spec does not
  # matter" from "the spec does not matter HERE".
  nz <- sum(abs(m$d) < 1e-9)
  say("unaffected regions   : ", nz, " of ", nrow(m),
      "  (other sector binds, so min() absorbs the change)")

  # The band is a paper number (claim C31), so it has to leave an artifact rather than only a
  # console line: paper-data may quote nothing that is not in a file.
  out <- list(
    groups = c(deployed = a, variant = b), theta = theta,
    # coupling-summary.rds does not carry the spec name, so take it from the pin itself.
    spec = vapply(c(deployed = a, variant = b), function(g) {
      f <- pfm:::.pfmSelectedModels(file.path(resultsDir, g))
      if (!file.exists(f) || !requireNamespace("yaml", quietly = TRUE)) return(NA_character_)
      sel <- yaml::read_yaml(f)
      paste(vapply(c("Bulk", "Diffuse"), function(sec) {
        e <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)
        paste0(sec, ": ", if (length(e)) e[[1]]$name else NA_character_)
      }, character(1)), collapse = " | ")
    }, character(1)),
    byRegion = m,
    stats = list(
      spearman = stats::cor(m$phi_a, m$phi_b, method = "spearman"),
      medAbsDPhi = stats::median(abs(m$d)), maxAbsDPhi = max(abs(m$d)),
      maxRegion = m$region[which.max(abs(m$d))],
      medRankShift = stats::median(abs(rank(m$phi_b) - rank(m$phi_a))),
      nRegions = nrow(m), nUnaffected = sum(abs(m$d) < 1e-9),
      floorDeployed = fl(m, m$phi_a), floorVariant = fl(m, m$phi_b)))
  if (isTRUE(save)) {
    f <- file.path(resultsDir, a, "coupling", paste0("spec-band-", b, ".rds"))
    dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
    saveRDS(out, f)
    say("\nwrote ", f)
  }

  say("\n>>> CURRENT, v5 vs v5-specalt (Bulk pinned to X-1791, its per-sector optimum):")
  say(">>> Spearman 0.775, median |dphi| 0.0001, max 0.271 (IND), median rank shift 1 of 21,")
  say(">>> 2 of 21 unaffected, floor regions CHA+REF (v5) -> CHA+IND (v5-specalt). MODEL.md 5.3.0.")
  say(">>> READ IT AS A FEW BIG MOVES, NOT A SMALL BAND: the median is ~0, but IND -0.271,")
  say(">>> OAS -0.187, CAZ -0.101, REF +0.090 and ENC -0.070, and the floor region CHANGES -")
  say(">>> which is what the coupling consumes (ADR 0041). Quote max and rank shift too.")
  say(">>> SUPERSEDED, do not quote: v4 vs v4-specalt (0.865/0.034/0.169 ESW); v1 vs")
  say(">>> v1-specalt (0.826/0.110/0.254 FRA); and before that the laptop approximation")
  say(">>> (0.776/0.042/0.169) and the first cluster run (0.895/0.031/0.156), which carried")
  say(">>> the broken aggregation weight in BOTH groups. It did NOT cancel in the difference -")
  say(">>> near-equal weights compress the between-region spread that min-max normalisation")
  say(">>> acts on, so the statistic was suppressed in both at once. See PITFALLS.md 20.")
  invisible(out)
}

if (!interactive() && identical(environment(), globalenv())) {
  a <- commandArgs(trailingOnly = TRUE)
  compareSpecVariantPhi(a = if (length(a) > 0) a[1] else "v1",
                        b = if (length(a) > 1) a[2] else "v1-specalt")
}
