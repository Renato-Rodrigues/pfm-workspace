#!/usr/bin/env bash
# Stage REMIND run results for a manual copy to the workstation (WinSCP etc.), ON THE CLUSTER.
# The counterpart of tools/syncFromCluster.sh for when the workstation cannot reach the cluster.
#
#   tools/stageRunsForCopy.sh <group> [--res 'EU21 H12'] [--runs '<glob>'] [--dry-run]
#   e.g. tools/stageRunsForCopy.sh v6 --res EU21 --runs 'SSP2-EU21-*_2026-10-0[78]_*'
#
# From each FINISHED run folder (one with fulldata.gdx) of models/remind_pfm-<res>/output/ matching
# --runs (default '*'), it copies only what the analysis reads - the same files syncFromCluster.sh
# fetches: fulldata.gdx, log.txt, config.Rdata, pfm-phi-history.rds, pfm-coupling.yml (subfolders such
# as pfm/ kept) - into
#   output/remind-runs/<group>/<res>/<run folder>/
# which is exactly where the workstation expects them. Then copy output/remind-runs/<group>/ with WinSCP
# to <workstation project>/output/remind-runs/<group>/ (about 70 MB a run). Run from the project root.
# Existing staged files are overwritten; nothing in the run folders is touched.
set -euo pipefail
say() { echo "[stage] $*"; }
[ $# -ge 1 ] || { echo "usage: tools/stageRunsForCopy.sh <group> [--res 'EU21 H12'] [--runs '<glob>'] [--dry-run]"; exit 1; }
GROUP="$1"; shift
RES="EU21 H12"; RUNS='*'; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --res)     RES="$2"; shift ;;
    --runs)    RUNS="$2"; shift ;;
    --dry-run) DRY=1 ;;
    *) echo "unknown option $1"; exit 1 ;;
  esac
  shift
done
[ -d models ] && [ -d output ] || { echo "run from the project root (models/ and output/ not found here)"; exit 1; }

total=0
for res in $RES; do
  src="models/remind_pfm-$res/output"
  [ -d "$src" ] || { say "$src not found - skipped"; continue; }
  dst="output/remind-runs/$GROUP/$res"
  n=0
  for run in "$src"/$RUNS; do
    [ -d "$run" ] || continue
    name=$(basename "$run")
    if [ ! -f "$run/fulldata.gdx" ]; then say "$res: $name has no fulldata.gdx (not finished) - skipped"; continue; fi
    files=$(cd "$run" && find . -maxdepth 2 -type f \( -name fulldata.gdx -o -name log.txt -o -name config.Rdata \
              -o -name pfm-phi-history.rds -o -name pfm-coupling.yml \) | sed 's|^\./||' | sort)
    size=$(cd "$run" && du -ch $files 2>/dev/null | tail -1 | cut -f1)
    say "$res: $name  ($(echo "$files" | wc -l) files, $size): $(echo $files)"
    if [ "$DRY" = 0 ]; then
      mkdir -p "$dst/$name"
      (cd "$run" && cp --parents $files "$OLDPWD/$dst/$name/")
    fi
    n=$((n + 1))
  done
  total=$((total + n))
  [ "$n" -gt 0 ] && say "$res: $n run(s) staged in $dst"
done
[ "$DRY" = 1 ] && say "dry run - nothing copied"
say "$total run(s). Copy output/remind-runs/$GROUP/ to the workstation's output/remind-runs/$GROUP/"
[ "$DRY" = 0 ] && du -sh "output/remind-runs/$GROUP" 2>/dev/null | sed 's/^/[stage] total /' || true
