# Build the coupled scenario config from a scenario matrix (ADR 0055; design note 0005 F1 / E16).
#
#   Rscript analysis/run-groups/buildPFMScenarioConfig.R [matrix] [remindDir]
#   defaults: analysis/run-groups/scenario-matrix-v6.yml, models/remind_pfm
#
# Writes the matrix's `output` (models/remind_pfm/config/scenario_config_PFM_v6.csv), then runs the
# project validator and REMIND's own reader on it. The CSV is a build artifact: edit the matrix,
# rebuild, commit both (the matrix here, the CSV in the remind_pfm fork). The v5 scaffold this
# replaces is archived (../_archive/_wip/2026-10-07/analysis/run-groups/buildPFMScenarioConfig-v5.R).
a <- commandArgs(trailingOnly = TRUE)
matrix <- if (length(a) >= 1) a[1] else "analysis/run-groups/scenario-matrix-v6.yml"
remindDir <- if (length(a) >= 2) a[2] else "models/remind_pfm"
if (!file.exists(matrix)) stop("no matrix at ", matrix, " - run from the project root")

suppressMessages(library(pfm))
df <- buildPFMScenarioConfig(matrix, remindDir)
out <- attr(df, "path")

# 1. the project validator
v <- system2(file.path(R.home("bin"), "Rscript"),
             c("analysis/run-groups/validatePFMScenarioConfig.R", shQuote(out)), stdout = TRUE, stderr = TRUE)
cat(v, sep = "\n")
if (!is.null(attr(v, "status")) && attr(v, "status") != 0) stop("validatePFMScenarioConfig.R reports errors")

# 2. REMIND's own reader, outside its renv (it needs only base R and the start scripts)
rd <- normalizePath(remindDir, winslash = "/")
code <- sprintf(paste0(
  "setwd('%s'); for (f in c('needBau','readCheckScenarioConfig','path_gdx_list','checkFixCfg')) ",
  "source(file.path('scripts/start', paste0(f, '.R'))); w <- 0L; ",
  "s <- withCallingHandlers(readCheckScenarioConfig('%s', remindPath = '.', testmode = FALSE), ",
  "warning = function(e) { w <<- w + 1L; message('  REMIND: ', conditionMessage(e)); invokeRestart('muffleWarning') }); ",
  "cat('REMIND readCheckScenarioConfig:', nrow(s), 'rows,', w, 'warning(s)\\n'); quit(status = as.integer(w > 0))"),
  rd, normalizePath(out, winslash = "/"))
r <- system2(file.path(R.home("bin"), "Rscript"), c("--no-init-file", "-e", shQuote(code)), stdout = TRUE, stderr = TRUE)
cat(r, sep = "\n")
if (!is.null(attr(r, "status")) && attr(r, "status") != 0) stop("REMIND's reader reports problems")

tags <- table(unlist(strsplit(df$start[nzchar(df$start)], ",")))
cat("\nstart tags:", paste(sprintf("%s (%d)", names(tags), tags), collapse = ", "), "\n")
