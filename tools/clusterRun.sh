#!/usr/bin/env bash
# The whole cluster sequence for re-running Run-Groups after a code change, in one call:
# update -> install -> verify -> preflight -> clean what pfmRun's `clean` does not -> submit each group.
#
#   tools/clusterRun.sh --priority v6 --standby v6-annual                     # the usual call
#   tools/clusterRun.sh --priority v6 --standby v6-annual --dry-run           # everything but deleting and submitting
#   tools/clusterRun.sh --priority v6 --require .pfmLagLookup,.pfmHarmoniseScenario
#
# options
#   --priority 'g1 g2'   groups on the priority QOS (auto-sized)            } at least one group in total;
#   --standby  'g3'      groups on qos=standby (sized by prioritySizing)    } names space- or comma-separated
#   --short    'g4'      groups on the default queue
#   --stage s            pfmRun stage(s), comma-separated (default all)
#   --clean c            group | steps | none (default group: every step artifact of the group is removed;
#                        the Fit Cache, panels, boot-cache and madrat cache are never touched)
#   --require 'f1,f2'    pfm functions that must exist after the install - proves the NEW code is installed
#   --standby-partition  partition for standby jobs (default priority)
#   --no-update          skip git pull and setup.sh (code already current and installed)
#   --dry-run            print the plans; delete and submit nothing
#
# Each pfmRun call returns once its job is submitted, so the groups run side by side.
# Read docs/PITFALLS.md sections 1-3 first; docs/RUNNING.md has the procedure this automates.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f config.yml ] || { echo "no config.yml in $(pwd)" >&2; exit 2; }

PRIO=""; STBY=""; SHORT=""; STAGE="all"; CLEAN="group"; REQ=""; SPART="priority"; UPDATE=1; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --priority) PRIO="${2//,/ }"; shift ;;
    --standby) STBY="${2//,/ }"; shift ;;
    --short) SHORT="${2//,/ }"; shift ;;
    --stage) STAGE="$2"; shift ;;
    --clean) CLEAN="$2"; shift ;;
    --require) REQ="$2"; shift ;;
    --standby-partition) SPART="$2"; shift ;;
    --no-update) UPDATE=0 ;;
    --dry-run) DRY=1 ;;
    *) echo "unknown option: $1" >&2; sed -n '2,24p' "$0"; exit 2 ;;
  esac
  shift
done
ALL="$PRIO $STBY $SHORT"
[ -n "${ALL// /}" ] || { echo "no group given (--priority / --standby / --short)" >&2; exit 2; }
dup=$(printf '%s\n' $ALL | sort | uniq -d)
[ -z "$dup" ] || { echo "group(s) on more than one queue: $dup" >&2; exit 2; }
case "$CLEAN" in group|steps|none) ;; *) echo "--clean must be group, steps or none" >&2; exit 2 ;; esac
say() { echo "[clusterRun] $*"; }

# 1. code: the project repo, then every models/* repo fast-forwarded and installed (your library + each
#    REMIND checkout's renv). `git pull` alone does not update models/* (RUNNING.md step 4).
if [ "$UPDATE" = 1 ]; then
  say "updating the project repo"; git pull --ff-only
  say "updating and installing models/*"; ./tools/setup.sh --cluster --update --install --no-cache
fi

# 2. the installed pfm is the new code
if [ -n "$REQ" ]; then
  Rscript -e "f <- strsplit('${REQ}', ',')[[1]]; miss <- f[!vapply(f, exists, logical(1), envir = asNamespace('pfm'))];
              if (length(miss)) stop('installed pfm lacks: ', paste(miss, collapse = ', '), ' - old code installed?');
              cat('[clusterRun] installed pfm', format(packageVersion('pfm')), 'has', length(f), 'required function(s)\n')"
fi

# 3. preflight: repositories clean and pushed, installed code = working tree (fails loudly)
Rscript -e 'invisible(pfm::pfmPreflight(checks = c("repos", "installed")))'

# 4. what pfmRun(clean = ...) leaves: the REMIND export (written outside the Run-Group) and the coupling
#    bound's scenario-panel cache (keyed by name only). Removed only when the run will rebuild them.
if [ "$CLEAN" != "none" ]; then
  for g in $ALL; do
    t=$(ls -d "output/remind-inputs/$g" output/pfm/panel-cache/"$g"-scen-ca*.rds \
            output/pfm/panel-cache/"$g"-SSP*-scen-ca*.rds 2>/dev/null || true)
    if [[ ",$STAGE," != *",all,"* && ",$STAGE," != *",remind,"* ]]; then
      t=$(printf '%s\n' $t | grep -v '^output/remind-inputs/' || true)
    fi
    [ -z "$t" ] && continue
    if [ "$DRY" = 1 ]; then say "would delete: $(echo $t)"; else say "deleting: $(echo $t)"; rm -rf $t; fi
  done
fi

# 5. submit
for g in $PRIO;  do Rscript tools/clusterSubmit.R "$g" priority "$STAGE" "$CLEAN" "$DRY" "$SPART"; done
for g in $STBY;  do Rscript tools/clusterSubmit.R "$g" standby  "$STAGE" "$CLEAN" "$DRY" "$SPART"; done
for g in $SHORT; do Rscript tools/clusterSubmit.R "$g" short    "$STAGE" "$CLEAN" "$DRY" "$SPART"; done

if [ "$DRY" = 1 ]; then say "dry run: nothing deleted or submitted"; else
  say "submitted: $ALL"
  squeue -u "$USER" -o "%.10i %.20j %.9q %.9P %.8T %.10M %R" 2>/dev/null || true
  say "logs: output/pfm/<group>/pfm-<group>-<job>.out (last line DONE / DONE WITH GAPS / FAILED)"
fi
