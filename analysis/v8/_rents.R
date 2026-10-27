# Fossil rents for the v8 tests (design note 0009 section 3), shared by analysis/v8/*.R.
#   v8RentsHistory(cty, years, cache)  World Bank WDI oil + gas + coal rents, % of GDP, per country and year: gaps
#                                      interpolated, held at the last value after 2021, log(1 + rents), centred
#                                      five-year mean (as every panel column). Matrix country x year.
#   v8RentsREMIND(gdx)                 a REMIND run's regional rents, % of GDP: sum over coal, oil and gas of
#                                      (regional primary-energy price x extraction - extraction cost) / GDP.
#                                      Matrix region x period.
#   v8RentsScenario(hist, gdx, map, years, link)  the scenario series per country: history to 2023; after that
#                                      either held at 2023 (link = FALSE) or the country's 2023 rents scaled by its
#                                      region's REMIND rents relative to 2025 (link = TRUE). log(1 + rents).
#   v8AddRents(x, R, exporter)         adds "Fossil Rents" (and its |Bulk, |Diffuse names, which the actor-power
#                                      reader takes) and, with `exporter`, the dummy "Fossil Exporter" (rents above
#                                      `exporter` % of GDP) to a magpie panel.
v8RentsHistory <- function(cty, years, cache) {
  wdi <- if (file.exists(cache)) readRDS(cache) else {
    options(timeout = 900)   # the World Bank API is slow; one indicator per request
    ind <- c(oil = "NY.GDP.PETR.RT.ZS", gas = "NY.GDP.NGAS.RT.ZS", coal = "NY.GDP.COAL.RT.ZS")
    parts <- lapply(names(ind), function(n) { x <- WDI::WDI(country = "all", indicator = stats::setNames(ind[[n]], n), start = 1995, end = 2023, extra = FALSE)
      if (!nrow(x)) stop("WDI download of ", ind[[n]], " returned nothing"); x[, c("iso3c", "year", n)] })
    x <- Reduce(function(a, b) merge(a, b, by = c("iso3c", "year"), all = TRUE), parts)
    saveRDS(x, cache); x }
  wdi$rents <- rowSums(wdi[, c("oil", "gas", "coal")], na.rm = TRUE)
  wdi$rents[rowSums(is.finite(as.matrix(wdi[, c("oil", "gas", "coal")]))) == 0] <- NA
  yy <- 1995:2023
  R <- matrix(NA_real_, length(cty), length(yy), dimnames = list(cty, yy))
  ok <- wdi$iso3c %in% cty
  R[cbind(match(wdi$iso3c[ok], cty), match(wdi$year[ok], yy))] <- wdi$rents[ok]
  dn <- dimnames(R)
  R <- t(apply(R, 1, function(r) { ok <- which(is.finite(r)); if (!length(ok)) return(r)
    r[seq_along(r) > max(ok)] <- r[max(ok)]; stats::approx(ok, r[ok], xout = seq_along(r), rule = 2)$y }))
  R <- log1p(R); dimnames(R) <- dn
  ma <- t(apply(R, 1, function(r) vapply(seq_along(r), function(i) mean(r[max(1, i - 2):min(length(r), i + 2)], na.rm = TRUE), 0)))
  dimnames(ma) <- dn
  ma[, as.character(intersect(years, yy)), drop = FALSE]
}

v8RentsREMIND <- function(gdx) {
  rd <- function(s, ...) suppressWarnings(gdx::readGDX(gdx, s, restore_zeros = FALSE, ...))
  fu <- c("pecoal", "peoil", "pegas")
  ex <- rd("vm_fuExtr", field = "l"); pr <- rd("pm_PEPrice"); co <- rd("vm_costFuEx", field = "l")
  gdp <- rd("vm_cesIO", field = "l")[, , "inco"]
  yrs <- intersect(intersect(magclass::getYears(ex), magclass::getYears(pr)), magclass::getYears(gdp))
  yrs <- yrs[magclass::getYears(magclass::new.magpie(years = yrs), as.integer = TRUE) >= 2005 &
               magclass::getYears(magclass::new.magpie(years = yrs), as.integer = TRUE) <= 2150]
  rent <- 0
  for (f in fu) {
    e <- magclass::dimSums(ex[, yrs, grep(paste0("^", f, "\\."), magclass::getNames(ex), value = TRUE)], dim = 3)
    rent <- rent + pr[, yrs, f] * e - co[, yrs, f]
  }
  out <- 100 * as.array(rent)[, , 1] / as.array(gdp[, yrs, ])[, , 1]
  colnames(out) <- sub("^y", "", colnames(out)); out
}

v8RentsScenario <- function(hist, gdx, map, years, link = TRUE) {
  cty <- rownames(hist); last <- hist[, "2023"]
  out <- matrix(NA_real_, length(cty), length(years), dimnames = list(cty, years))
  h <- intersect(as.character(years), colnames(hist)); out[, h] <- hist[, h]
  fut <- as.character(years[years > 2023])
  if (!link) { out[, fut] <- last; return(out) }
  rr <- v8RentsREMIND(gdx); base <- rr[, "2025"]
  ratio <- sweep(rr, 1, base, "/"); ratio[!is.finite(ratio)] <- 1; ratio <- pmin(pmax(ratio, 0), 3)   # tiny 2025 bases (ENC) would explode
  yr <- as.integer(colnames(rr))
  for (c in cty) {
    r <- map[[c]]; if (is.null(r) || is.na(r) || !r %in% rownames(rr)) { out[c, fut] <- last[[c]]; next }
    f <- stats::approx(yr, ratio[r, ], xout = as.integer(fut), rule = 2)$y
    out[c, fut] <- log1p(expm1(last[[c]]) * f)
  }
  out
}

v8AddRents <- function(x, R, exporter = NULL) {
  cty <- magclass::getItems(x, dim = 1); yrs <- magclass::getYears(x, as.integer = TRUE)
  nm <- c("Fossil Rents", "Fossil Rents|Bulk", "Fossil Rents|Diffuse", if (!is.null(exporter)) "Fossil Exporter")
  m <- magclass::new.magpie(cty, yrs, nm, fill = NA)
  for (y in yrs) {
    v <- if (as.character(y) %in% colnames(R)) R[cty, as.character(y)] else rep(NA_real_, length(cty))
    for (n in nm[1:3]) m[, y, n] <- v
    if (!is.null(exporter)) m[, y, "Fossil Exporter"] <- as.numeric(expm1(v) > exporter)
  }
  magclass::mbind(x, m)
}
