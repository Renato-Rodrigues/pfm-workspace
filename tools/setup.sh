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
# REMIND rewrites core/sets.gms for its region mapping whenever a run is prepared (the committed file
# holds the H12 sets), so an EU21 checkout is "dirty" after every batch. In a remind_pfm* checkout the
# file is therefore marked skip-worktree: git ignores REMIND's version, `git status` stays clean (this
# update, pfmPreflight's repos check) and the file is never restored. Only when the commit being
# checked out itself changes core/sets.gms (a REMIND version merge) is the flag lifted and the
# committed file taken - REMIND regenerates it at its next start. PITFALLS.md section 36.
# renv/activate.R is treated the same way: the checkout's renv (1.1.7) rewrites the committed 3.7.1
# script (renv 1.2.4) to its own version at every R start in the checkout, so EU21 was dirty after each
# submission and the next submitPFM() was refused (2026-10-08).
REMIND_GENERATED="core/sets.gms renv/activate.R"
isRemind() { case "$1" in remind_pfm*) return 0 ;; *) return 1 ;; esac; }
markGenerated() { for f in $REMIND_GENERATED; do run git -C "$1" update-index --skip-worktree "$f"; done; }
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
    if isRemind "$name"; then markGenerated "$path"; fi
  elif [ "$UPDATE" = 1 ] || [ -n "$REF" ]; then
    if isRemind "$name"; then markGenerated "$path"; fi
    if [ -n "$(git -C "$path" status --porcelain --untracked-files=no)" ]; then
      say "$name: UNCOMMITTED CHANGES - not updated (commit or stash first)"; continue
    fi
    say "$name: fetch, checkout $target"
    run git -C "$path" fetch --tags --quiet origin
    if isRemind "$name"; then
      cmp="origin/$target"; git -C "$path" rev-parse -q --verify "$cmp" >/dev/null || cmp="$target"
      for f in $REMIND_GENERATED; do
        if ! git -C "$path" diff --quiet HEAD "$cmp" -- "$f" 2>/dev/null; then
          say "$name: $f changes in $cmp - taking the committed version (REMIND regenerates it at its next start)"
          run git -C "$path" update-index --no-skip-worktree "$f"
          run git -C "$path" checkout -- "$f"
        fi
      done
    fi
    run git -C "$path" checkout --quiet "$target"
    if git -C "$path" symbolic-ref -q HEAD >/dev/null; then run git -C "$path" pull --ff-only --quiet; fi
    if isRemind "$name"; then markGenerated "$path"; fi
  else
    say "$name: present ($(git -C "$path" rev-parse --short HEAD) on $(git -C "$path" rev-parse --abbrev-ref HEAD)) - NOT updated; --update fetches and fast-forwards it"
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
# A coupled run loads pfm from its own run-folder renv, which REMIND restores from a snapshot of the
# checkout's renv (cfg$UseThisRenvLock = NULL, PITFALLS.md section 37). renv refuses to snapshot packages
# "installed from an unknown source", which an R CMD INSTALL from models/ is (2026-10-07: every coupled
# submission stopped at "Generating lockfile"). So after installing, the installed DESCRIPTION gets the
# Remote* fields renv::install("<user>/<repo>") would write: the package's GitHub repository at the
# commit models/<pkg> has checked out. The snapshot then records it as a GitHub package, and the run
# folder's restore installs that commit from GitHub (at submission, on the login node). The commit must
# be pushed - pfmPreflight's repos check already requires it.
stampRemote() {  # $1 installed package directory, $2 the source checkout
  url=$(git -C "$2" remote get-url origin 2>/dev/null); sha=$(git -C "$2" rev-parse HEAD)
  ref=$(git -C "$2" rev-parse --abbrev-ref HEAD)
  case "$url" in *github.com[:/]*) ;; *) say "FAILED: $2 has no GitHub origin ($url) - renv cannot record its source"; return 1 ;; esac
  slug=${url#*github.com[:/]}; slug=${slug%.git}; user=${slug%%/*}; repo=${slug#*/}
  desc="$1/DESCRIPTION"
  grep -v '^Remote\(Type\|Host\|Username\|Repo\|Ref\|Sha\|Url\):' "$desc" > "$desc.tmp" && mv "$desc.tmp" "$desc"
  printf 'RemoteType: github\nRemoteHost: api.github.com\nRemoteUsername: %s\nRemoteRepo: %s\nRemoteRef: %s\nRemoteSha: %s\n' \
    "$user" "$repo" "$ref" "$sha" >> "$desc"
}
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
      stampRemote "$RLIB/$p" "models/$p" || exit 1
    done
    say "$r: mrpfm and pfm recorded as GitHub packages at $(git -C models/mrpfm rev-parse --short HEAD) / $(git -C models/pfm rev-parse --short HEAD)"
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
        # skip-worktree hides REMIND's regenerated sets from status; record that they differ
        if [ -f "$d/core/sets.gms" ] && [ "$(git -C "$d" hash-object core/sets.gms)" != "$(git -C "$d" rev-parse -q HEAD:core/sets.gms 2>/dev/null)" ]; then
          dirty="$dirty  (core/sets.gms regenerated by REMIND)"
        fi
        echo "$d  $(git -C "$d" rev-parse HEAD)  $(git -C "$d" rev-parse --abbrev-ref HEAD)$dirty"
      fi
    done
  } > "$out"
  say "commits recorded in $out"
  cat "$out"
fi
