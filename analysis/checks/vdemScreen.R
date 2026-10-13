# Screen of V-Dem indicators for the frontier's institutional channels and the interaction weight (design note 0007).
#   Rscript analysis/checks/vdemScreen.R [group]        (repo root; default v6; after edgeGateValidation.R, whose
#   scenario panel output/pfm/<group>/coupling/scen-PFMlevelBfix-<group>-democracy.rds it reads)
#
# Candidates are declared below with a role, before any result is read:
#   acc  replaces vertical accountability in the selected specification (an accountability / democracy channel)
#   cap  replaces state capability (WGI government effectiveness): quality of administration and corruption
#   pe   replaces vertical accountability: the political economy of distribution (clientelism, particularism,
#        programmatic parties), which the rentier-state argument (0007 section 7) points to
#   w    a 0-1 index used as the interaction weight (interactionWeight), the selected channels unchanged
# Each variant is the selected specification with that one change, refitted as a frontier on the group's training
# panel and scored by the sanity walk's ceiling trajectory with the edge-of-data gate at its defaults, on the coupled
# hold-the-price energy system. Per candidate it also reports where the sample's autocracies sit (standard deviations
# on the sample) and its correlation with the current channels and income (sample, 2023).
# Indicator values: V-Dem v16 core, country-year, a centred 5-year moving average like the panel's (shortened at the
# ends), held at the last panel year in the scenario. "Bad when high" indicators keep their scale (the sign of the
# coefficient is read accordingly; standardisation makes the fit invariant to it).
# Writes output/pfm/<group>/vdem-screen.rds and prints the table.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v6"
GD <- file.path("output/pfm", g)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE)
say <- function(...) message("[vdem-screen:", g, "] ", ...)

CAND <- rbind(
  data.frame(code = c("v2x_accountability", "v2x_horacc", "v2x_diagacc", "v2xel_frefair", "v2x_jucon", "v2xlg_legcon",
                      "v2xcs_ccsi", "v2x_freexp_altinf", "v2x_civlib", "v2x_liberal", "v2xcl_rol", "v2x_polyarchy"),
             role = "acc"),
  data.frame(code = c("v2clrspct", "v2x_pubcorr", "v2x_corr", "v2x_execorr", "v2x_neopat"), role = "cap"),
  data.frame(code = c("v2xnp_client", "v2dlencmps", "v2psprlnks", "v2dlunivl", "v2xpe_exlecon", "v2xps_party", "v2xeg_eqdr"),
             role = "pe"),
  data.frame(code = c("v2x_polyarchy", "v2x_libdem", "v2xel_frefair", "v2x_freexp_altinf", "v2x_civlib", "v2x_partipdem",
                      "v2x_regime"), role = "w"),
  stringsAsFactors = FALSE)

# ---- the indicators as panel variables -------------------------------------------------------------------
vd <- data.table::fread(Sys.glob("C:/_data/work/remind_input_data/sources/VDem/V-Dem-CY-Core-v*.csv")[1],
                        select = c("country_text_id", "year", unique(CAND$code)))
panel <- loadTrainingPanel(jsonlite::read_json(file.path(GD, "manifest.json"))$panel_hash, rc$modelDir %||% "output/pfm/fit-cache")
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, "-democracy.rds")))
cty <- getItems(panel, 1); yrsP <- getYears(panel, as.integer = TRUE); yrsS <- getYears(scen, as.integer = TRUE)
label <- function(code) paste0(code, " (VDem)")
ma5 <- function(v, yrs) sapply(yrs, function(t) mean(v[abs(as.integer(names(v)) - t) <= 2], na.rm = TRUE))
addVars <- list(); addScen <- list()
for (code in unique(CAND$code)) {
  x <- vd[, c("country_text_id", "year", code), with = FALSE]; names(x)[3] <- "v"
  if (code == "v2x_regime") x$v <- x$v / 3                                   # 0-3 regime class onto 0-1
  mp <- magclass::new.magpie(cty, yrsP, label(code), fill = NA)
  ms <- magclass::new.magpie(getItems(scen, 1), yrsS, label(code), fill = NA)
  for (cc in intersect(cty, unique(x$country_text_id))) {
    xc <- x[x$country_text_id == cc & x$year >= min(yrsP) - 2 & x$year <= max(yrsP) + 2, ]
    v <- stats::setNames(xc$v, xc$year)
    s <- ma5(v, yrsP); mp[cc, , ] <- s
    if (cc %in% getItems(scen, 1)) ms[cc, , ] <- s[length(s)]                  # held at the last panel year
  }
  # countries without V-Dem data: the sample median (as toolImputeMedians does in the panel)
  med <- stats::median(as.vector(mp[, max(yrsP), ]), na.rm = TRUE)
  mp[is.na(mp)] <- med; ms[is.na(ms)] <- med
  addVars[[code]] <- mp; addScen[[code]] <- ms
}
panel <- mbind(panel, do.call(mbind, addVars)); scen <- mbind(scen, do.call(mbind, addScen))
if (!"Electoral Democracy (VDem)" %in% getNames(panel)) panel <- mbind(panel, setNames(addVars[["v2x_polyarchy"]], "Electoral Democracy (VDem)"))

