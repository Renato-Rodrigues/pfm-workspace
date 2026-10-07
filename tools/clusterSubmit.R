# Submit one Run-Group's pipeline on a chosen SLURM queue. Called by tools/clusterRun.sh, once per group;
# usable alone from the project root:
#   Rscript tools/clusterSubmit.R <group> <priority|standby|short> [stage,stage] [clean] [dry 0|1] [standbyPartition]
#   Rscript tools/clusterSubmit.R v6-annual standby all group 1          # dry run: prints the plan only
# priority: pfmRun's own priority QOS, auto-sized to the allowance (ADR 0031).
# standby : qos=standby on `standbyPartition` (default "priority"), sized by prioritySizing() for that QOS.
# short   : the default queue.
`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a
a <- commandArgs(trailingOnly = TRUE)
if (length(a) < 2) stop("usage: Rscript tools/clusterSubmit.R <group> <priority|standby|short> [stages] [clean] [dry] [standbyPartition]")
group <- a[1]
queue <- match.arg(a[2], c("priority", "standby", "short"))
stage <- strsplit(a[3] %||% "all", ",")[[1]]
clean <- a[4] %||% "group"
dry   <- identical(a[5] %||% "0", "1")
sPart <- a[6] %||% "priority"
if (!file.exists("config.yml")) stop("run from the project root (no config.yml in ", getwd(), ")")
# pfmRun(cluster = "slurm") without sbatch silently runs the whole pipeline in THIS session
if (!dry && !nzchar(Sys.which("sbatch"))) stop("sbatch not on PATH - refusing (pfmRun would run locally)", call. = FALSE)

suppressMessages(library(pfm))
args <- list(group = group, stage = stage, cluster = "slurm", config = "config.yml",
             clean = clean, dryRun = dry, ask = FALSE)
if (queue == "priority") {
  args$priority <- TRUE
} else if (queue == "short") {
  args$priority <- FALSE
} else {
  sz <- prioritySizing(qos = "standby", partition = sPart)
  message("[clusterSubmit] ", group, " standby sizing: ", sz$detail)
  if (!isTRUE(sz$partitionOk)) {
    stop("no partition confirmed to allow qos=standby (asked for '", sPart, "'). Check:\n",
         "  scontrol show partition | grep -iE 'PartitionName|AllowQos'", call. = FALSE)
  }
  args <- c(args, list(priority = FALSE, qos = "standby", partition = sz$partition,
                       mem = sz$mem, time = sz$time, nCores = sz$nCores))
}
message("[clusterSubmit] ", group, " -> ", queue, " | stage ", paste(stage, collapse = ","),
        " | clean ", clean, if (dry) " | DRY RUN" else "")
invisible(do.call(pfmRun, args))
