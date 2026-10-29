# First read of Run-Group v8 against v7 (design note 0009 section 17), from the synced artifacts only (no refit).
#   Rscript analysis/v8/checkV8.R   (repo root) -> printed report
options(width = 200)
`%||%` <- function(a, b) if (is.null(a)) b else a
V <- c("v7", "v8"); P <- function(g, f) file.path("output/pfm", g, f)
sel <- lapply(V, function(g) yaml::read_yaml(P(g, "selected-models-pfm.yml"))); names(sel) <- V
cat("== selected\n"); for (g in V) cat(g, ":", sel[[g]][[1]]$name, "| fossilFloor", sel[[g]][[1]]$fossilFloor %||% "-",
                                     "| slackDrivers", paste(unlist(sel[[g]][[1]]$slackDrivers), collapse = ","), "\n")

# why not v7's own form (satInn) with the bound: the sanity walk's verdicts
sw <- readRDS(P("v8", "sweep.rds")); tr <- sw$sanity$PolicyStringency$trace; fl <- sw$sanity$PolicyStringency$flags
mm <- sw$maximin$PolicyStringency
cat("\n== sanity walk (v8): order of the walk, verdicts\n")
print(utils::head(tr[, intersect(c("model", "nSevere", "nWarning", "pass"), names(tr))], 12), row.names = FALSE)
v7form <- grep("^X-1791 .*fe:OECDp satInn iw:fexp fos5$", names(fl), value = TRUE)
for (m in v7form) { f <- fl[[m]]; if (is.data.frame(f)) { cat("\nsevere flags of", m, ":\n"); print(f[f$severity == "severe", intersect(c("check", "sector", "value", "detail"), names(f))], row.names = FALSE) } }
r <- mm[mm$model %in% c(sel$v8[[1]]$name, v7form), intersect(c("model", "rank", "gatePass", "gateFailReason", "meanDeltaR2"), names(mm))]
cat("\nmaximin rows:\n"); print(r, row.names = FALSE)

# the frontier: fossil terms, the slack, gamma
cat("\n== frontier\n")
for (g in V) { fr <- readRDS(P(g, "frontier.rds"))$bySector
  for (s in names(fr)) { ct <- fr[[s]]$coefTable
    k <- ct$term %in% c("Incumbent.Power", "Incumbent.Power.pc", "Innovator.Power") | startsWith(ct$term, "slack_")
    cat(sprintf("%s %-7s gamma %.4f | %s\n", g, s, fr[[s]]$gamma,
                paste(sprintf("%s %+.3f (z %.1f)", ct$term[k], ct$estimate[k], ct$zValue[k]), collapse = "; "))) } }

# country E 2023: the extremes, and the exporters
cat("\n== share of the ceiling used, 2023\n")
E <- lapply(V, function(g) { fr <- readRDS(P(g, "frontier.rds"))$bySector
  do.call(rbind, lapply(names(fr), function(s) { x <- fr[[s]]$scores; x <- x[x$year == 2023, c("region", "efficiencyRatio")]; x$sector <- s; x$group <- g; x })) })
E <- do.call(rbind, E)
w <- reshape(E, idvar = c("sector", "region"), timevar = "group", direction = "wide"); names(w) <- sub("efficiencyRatio.", "E_", names(w))
for (s in c("Bulk", "Diffuse")) { x <- w[w$sector == s, ]
  cat(s, ": rank correlation v7-v8", round(stats::cor(x$E_v7, x$E_v8, method = "spearman", use = "complete.obs"), 3), "\n")
  print(x[x$region %in% c("ISL", "IDN", "PER", "ARG", "RUS", "SAU", "NOR", "CHN", "IND", "USA", "DEU"), ], digits = 2, row.names = FALSE) }

# the regional ranking u (the anchor of each group)
cat("\n== regional ranking u (EU21 anchor)\n")
# the anchor of the REMIND export, or the group's own copy (output/pfm/<g>/phi-anchor.rds)
ancOf <- function(g) { d <- file.path("output/remind-inputs", g); pfm:::pfmAnchorFor(if (dir.exists(d)) d else P(g, "phi-anchor.rds"), "EU21") }
U <- lapply(V, function(g) cbind(group = g, ancOf(g)$region[, c("sector", "region", "u", "shareObserved")]))
if (TRUE) {
  U <- do.call(rbind, U); u <- reshape(U[, c("group", "sector", "region", "u")], idvar = c("sector", "region"), timevar = "group", direction = "wide")
  for (s in c("Bulk", "Diffuse")) { x <- u[u$sector == s, ]; cat(s, ": rank correlation", round(stats::cor(x$u.v7, x$u.v8, method = "spearman"), 3), "\n")
    print(x[order(-x$u.v8), ], digits = 2, row.names = FALSE) }
} else cat("output/remind-inputs/v8 not on this machine: copy it (Step 6d.6)\n")

# coverage
a <- readRDS(P("v8", "donor-assignment-band-Bulk.rds")); cat("\n== coverage rule (P&I):", paste(names(table(a$basis)), table(a$basis), collapse = " "), "\n")

# inference: the theory terms under the wild bootstrap
inf <- tryCatch(readRDS(P("v8", "inference.rds")), error = function(e) NULL)
if (!is.null(inf)) { cat("\n== inference (v8)\n"); str(inf, max.level = 1) }
sb <- tryCatch(readRDS(P("v8", "selection-bootstrap.rds")), error = function(e) NULL)
if (!is.null(sb)) { cat("\n== selection bootstrap (v8)\n"); str(sb, max.level = 1) }