# ---- position and overlap (sample, 2023) -----------------------------------------------------------------
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
cfg0 <- function(sec) Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
samp <- unique(as.character(readRDS(file.path(GD, "frontier.rds"))$bySector$Bulk$scores$region))
y23 <- max(yrsP)
val <- function(nm) stats::setNames(as.vector(panel[samp, y23, nm]), samp)
ref <- list(VA = val("Vertical Accountability (VDem)"), GE = val("Government Effectiveness (WGI)"),
            RoL = val("Rule of Law (VDem)"), GDPpc = log(val("GDP per Capita")))
position <- do.call(rbind, lapply(unique(CAND$code), function(code) {
  v <- val(label(code)); z <- (v - mean(v)) / stats::sd(v)
  nb <- sum(abs(z[setdiff(samp, c("CHN", "SAU"))] - z[["CHN"]]) <= 1)
  data.frame(code = code, zCHN = z[["CHN"]], zSAU = z[["SAU"]], zRUS = z[["RUS"]], zTUR = z[["TUR"]],
             neighboursCHN = nb, corVA = stats::cor(v, ref$VA), corGE = stats::cor(v, ref$GE),
             corRoL = stats::cor(v, ref$RoL), corGDPpc = stats::cor(v, ref$GDPpc))
}))

# ---- the variants ------------------------------------------------------------------------------------------
gate <- pfm:::.pfmEdgeGateDefaults()
run <- function(sec, cfg, lab, code, role) {
  ct <- tryCatch(pfm:::.pfmCeilingTrajectory(cfg, sec, panel, scen, modelDir = NULL, indexMax = 10, edgeGate = gate),
                 error = function(e) { say(lab, " ", sec, " failed: ", conditionMessage(e)); NULL })
  if (is.null(ct)) return(NULL)
  xn <- make.names(label(code)); b <- ct$beta; se <- ct$se
  zOf <- function(t) if (!is.null(se) && t %in% names(se) && se[[t]] > 0) b[[t]] / se[[t]] else NA_real_
  data.frame(variant = lab, code = code, role = role, sector = sec, logLik = ct$logLik, gamma = ct$gamma,
             ceilingRatio = ct$ratio, gatePass = isTRUE(ct$edge$pass), capShift = ct$edge$capShift,
             against = if (is.null(ct$edge$against)) "" else paste(unique(ct$edge$against$region), collapse = " "),
             betaX = if (xn %in% names(b)) b[[xn]] else NA_real_, zX = zOf(xn),
             betaFossilX = { t <- paste0("Incumbent.Power_x_", xn); if (t %in% names(b)) b[[t]] else NA_real_ },
             stringsAsFactors = FALSE)
}
rows <- list()
for (sec in c("Bulk", "Diffuse")) {
  c0 <- cfg0(sec)
  rows[[length(rows) + 1]] <- run(sec, c0, "v6 as selected", NA, "base")
  cw <- c0; cw$interactionWeight <- "Electoral Democracy (VDem)"
  rows[[length(rows) + 1]] <- run(sec, cw, "weight: electoral democracy (iw:poly)", "v2x_polyarchy", "base")
  for (i in seq_len(nrow(CAND))) {
    code <- CAND$code[i]; role <- CAND$role[i]; cf <- c0
    inst <- unlist(cf$instQualityDrivers)
    if (role %in% c("acc", "pe")) { cf$instQualityDrivers <- c(setdiff(inst, "Vertical Accountability (VDem)"), label(code)); lab <- paste("replace accountability:", code) }
    if (role == "cap") { cf$instQualityDrivers <- c(setdiff(inst, "Government Effectiveness (WGI)"), label(code)); lab <- paste("replace state capability:", code) }
    if (role == "w") { if (code == "v2x_polyarchy") next; cf$interactionWeight <- label(code); lab <- paste("weight:", code) }
    say(sec, " ", lab)
    rows[[length(rows) + 1]] <- run(sec, cf, lab, code, role)
  }
}
res <- do.call(rbind, rows)
base <- res[res$variant == "v6 as selected", c("sector", "logLik")]; names(base)[2] <- "logLik0"
res <- merge(res, base, by = "sector"); res$dLogLik <- res$logLik - res$logLik0
# a variant passes when both sectors pass the gate
both <- aggregate(gatePass ~ variant, res, all); names(both)[2] <- "passBoth"
res <- merge(res, both, by = "variant")
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), candidates = CAND, position = position,
             results = res, gate = gate), file.path(GD, "vdem-screen.rds"))

options(width = 250)
cat("\n== Where the sample's autocracies sit (SD on the 48-country sample, 2023) and overlap with current channels\n")
print(position[order(position$zCHN), ], row.names = FALSE, digits = 2)
cat("\n== Variants: change in log-likelihood vs the selected spec, gamma, edge gate (both sectors), the candidate's coefficient\n")
w <- reshape(res[, c("variant", "role", "sector", "dLogLik", "gamma", "gatePass", "capShift", "against", "betaX", "zX", "passBoth")],
             idvar = c("variant", "role", "passBoth"), timevar = "sector", direction = "wide")
print(w[order(-w$passBoth, w$role, -(w$dLogLik.Bulk + w$dLogLik.Diffuse)), ], row.names = FALSE, digits = 3)
