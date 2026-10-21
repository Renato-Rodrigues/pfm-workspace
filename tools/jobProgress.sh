#!/usr/bin/env bash
# Progress of a running pfm sweep job: share of the fit grid done and the time left at the current rate.
#
#   tools/jobProgress.sh <jobid>          # e.g. tools/jobProgress.sh 2642005
#
# The parallel fit grid logs nothing until it ends, so progress is read from the Fit Cache: every finished fit
# writes one .rds to output/pfm/fit-cache/models. Jobs = specs x 2 sectors (the log's "PFM specs after
# adaptation" line). Fits already in the cache, and failed fits, write no file: the share can stay below 100%
# when the grid is done. The grid has ended when the log prints "... jobs: ... newly fit, ..."; selection and
# the sanity walk follow (v6: 51 min), then the diagnostics. Another job writing to the same Fit Cache at the
# same time inflates the count.
set -euo pipefail
cd "$(dirname "$0")/.."
J="${1:?usage: tools/jobProgress.sh <jobid>}"

info=$(squeue -j "$J" -h -o "%S|%Z|%T|%L" 2>/dev/null || true)
[ -n "$info" ] || { echo "job $J is not in the queue (finished or unknown): sacct -j $J" >&2; exit 1; }
IFS='|' read -r START WORKDIR STATE LEFT <<< "$info"
[ "$STATE" = "RUNNING" ] || { echo "job $J is $STATE (start $START)"; exit 0; }

GROUP=$(basename "$WORKDIR")
LOG="$WORKDIR/pfm-$GROUP-$J.out"
[ -f "$LOG" ] || { echo "no log $LOG" >&2; exit 1; }
MODELS="output/pfm/fit-cache/models"

SPECS=$(grep -m1 -o '[0-9]* PFM specs after adaptation' "$LOG" | cut -d' ' -f1 || true)
[ -n "$SPECS" ] || { echo "job $J ($GROUP): the spec grid is not built yet (no 'PFM specs after adaptation' in $LOG)"; exit 0; }
JOBS=$((2 * SPECS))
NEW=$(find "$MODELS" -maxdepth 1 -name '*.rds' -newermt "$START" | wc -l)
ELAPSED=$(( $(date +%s) - $(date -d "$START" +%s) ))
PCT=$(awk -v n="$NEW" -v t="$JOBS" 'BEGIN { printf "%.1f", 100 * n / t }')
hm() { printf "%dh%02dm" $(($1 / 3600)) $(($1 % 3600 / 60)); }

echo "job $J | group $GROUP | started $START | elapsed $(hm "$ELAPSED") | wall time left $LEFT"
if grep -q 'jobs: .* newly fit' "$LOG"; then
  echo "fit grid DONE: $(grep -m1 -o '[0-9]* jobs: .*' "$LOG")"
  echo "now: $(tail -n 1 "$LOG" | cut -c1-200)"
  exit 0
fi
echo "fit grid: $NEW new fits of $JOBS jobs ($SPECS specs x 2 sectors) = $PCT%"
if [ "$NEW" -gt 0 ]; then
  REST=$(( (JOBS - NEW) * ELAPSED / NEW ))
  echo "at this rate: about $(hm "$REST") more for the fit grid (then selection, sanity walk, diagnostics)"
fi
