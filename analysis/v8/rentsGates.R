# v8 test 1 (design note 0009 section 5): fossil rents through the selection's gates, offline, on the v7 panel.
#   Rscript analysis/v8/rentsGates.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-rents-gates.rds
# Variants of the selected specification, both sectors:
#   v7      the selected specification;
#   A_add   rents a fourth actor-power term (main effect + the three weighted institution interactions);
#   B_swap  rents in place of fossil energy per person;
#   C_ctl   rents a control (main effect only, no interaction): log(1 + rents, % of GDP);
#   D_exp   an exporter control: rents above 5% of GDP (dummy; Saudi Arabia, Russia, Norway in the sample).
# Gates as the sweep applies them (config.yml group v7): H1-H2 on the mean regression's coefficient table
# (.pfmTheoryScreen; asymptotic clustered p, the wild bootstrap is not rerun), and on the frontier: gamma <= 0.999,
# H3 coherence >= 0.75 and the edge-of-data gate (.pfmCeilingTrajectory, the sanity walk's own call) on the
# scenario panel of the coupled hold-the-price headline run (EU21, PkBudg1000), with the rents after 2023 either
# held at 2023 or linked to the run's REMIND rents (analysis/v8/_rents.R). Also: BIC, the rents terms, every covered
# country's E in 2023 and a covered-countries regional u (EU21).
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
source("analysis/v8/_rents.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
# the edge gate and the coupling weights read final energy through madrat: without the group's cache the edge gate
# finds no weights and passes without testing anything
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
local({ pd <- pfm:::.pfmPanelDefForGroup(file.path("output/pfm", g), pfmResolveConfig("config.yml", group = g, verbose = FALSE)$panel)   # the IEA edition: the cache key
  options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability"), names(pd))]) })
GD <- file.path("output/pfm", g)
FOCUS <- c("SAU", "RUS", "NOR", "IDN", "CAN", "AUS", "MEX", "COL", "ARG", "PER", "ISL", "USA", "CHN")
EXPORTER <- 5
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
gate <- rc$sweep$edgeGate; tg <- utils::modifyList(pfm:::.pfmTheoryGateDefaults(), rc$sweep$theoryGate %||% list())
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, ".rds"))); gdx <- attr(scen, "gdx")
map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv")
rmap <- stats::setNames(map$RegionCode, map$CountryCode)

cache <- file.path(GD, "v8-wdi-rents.rds")
Rh <- v8RentsHistory(getItems(panel, dim = 1), getYears(panel, as.integer = TRUE), cache)
panelR <- v8AddRents(panel, Rh, EXPORTER)
sc <- getItems(scen, dim = 1); sy <- getYears(scen, as.integer = TRUE)
RhS <- v8RentsHistory(sc, 1995:2023, cache)
scenR <- list(held = v8AddRents(scen, v8RentsScenario(RhS, gdx, rmap, sy, link = FALSE), EXPORTER),
              linked = v8AddRents(scen, v8RentsScenario(RhS, gdx, rmap, sy, link = TRUE), EXPORTER))

sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
swapPc <- function(v) replace(v, v == "Incumbent Power pc", "Fossil Rents")
VARIANTS <- list(
  v7 = function(c) c,
  A_add = function(c) { c$actorPowerDrivers <- c(c$actorPowerDrivers, "Fossil Rents"); c$actorPowerIndex <- c(c$actorPowerIndex, "Fossil Rents"); c },
  B_swap = function(c) { c$actorPowerDrivers <- swapPc(c$actorPowerDrivers); c$actorPowerIndex <- swapPc(c$actorPowerIndex); c },
  C_ctl = function(c) { c$controlDrivers <- c(c$controlDrivers, "Fossil Rents"); c },
  D_exp = function(c) { c$controlDrivers <- c(c$controlDrivers, "Fossil Exporter"); c })
cfgOf <- function(sec, vn) { c <- VARIANTS[[vn]](norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]))
  c$name <- vn; c }
fit <- function(sec, vn, est) suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel,
  c(list(data = panelR, sector = sec, estimator = est, indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfgOf(sec, vn))))))
anc <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21"); w <- anc$weights
RENT <- "Fossil.Rents|Fossil.Exporter"

