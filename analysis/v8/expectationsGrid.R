# The persistence x expectations grid of the NCC paper (design note 0012 sec. 5; NCC claims C1-C5, C8; gate G1, D6).
#   Rscript analysis/v8/expectationsGrid.R [group]   (repo root; default v8) -> output/pfm/<group>/coupling/expectations-grid.rds
# Every chain of scenario-matrix-v8.yml (sections v8_sequential and v8_expectations, start tags V8SEQEU21 / V8EXPEU21 /
# V8EXPH12), hold the price: the extra cumulative CO2 2020-2100 of the chain's last step and of each step's plan, against
# the no-politics hold-the-price reference of its resolution, beside the one-shot run of the same persistence and severity.
# Runs not there yet are NA, so the script can be run as the batch comes back. Reads output/remind-runs/<group>/<res>/.
suppressMessages({ library(gdx); library(magclass) })
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
OUT <- file.path("output/pfm", g, "coupling"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
say <- function(...) message("[expectations-grid:", g, "] ", ...)
PRE <- c(EU21 = "SSP2-EU21-PkBudg1000-PFM-", H12 = "SSP2-PkBudg1000-PFM-")
STEP10 <- c(2030, 2040, 2050, 2060, 2070); STEP5 <- c(2030, 2035, 2040, 2045, 2050, 2055, 2060, 2070)

# the newest folder of a title with a fulldata.gdx; finished when REMIND's log says so
cum2100 <- function(res, title) {
  d <- sort(Sys.glob(file.path("output/remind-runs", g, res, paste0(PRE[[res]], title, "_*"))), decreasing = TRUE)
  d <- d[file.exists(file.path(d, "fulldata.gdx"))]
  if (!length(d)) return(c(cum = NA_real_, finished = NA))
  fin <- any(grepl("Normal completion", readLines(file.path(d[1], "log.txt"), warn = FALSE)))
  cum <- readGDX(file.path(d[1], "fulldata.gdx"), "pm_actualbudgetco2")
  c(cum = as.numeric(cum[, 2100, ]), finished = fin)
}

# family: persistence, expectations, theta, resolution, one-shot title, chain step title, steps
FAM <- list(
  list(id = "fading.chain",     persistence = "fading",          expectations = "lift after each decade", theta = 0.50,  res = "EU21", oneShot = "holdPrice-v8",                 step = function(y) paste0("holdPrice-shrinkingFuture", y, "-v8"), steps = STEP10),
  list(id = "fading.control",   persistence = "fading",          expectations = "re-planned, known to last (control)", theta = 0.50, res = "EU21", oneShot = "holdPrice-v8", step = function(y) paste0("holdPrice-replanned", y, "-v8"), steps = STEP10),
  list(id = "fading.lift20",    persistence = "fading",          expectations = "lift after 20 years",    theta = 0.50,  res = "EU21", oneShot = "holdPrice-v8",                 step = function(y) paste0("holdPrice-lift20y-shrinkingFuture", y, "-v8"), steps = STEP10),
  list(id = "fading.step5",     persistence = "fading",          expectations = "lift after each step (5-year steps)", theta = 0.50, res = "EU21", oneShot = "holdPrice-v8", step = function(y) paste0("holdPrice-step5y-shrinkingFuture", y, "-v8"), steps = STEP5),
  list(id = "constant.chain",   persistence = "constant",        expectations = "lift after each decade", theta = 0.50,  res = "EU21", oneShot = "holdPrice-constantLimit-v8",   step = function(y) paste0("holdPrice-constantLimit-shrinkingFuture", y, "-v8"), steps = STEP10),
  list(id = "erosion.chain",    persistence = "fading + 2.7%/yr", expectations = "lift after each decade", theta = 0.50, res = "EU21", oneShot = "holdPrice-erosion2p7-v8",     step = function(y) paste0("holdPrice-erosion2p7-shrinkingFuture", y, "-v8"), steps = STEP10),
  list(id = "theta325.chain",   persistence = "fading",          expectations = "lift after each decade", theta = 0.325, res = "EU21", oneShot = "holdPrice-theta325-v8",       step = function(y) paste0("holdPrice-theta325-shrinkingFuture", y, "-v8"), steps = STEP10),
  list(id = "theta675.chain",   persistence = "fading",          expectations = "lift after each decade", theta = 0.675, res = "EU21", oneShot = "holdPrice-theta675-v8",       step = function(y) paste0("holdPrice-theta675-shrinkingFuture", y, "-v8"), steps = STEP10),
  list(id = "H12.fading.chain", persistence = "fading",          expectations = "lift after each decade", theta = 0.50,  res = "H12",  oneShot = "holdPrice-v8",                 step = function(y) paste0("holdPrice-shrinkingFuture", y, "-v8"), steps = STEP10))

REF <- lapply(c(EU21 = "EU21", H12 = "H12"), function(r) cum2100(r, "noPolitics-holdPrice-v8"))
rows <- list(); plans <- list()
for (f in FAM) {
  ref <- REF[[f$res]][["cum"]]
  os <- cum2100(f$res, f$oneShot)
  st <- t(vapply(f$steps, function(y) cum2100(f$res, f$step(y)), c(cum = 0, finished = 0)))
  last <- st[nrow(st), ]
  rows[[f$id]] <- data.frame(id = f$id, persistence = f$persistence, expectations = f$expectations, theta = f$theta, res = f$res,
                             oneShotExtra = os[["cum"]] - ref, chainExtra = last[["cum"]] - ref,
                             stepsDone = sum(!is.na(st[, "cum"])), steps = nrow(st), chainFinished = as.logical(last[["finished"]]),
                             stringsAsFactors = FALSE)
  plans[[f$id]] <- data.frame(id = f$id, step = f$steps, planExtra = st[, "cum"] - ref, finished = as.logical(st[, "finished"]))
}
grid <- do.call(rbind, rows); rownames(grid) <- NULL
grid$chainOverOneShot <- grid$chainExtra / grid$oneShotExtra
plans <- do.call(rbind, plans); rownames(plans) <- NULL

# gate G1 (D6, fixed before the results): the control passes the headline if its overshoot is nearer the one-shot result
# than the chain's
ctl <- grid[grid$id == "fading.control", ]; chn <- grid[grid$id == "fading.chain", ]
G1 <- if (is.na(ctl$chainExtra) || !isTRUE(ctl$chainFinished)) list(status = "pending", control = ctl$chainExtra) else {
  dOne <- abs(ctl$chainExtra - chn$oneShotExtra); dChain <- abs(ctl$chainExtra - chn$chainExtra)
  list(status = if (dOne < dChain) "pass: expectation" else "fail: re-planning", control = ctl$chainExtra,
       oneShot = chn$oneShotExtra, chain = chn$chainExtra, distanceToOneShot = dOne, distanceToChain = dChain) }
# the severity equivalence (NCC C3): each chain against the one-shot runs across theta
os <- grid[grid$res == "EU21" & grid$persistence == "fading" & grid$expectations == "lift after each decade", c("theta", "oneShotExtra", "chainExtra")]
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), reference = REF, grid = grid, plans = plans, G1 = G1,
            severityEquivalence = os[order(os$theta), ],
            note = paste("Extra cumulative CO2 2020-2100 (Gt) against the no-politics hold-the-price reference of the same resolution",
                         "(pm_actualbudgetco2); a chain's result is its last step; NA = not run yet. G1: design note 0012 D6."))
saveRDS(out, file.path(OUT, "expectations-grid.rds")); say("wrote ", file.path(OUT, "expectations-grid.rds"))
options(width = 220)
print(grid[, c("id", "theta", "res", "oneShotExtra", "chainExtra", "chainOverOneShot", "stepsDone", "steps", "chainFinished")], digits = 4, row.names = FALSE)
cat("\nG1 (control vs one-shot and chain):", G1$status, "\n")
cat("\nseverity equivalence (fading, EU21):\n"); print(out$severityEquivalence, digits = 4, row.names = FALSE)
