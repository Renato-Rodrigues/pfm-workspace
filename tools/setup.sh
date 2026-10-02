#!/usr/bin/env bash
# Create or update a PFM workspace: the model repositories in models/, the data and output
# folders, and (on the cluster) a checkout of the project repo without docs/.
#
#   ./tools/setup.sh                    # workstation: clone what is missing (repos.txt "both" + "local")
#   ./tools/setup.sh --cluster            # cluster: "both" + "cluster" repos; docs/ left out
#   ./tools/setup.sh --cluster --update   # also fetch and fast-forward repos that already exist
#   ./tools/setup.sh --cluster --ref v5-final   # check every repo out at a tag (reproduce a version)
#   ./tools/setup.sh --cluster --install  # then install mrpfm and pfm from models/ into the R library
#   ./tools/setup.sh --group v6           # the Run-Group whose madrat cache to prepare (default: config.yml)
#   ./tools/setup.sh --no-cache           # skip the madrat cache preparation
#   ./tools/setup.sh --dry-run ...        # print what would happen
#
# When pfm is installed, it ends by preparing the project madrat cache (pfm::pfmPrepareCache,
# config.yml `madrat:`): every file the pipeline reads is checked, copied from the configured
# cache sources when missing, and computed from the raw sources when no cache has it.
#
# Run it from anywhere: it moves to the project root (the folder above tools/). It never deletes anything and
# never touches a repository with uncommitted changes. It ends by writing the commit of every
# repository to output/workspace-commits.txt, the record a batch should be quoted against.

set -euo pipefail
cd "$(dirname "$0")/.."    # the project root: this script lives in tools/

MODE=local; UPDATE=0; REF=""; INSTALL=0; DRY=0; CACHE=1; GROUP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --cluster) MODE=cluster ;;
    --update)  UPDATE=1 ;;
    --ref)     REF="$2"; shift ;;
    --install) INSTALL=1 ;;
    --group)   GROUP="$2"; shift ;;
    --no-cache) CACHE=0 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,21p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
run() { if [ "$DRY" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }
say() { echo "[setup] $*"; }

[ -f tools/repos.txt ] || { echo "tools/repos.txt not found" >&2; exit 1; }

# --- 1. folders that are not in git ------------------------------------------------------
for d in data/madrat output/pfm/fit-cache output/remind-inputs output/remind-runs; do
  [ -d "$d" ] || { say "mkdir $d"; run mkdir -p "$d"; }
done

# --- 2. the project repo on the cluster: leave out docs/ -----------------------------------
# (papers/ holds only separate repositories, and those are "local" in repos.txt)
if [ "$MODE" = cluster ] && [ -d .git ]; then
  say "sparse checkout: everything except docs/"
  run git sparse-checkout set --no-cone '/*' '!/docs/'
fi

# --- 3. the model repositories ------------------------------------------------------------
grep -vE '^\s*(#|$)' tools/repos.txt | while read -r name where path url branch; do
  case "$where" in both) ;; "$MODE") ;; *) continue ;; esac
  target="${REF:-$branch}"
  if [ "$url" = "-" ]; then
    if [ -d "$path" ]; then say "$name: present, no remote recorded"; else say "$name: SKIPPED - no remote in repos.txt"; fi
    continue
  fi
  if [ ! -d "$path/.git" ]; then
    if [ -e "$path" ]; then say "$name: $path exists but is not a git checkout - left alone"; continue; fi
    say "$name: clone $url ($target) -> $path"
    run git clone --branch "$branch" "$url" "$path"
    if [ -n "$REF" ]; then run git -C "$path" checkout "$REF"; fi
  elif [ "$UPDATE" = 1 ] || [ -n "$REF" ]; then
    if [ -n "$(git -C "$path" status --porcelain --untracked-files=no)" ]; then
      say "$name: UNCOMMITTED CHANGES - not updated (commit or stash first)"; continue
    fi
    say "$name: fetch, checkout $target"
    run git -C "$path" fetch --tags --quiet origin
    run git -C "$path" checkout --quiet "$target"
    if git -C "$path" symbolic-ref -q HEAD >/dev/null; then run git -C "$path" pull --ff-only --quiet; fi
  else
    say "$name: present ($(git -C "$path" rev-parse --short HEAD) on $(git -C "$path" rev-parse --abbrev-ref HEAD))"
  fi
done

