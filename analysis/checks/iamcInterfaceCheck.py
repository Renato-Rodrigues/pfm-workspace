"""Check the PFM interface's variables (GMD paper, Appendix L, Table L1) against the IAMC common definitions (gap plan GP-33).

Usage (repo root):
  git clone --depth 1 https://github.com/IAMconsortium/common-definitions.git <dir>
  python -I analysis/checks/iamcInterfaceCheck.py <dir> output/pfm/v8/interface-iamc-check.csv
Needs the `nomenclature-iamc` package (tags in the definitions, e.g. `Primary Energy|{Fuel}`, are expanded by it).
Writes one row per candidate IAMC name with whether it is defined and its unit, and the definitions' commit.
"""
import csv
import sys
from pathlib import Path

import nomenclature

repo = Path(sys.argv[1])
out = Path(sys.argv[2])
dsd = nomenclature.DataStructureDefinition(repo / "definitions", dimensions=["variable"])
known = dsd.variable.mapping  # name -> code (tags expanded)
import subprocess
commit = subprocess.run(["git", "-C", str(repo), "log", "-1", "--format=%H %cs"], capture_output=True, text=True).stdout.strip()

WANT = {
    "primary energy by carrier and total": [
        "Primary Energy|Coal", "Primary Energy|Oil", "Primary Energy|Gas", "Primary Energy|Wind",
        "Primary Energy|Solar", "Primary Energy|Nuclear", "Primary Energy|Hydro", "Primary Energy|Geothermal",
        "Primary Energy"],
    "electricity from wind and solar, and total": [
        "Secondary Energy|Electricity|Wind", "Secondary Energy|Electricity|Solar", "Secondary Energy|Electricity"],
    "industry final energy, fossil and total": [
        "Final Energy|Industry|Liquids|Fossil", "Final Energy|Industry|Liquids|Oil", "Final Energy|Industry|Gases|Fossil",
        "Final Energy|Industry|Gases|Natural Gas", "Final Energy|Industry|Solids|Fossil", "Final Energy|Industry|Solids|Coal",
        "Final Energy|Industry"],
    "final electricity and total final energy": ["Final Energy|Electricity", "Final Energy"],
    "transport liquids, biofuel and total": [
        "Final Energy|Transportation|Liquids|Biomass", "Final Energy|Transportation|Liquids|Bioenergy",
        "Final Energy|Transportation|Liquids"],
    "fossil extraction, its price and cost; GDP": [
        "Resource|Extraction|Coal", "Resource|Extraction|Oil", "Resource|Extraction|Gas",
        "Price|Primary Energy|Coal", "Price|Primary Energy|Oil", "Price|Primary Energy|Gas",
        "Resource|Cost|Coal", "Resource|Cost|Oil", "Resource|Cost|Gas", "Cost|Resource|Coal",
        "GDP|PPP", "GDP|MER"],
}
rows = []
for quantity, names in WANT.items():
    for n in names:
        code = known.get(n)
        rows.append({"quantity": quantity, "variable": n, "definitions_commit": commit, "in_common_definitions": code is not None,
                     "unit": (code.unit if code is not None else "")})
# Close matches for every name not found, to help the table say what a host would report instead.
for r in rows:
    if not r["in_common_definitions"]:
        stem = r["variable"].rsplit("|", 1)[0]
        cands = sorted(k for k in known if k.startswith(stem + "|"))[:12]
        r["nearest"] = "; ".join(cands)
    else:
        r["nearest"] = ""
with out.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["quantity", "variable", "definitions_commit", "in_common_definitions", "unit", "nearest"])
    w.writeheader()
    w.writerows(rows)
print(f"{len(known)} variables in the common definitions; wrote {out}")
for r in rows:
    print(("OK   " if r["in_common_definitions"] else "MISS ") + r["variable"] + ("" if r["in_common_definitions"] else "   -> " + r["nearest"][:200]))
