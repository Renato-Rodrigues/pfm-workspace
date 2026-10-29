#!/bin/bash
# The per-sector selection (analysis/v8/perSectorSelection.R) on the cluster: the walk refits each candidate's frontier
# and projects it on two scenarios in its own R process, which ran a workstation out of memory (2026-10-29).
#   cd /p/projects/elevate/WP3.4/pfm-workspace && git pull --ff-only && sbatch analysis/v8/perSectorSelection.sbatch
# Both sectors (pass "v8 Diffuse" in ARGS for one). Log: output/pfm/v8/per-sector-<jobid>.out
# Result: output/pfm/v8/per-sector-selection.rds (copy it back to the workstation's output/pfm/v8/).
#SBATCH --job-name=pfm-per-sector
#SBATCH --qos=priority
#SBATCH --partition=priority
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --chdir=/p/projects/elevate/WP3.4/pfm-workspace
#SBATCH --output=output/pfm/v8/per-sector-%j.out
#SBATCH --error=output/pfm/v8/per-sector-%j.out
set -euo pipefail
ARGS=${ARGS:-"v8 Bulk,Diffuse"}
export PFM_WALK_TIMEOUT_MIN=${PFM_WALK_TIMEOUT_MIN:-30}

# the inputs the walk reads: fail now, not after an hour
for f in output/pfm/v8/sweep.rds output/pfm/v8/manifest.json data/madrat/v8 \
         output/remind-runs/v6/EU21/SSP2-EU21-PkBudg1000_2026-10-07_19.04.46/fulldata.gdx \
         output/remind-runs/v6/EU21/SSP2-EU21-NPi2025_2026-10-07_12.36.43/fulldata.gdx; do
  [ -e "$f" ] || { echo "missing: $f" >&2; exit 2; }
done
Rscript -e 'h <- jsonlite::fromJSON("output/pfm/v8/manifest.json")$panel_hash;
            p <- file.path("output/pfm/fit-cache/panels", paste0("panel_", h, ".rds"));
            if (!file.exists(p)) stop("missing training panel: ", p);
            if (!requireNamespace("callr", quietly = TRUE)) stop("the R package callr is not installed")'

echo "[per-sector] $(date) host $(hostname) args: $ARGS timeout ${PFM_WALK_TIMEOUT_MIN} min"
Rscript analysis/v8/perSectorSelection.R $ARGS
echo "[per-sector] $(date) done"