# --- 4. install the R packages from models/ -----------------------------------------------
# Two libraries, because a REMIND checkout sees only its own renv library (renv/library), never
# yours (PITFALLS 23):
#   1. your R library - what pfmRun() and the cache preparation load from the project root;
#   2. each REMIND checkout's renv library - what the coupled runs load.
# mrpfm first: pfm depends on it (mrpfm >= 0.4.0).
#
# R CMD INSTALL, not devtools::install(): devtools resolves the dependencies through `remotes`,
# which fails on packages renv or pak installed ("can't convert package magclass with RemoteType
# 'repository' to remote", the cluster, 2026-10-02). R CMD INSTALL resolves nothing: the
# dependencies must already be in your library (they are on the cluster); a missing one is named
# in its error - install it with install.packages() and re-run.
# Into a REMIND checkout's renv, nothing is downloaded: on the cluster, renv::install() of a
# local mrpfm failed twice while resolving its dependency tree from the repositories
# ("dependency 'mrremind' is not available", then "package 'Deriv' is not available";
# 2026-10-02). Your library already holds the whole working set, so per checkout:
#   a. renv::hydrate() copies mrpfm's and pfm's dependencies from your library (and the site
#      library) into the checkout's renv; packages it already has, such as REMIND's own madrat and
#      magclass, are left alone;
#   b. the copies of mrpfm and pfm that hydrate linked from renv's cache are removed: the cache is
#      keyed by version, and commits land without a version change, so a cached pfm 0.8.0 can be
#      older code than models/pfm;
#   c. R CMD INSTALL -l <renv library> installs them from models/, as real directories. Run from
#      the project root: inside the checkout REMIND's .Rprofile breaks R CMD INSTALL
#      ("could not find function installed.packages").
# The first R start in a freshly cloned checkout bootstraps its renv library (renv::hydrate in
# REMIND's .Rprofile), which takes several minutes.
RENV_DEPS='src <- strsplit(Sys.getenv("PFM_SOURCE_LIBS"), .Platform$path.sep, fixed = TRUE)[[1]]; renv::hydrate(packages = c("mrpfm", "pfm"), sources = src, prompt = FALSE, report = FALSE); lib <- .libPaths()[1]; old <- intersect(c("pfm", "mrpfm"), rownames(utils::installed.packages(lib.loc = lib))); if (length(old)) renv::remove(old, library = lib); cat("RLIB=", lib, "\n", sep = "")'
RENV_CHECK='cat("[setup]", basename(getwd()), "loads pfm", format(packageVersion("pfm")), "| mrpfm", format(packageVersion("mrpfm")), "| mrremind", format(packageVersion("mrremind")), "\n")'
if [ "$INSTALL" = 1 ]; then
  for p in mrpfm pfm; do
    say "install models/$p into your R library"
    run R CMD INSTALL "models/$p" || { say "FAILED: R CMD INSTALL models/$p"; exit 1; }
  done
  # your library and the site library, as a session started here sees them
  LIBS=$(Rscript -e 'cat("LIBS=", paste(.libPaths(), collapse = .Platform$path.sep), "\n", sep = "")' 2>/dev/null \
           | grep "^LIBS=" | sed 's/^LIBS=//; s/ *$//')
  for r in models/remind_pfm*; do
    [ -d "$r" ] || continue
    say "mrpfm and pfm into the renv library of $r"
    if [ "$DRY" = 1 ]; then
      echo "  [dry-run] (cd $r && Rscript -e '<hydrate the dependencies from $LIBS; remove the cached pfm/mrpfm>')"
      echo "  [dry-run] R CMD INSTALL -l <the renv library of $r> models/mrpfm, models/pfm"
      continue
    fi
    RLIB=$(cd "$r" && PFM_SOURCE_LIBS="$LIBS" Rscript -e "$RENV_DEPS" | grep "^RLIB=" | sed 's/^RLIB=//; s/ *$//')
    [ -n "$RLIB" ] || { say "FAILED: renv::hydrate in $r"; exit 1; }
    for p in mrpfm pfm; do
      R CMD INSTALL -l "$RLIB" "models/$p" > /dev/null || { say "FAILED: R CMD INSTALL -l $RLIB models/$p"; exit 1; }
    done
    (cd "$r" && Rscript -e "$RENV_CHECK") || { say "FAILED: pfm does not load in $r"; exit 1; }
  done
  say "check that every library holds the working tree's code:"
  echo "  Rscript -e 'pfm::pfmPreflight(checks = c(\"repos\", \"installed\"))'"
fi

# --- 5. the madrat cache -------------------------------------------------------------------
# The first preparation of the workspace is where a cache is filled; pfmRun() repeats the check
# before every run (a complete cache is confirmed in under a second).
if [ "$CACHE" = 1 ]; then
  if Rscript -e 'quit(status = !requireNamespace("pfm", quietly = TRUE))' >/dev/null 2>&1; then
    say "madrat cache: pfm::pfmPrepareCache(${GROUP:+group = \"$GROUP\"})"
    if [ -n "$GROUP" ]; then garg="group = '$GROUP'"; else garg="group = NULL"; fi
    run Rscript -e "suppressMessages(library(pfm)); r <- pfmPrepareCache('config.yml', $garg); if (r\$status == 'incomplete') quit(status = 1)"       || say "madrat cache INCOMPLETE - see [cache] above; fix config.yml madrat: cacheSources / sourcefolder"
  else
    say "madrat cache: skipped - pfm is not installed (run with --install, or pfmRun() prepares it)"
  fi
fi

# --- 6. record what this workspace is built from -----------------------------------------
if [ "$DRY" = 0 ]; then
  out=output/workspace-commits.txt
  { echo "# $(date -u +%Y-%m-%dT%H:%M:%SZ)  mode=$MODE  ref=${REF:-<branch heads>}"
    if [ -d .git ]; then echo "project  $(git rev-parse HEAD)  $(git rev-parse --abbrev-ref HEAD)"; fi
    for d in models/* papers/*; do
      if [ -d "$d/.git" ] && git -C "$d" rev-parse --git-dir >/dev/null 2>&1; then
        dirty=""
        if [ -n "$(git -C "$d" status --porcelain --untracked-files=no)" ]; then dirty="  DIRTY"; fi
        echo "$d  $(git -C "$d" rev-parse HEAD)  $(git -C "$d" rev-parse --abbrev-ref HEAD)$dirty"
      fi
    done
  } > "$out"
  say "commits recorded in $out"
  cat "$out"
fi