coefs <- list(); rows <- list(); terms <- list(); E <- list(); U <- list()
for (sec in c("Bulk", "Diffuse")) for (vn in names(VARIANTS)) {
  message("[v8 rents gates] ", sec, " ", vn)
  mf <- fit(sec, vn, "satP"); ff <- fit(sec, vn, "frontier")
  ct <- as.data.frame(unclass(mf$coeftest)); names(ct) <- c("estimate", "stdError", "zValue", "pValue")
  coefs[[length(coefs) + 1]] <- cbind(ct, term = rownames(mf$coeftest), model = vn, sector = sec, row.names = NULL)
  tr <- lapply(scenR, function(s) suppressWarnings(suppressMessages(
    pfm:::.pfmCeilingTrajectory(cfgOf(sec, vn), sec, panelR, s, modelDir = NULL, indexMax = 10, edgeGate = gate))))
  ll <- as.numeric(stats::logLik(ff$model)); k <- nrow(ff$coeftest)
  rows[[length(rows) + 1]] <- data.frame(sector = sec, variant = vn, logLik = ll, BIC = -2 * ll + k * log(nrow(ff$frontier)),
    gamma = tr$held$gamma, gammaPass = tr$held$gamma <= 0.999, H3 = tr$held$coherence$share, H3pass = tr$held$coherence$share >= tg$coherence,
    edgeHeld = tr$held$edge$pass, edgeLinked = tr$linked$edge$pass, ceilRatioHeld = tr$held$ratio, ceilRatioLinked = tr$linked$ratio,
    edgeHeldDetail = tr$held$edge$detail, edgeLinkedDetail = tr$linked$edge$detail, meanR2 = tryCatch(1 - stats::deviance(mf$model) / mf$model$null.deviance, error = function(e) NA_real_))
  fc <- ff$coeftest; kk <- grep(RENT, rownames(fc), value = TRUE)
  if (length(kk)) terms[[length(terms) + 1]] <- data.frame(sector = sec, variant = vn, term = kk, frontier = fc[kk, 1], frontierP = fc[kk, 4],
                                                          mean = mf$coeftest[kk, 1], meanP = mf$coeftest[kk, 4], row.names = NULL)
  s <- ff$frontier; e <- s[s$year == 2023, c("region", "efficiencyRatio")]
  E[[length(E) + 1]] <- cbind(sector = sec, variant = vn, e)
  e$r <- rmap[e$region]; e$w <- w[e$region]
  rg <- stats::aggregate(cbind(gw = (1 - efficiencyRatio) * w, w) ~ r, e, sum); rg$g <- rg$gw / rg$w
  U[[length(U) + 1]] <- data.frame(sector = sec, variant = vn, region = rg$r, u = (rg$g - min(rg$g)) / (max(rg$g) - min(rg$g)))
}
coefs <- do.call(rbind, coefs); rows <- do.call(rbind, rows); terms <- do.call(rbind, terms); E <- do.call(rbind, E); U <- do.call(rbind, U)
th <- pfm:::.pfmTheoryScreen(coefs, names(VARIANTS), c("Bulk", "Diffuse"), tg)
gates <- do.call(rbind, lapply(names(VARIANTS), function(vn) { r <- rows[rows$variant == vn, ]
  data.frame(variant = vn, H1H2 = th$pass[th$model == vn], gamma = all(r$gammaPass), H3 = all(r$H3pass),
             edgeHeld = all(r$edgeHeld %in% TRUE), edgeLinked = all(r$edgeLinked %in% TRUE),
             BIC = sum(r$BIC), theoryReason = th$reason[th$model == vn]) }))
gates$allPass <- with(gates, H1H2 & gamma & H3 & edgeHeld & edgeLinked)
remind <- v8RentsREMIND(gdx)
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), exporterThreshold = EXPORTER, gdx = gdx,
             gates = gates, bySector = rows, theory = th, terms = terms, E = E, U = U, remindRents = remind),
        file.path(GD, "v8-rents-gates.rds"))

options(width = 250)
cat("\n=== gates (both sectors) ===\n"); print(gates, row.names = FALSE)
cat("\n=== per sector ===\n"); print(rows[, setdiff(names(rows), c("edgeHeldDetail", "edgeLinkedDetail"))], digits = 4, row.names = FALSE)
cat("\nedge detail:\n"); for (i in seq_len(nrow(rows))) cat(rows$sector[i], rows$variant[i], "| held:", rows$edgeHeldDetail[i], "| linked:", rows$edgeLinkedDetail[i], "\n")
cat("\n=== rents terms ===\n"); print(terms, digits = 3, row.names = FALSE)
for (sec in c("Bulk", "Diffuse")) {
  e <- reshape(E[E$sector == sec, c("variant", "region", "efficiencyRatio")], idvar = "region", timevar = "variant", direction = "wide")
  names(e) <- sub("efficiencyRatio.", "E_", names(e), fixed = TRUE); cat("\n", sec, "E 2023\n"); print(e[e$region %in% FOCUS, ], digits = 2, row.names = FALSE)
  u <- reshape(U[U$sector == sec, c("variant", "region", "u")], idvar = "region", timevar = "variant", direction = "wide")
  names(u) <- sub("u.", "u_", names(u), fixed = TRUE); print(u[order(-u$u_v7), ][1:8, ], digits = 2, row.names = FALSE)
}
