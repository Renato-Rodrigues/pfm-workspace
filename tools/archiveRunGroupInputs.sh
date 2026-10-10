#!/usr/bin/env bash
# Copy every input file a Run-Group's estimation and coupled runs read into ONE folder you control,
# so the version can be rebuilt after the shared PIK folders are cleaned (TODO E25; 0005 D-M3 deposit).
# Run ON THE CLUSTER, from the project root:
#
#   bash tools/archiveRunGroupInputs.sh <group> <dest> [--dry-run]
#   bash tools/archiveRunGroupInputs.sh v6 /p/projects/elevate/WP3.4/archive --dry-run   # list, copy nothing
#   bash tools/archiveRunGroupInputs.sh v6 /p/projects/elevate/WP3.4/archive
#   bash tools/archiveRunGroupInputs.sh v5 /p/projects/elevate/WP3.4/archive             # the v5 rescue (E25)
#
# What it collects, from the records in records/<group>*/ (tracked in git, ADR 0047):
#   madrat-cache/used/        every file in records/<group>/madrat-cache-used-runs.tsv (what the coupled
#                             runs read) and madrat-cache-used-pfm.tsv (the estimation pin), looked up in
#                             the recorded cachefolder, then data/madrat/<group>*/, then the default
#                             shared cache /p/projects/rd3mod/inputdata/cache
#   madrat-cache/rungroups/<g>/  the prepared cache of the group and of each variant group <group>-*
#                             (data/madrat/<g>/, built by pfm::pfmPrepareCache)
#   remind-input/             every archive in records/<group>/remind-inputs-used-runs.tsv (input tgz,
#                             validation tgz, CESparametersAndGDX), looked up in the recorded repositories
#   records/                  a copy of records/<group>*/ so the folder explains itself
#   MANIFEST.tsv              path, size, md5 of everything copied; md5 checked against the records
#                             wherever they carry one
#   MISSING.tsv               anything that could not be found - check it: a missing file is a file
#                             that may already be gone
# Destination: <dest>/<group>-inputs-<date>/. Nothing outside it is written; the source files are
# only read. Re-running into a new date folder is safe. Sizes: v6 about a few GB (the input tgz
# dominate); check free space with the dry run first.
set -euo pipefail
say() { echo "[archive] $*"; }
[ $# -ge 2 ] || { echo "usage: tools/archiveRunGroupInputs.sh <group> <dest> [--dry-run]"; exit 1; }
GROUP="$1"; DEST="$2"; DRY=0; [ "${3:-}" = "--dry-run" ] && DRY=1
[ -d records ] && [ -d models ] || { echo "run from the project root (records/ and models/ not found here)"; exit 1; }
[ -d "records/$GROUP" ] || { echo "no records/$GROUP"; exit 1; }
SHARED_CACHE=/p/projects/rd3mod/inputdata/cache
OUT="$DEST/${GROUP}-inputs-$(date +%Y-%m-%d)"


copy() {   # copy <src> <relative target dir>
  local src="$1" rel="$2"; local sz; sz=$(stat -c %s "$src")
  if [ "$DRY" = 1 ]; then printf '  %-60s %12s  <- %s\n' "$rel/$(basename "$src")" "$sz" "$src"; return; fi
  mkdir -p "$OUT/$rel"; cp -p "$src" "$OUT/$rel/"
}
column_of() { grep -v '^#' "$1" | head -1 | tr '\t' '\n' | { grep -nx "$2" || true; } | cut -d: -f1; }
rows_of() { grep -v '^#' "$1" | tail -n +2 || true; }   # data rows: comment lines and the header dropped

# 1. madrat cache files the runs and the estimation read
for rec in "records/$GROUP/madrat-cache-used-runs.tsv" "records/$GROUP/madrat-cache-used-pfm.tsv"; do
  [ -f "$rec" ] || { say "$rec not present - skipped"; continue; }
  say "madrat cache files in $rec"
  cf=$(column_of "$rec" cachefolder)
  rows_of "$rec" | while IFS=$'\t' read -r -a f; do
    file="${f[0]}"; [ -n "$file" ] || continue
    rf=""; [ -n "$cf" ] && rf="${f[$((cf - 1))]:-}"
    found=""
    for d in "$rf" data/madrat/"$GROUP" data/madrat/"$GROUP"-* "$SHARED_CACHE"; do
      [ -n "$d" ] && [ -f "$d/$file" ] && { found="$d/$file"; break; }
    done
    if [ -n "$found" ]; then copy "$found" madrat-cache/used
    else echo -e "$file\tmadrat-cache\t$rec" >> "${TMPDIR:-/tmp}/archive-missing-$$"; fi
  done
done

# 2. the prepared caches of the group and its variants
for d in data/madrat/"$GROUP" data/madrat/"$GROUP"-*; do
  [ -d "$d" ] || continue
  g=$(basename "$d"); say "prepared cache $d"
  for f in "$d"/*; do [ -f "$f" ] && copy "$f" "madrat-cache/rungroups/$g"; done
done

# 3. REMIND input archives
rec="records/$GROUP/remind-inputs-used-runs.tsv"
if [ -f "$rec" ]; then
  say "REMIND input archives in $rec"
  rows_of "$rec" | while IFS=$'\t' read -r file times repos; do
    found=""
    IFS=';' read -r -a rs <<< "$repos"
    for d in "${rs[@]}" /p/projects/rd3mod/inputdata/output /p/projects/remind/inputdata/CESparametersAndGDX; do
      [ -f "$d/$file" ] && { found="$d/$file"; break; }
    done
    if [ -n "$found" ]; then copy "$found" remind-input
    else echo -e "$file\tremind-input\t$rec" >> "${TMPDIR:-/tmp}/archive-missing-$$"; fi
  done
else
  say "$rec not present - REMIND input archives not listed (write it with tools/listRemindInputsUsed.R on the run folders)"
fi

# 4. the records themselves, the manifest and what is missing
if [ "$DRY" = 0 ]; then
  mkdir -p "$OUT/records"; cp -rp records/"$GROUP" records/"$GROUP"-* "$OUT/records/" 2>/dev/null || true
  ( cd "$OUT" && find . -type f ! -name MANIFEST.tsv ! -name MISSING.tsv | sort | while read -r p; do
      printf '%s\t%s\t%s\n' "${p#./}" "$(stat -c %s "$p")" "$(md5sum "$p" | cut -d' ' -f1)"; done ) > "$OUT/MANIFEST.tsv.body"
  { echo -e "path\tsize\tmd5"; cat "$OUT/MANIFEST.tsv.body"; } > "$OUT/MANIFEST.tsv"; rm "$OUT/MANIFEST.tsv.body"
  # md5 check against every record that carries one (madrat-cache-manifest.tsv, madrat-cache-used-*.tsv)
  bad=0
  for rec in records/"$GROUP"/*.tsv records/"$GROUP"-*/*.tsv; do
    [ -f "$rec" ] || continue
    mc=$(column_of "$rec" md5); [ -n "$mc" ] || continue
    while IFS=$'\t' read -r -a f; do
      file="${f[0]}"; want="${f[$((mc - 1))]:-}"; [ -n "$want" ] || continue
      got=$(awk -F'\t' -v b="$file" '{ n = split($1, p, "/"); if (p[n] == b) print $3 }' "$OUT/MANIFEST.tsv" | sort -u)
      [ -z "$got" ] && continue
      echo "$got" | grep -qx "$want" || { say "md5 MISMATCH $file ($rec): want $want, have $got"; bad=$((bad + 1)); }
    done < <(rows_of "$rec")
  done
  [ "$bad" = 0 ] && say "md5: every file with a recorded md5 matches"
fi
if [ -f "${TMPDIR:-/tmp}/archive-missing-$$" ]; then
  say "NOT FOUND ($(wc -l < "${TMPDIR:-/tmp}/archive-missing-$$")):"; sed 's/^/  /' "${TMPDIR:-/tmp}/archive-missing-$$"
  [ "$DRY" = 0 ] && { echo -e "file\tkind\trecord"; cat "${TMPDIR:-/tmp}/archive-missing-$$"; } > "$OUT/MISSING.tsv"
  rm -f "${TMPDIR:-/tmp}/archive-missing-$$"
else say "nothing missing"; fi
if [ "$DRY" = 1 ]; then say "dry run: nothing copied"
else say "copied into $OUT"; du -sh "$OUT" | sed 's/^/[archive] size /'; fi
