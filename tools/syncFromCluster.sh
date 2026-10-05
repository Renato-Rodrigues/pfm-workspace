#!/usr/bin/env bash
# Bring cluster results into this workspace, so the analysis, figures and paper can use them.
#
#   tools/syncFromCluster.sh <ssh-host> <cluster-project-dir> <group> [options]
#
#   <ssh-host>              what `ssh <ssh-host>` connects to, e.g. renato@hpc2024.pik-potsdam.de
#   <cluster-project-dir>   the project folder on the cluster, e.g. /p/projects/elevate/WP3.4
#   <group>                 the Run-Group the batch belongs to, e.g. v6 (runs land in output/remind-runs/<group>/)
#
# options
#   --runs '<glob>'     which REMIND run folders to fetch (default '*'), e.g. 'SSP2-EU21-PkBudg1000-PFM*_2026-11-*'
#   --res 'EU21 H12'    which resolutions (default both); each comes from models/remind_pfm-<res>/output/
#   --estimation        also fetch output/pfm/<group>* (the Run-Group and its variants, e.g. v6-specalt)
#   --panels            also fetch the fitted panels and index of the Fit Cache (output/pfm/fit-cache/{panels,index.json})
#   --dry-run           list what would be fetched, fetch nothing
#
# From each run folder only what the analysis reads is fetched: fulldata.gdx and log.txt
# (analysis/coupled/), plus the small per-run records config.Rdata, pfm-phi-history.rds and
# pfm-coupling.yml (provenance). Copies over ssh + tar, so it needs no rsync. Existing local
# files are overwritten, so re-running after a batch has finished updates it.
#
# Afterwards, from the project root:
#   Rscript analysis/coupled/extractCoupledResults.R output/remind-runs/<group> <group>   # read its flags first
#   then the rest of analysis/coupled/ (analysis/README.md, section 1)

set -euo pipefail
cd "$(dirname "$0")/.."

[ $# -ge 3 ] || { sed -n '2,25p' "$0"; exit 2; }
HOST="$1"; PROJ="$2"; GROUP="$3"; shift 3
RUNS='*'; RES="EU21 H12"; EST=0; PANELS=0; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --runs) RUNS="$2"; shift ;;
    --res) RES="$2"; shift ;;
    --estimation) EST=1 ;;
    --panels) PANELS=1 ;;
    --dry-run) DRY=1 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
KEEP='-name fulldata.gdx -o -name log.txt -o -name config.Rdata -o -name pfm-phi-history.rds -o -name pfm-coupling.yml'

for r in $RES; do
  src="$PROJ/models/remind_pfm-$r/output"
  dst="output/remind-runs/$GROUP/$r"
  echo "[sync] $HOST:$src/$RUNS -> $dst"
  # find prints ./<run>/<file>; the -path test applies the glob to the run folder name only
  list="cd '$src' && find . -mindepth 2 -maxdepth 2 -path './$RUNS/*' \\( $KEEP \\)"
  if [ "$DRY" = 1 ]; then
    ssh "$HOST" "$list" | sed 's#^\./#  #'
  else
    mkdir -p "$dst"
    ssh "$HOST" "$list | tar -cf - -T -" | tar -xf - -C "$dst"
    echo "[sync]   $(find "$dst" -name fulldata.gdx | wc -l) run folders with fulldata.gdx now in $dst"
  fi
done

if [ "$EST" = 1 ]; then
  echo "[sync] $HOST:$PROJ/output/pfm/$GROUP* -> output/pfm/"
  if [ "$DRY" = 1 ]; then ssh "$HOST" "cd '$PROJ/output/pfm' && ls -d $GROUP*"
  else mkdir -p output/pfm; ssh "$HOST" "cd '$PROJ/output/pfm' && tar -cf - $GROUP*" | tar -xf - -C output/pfm; fi
fi

if [ "$PANELS" = 1 ]; then
  echo "[sync] $HOST:$PROJ/output/pfm/fit-cache/{panels,index.json} -> output/pfm/fit-cache/"
  if [ "$DRY" = 1 ]; then ssh "$HOST" "cd '$PROJ/output/pfm/fit-cache' && ls panels index.json"
  else mkdir -p output/pfm/fit-cache; ssh "$HOST" "cd '$PROJ/output/pfm/fit-cache' && tar -cf - panels index.json" | tar -xf - -C output/pfm/fit-cache; fi
fi
