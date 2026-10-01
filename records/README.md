# records/ — what a Run-Group needs to be reproduced, tracked in git

`output/` and `data/` are not in git: they are large, regenerable, or copied from the cluster.
This folder keeps the small text records without which a version cannot be rebuilt exactly,
one folder per Run-Group:

| file | written by | what it is |
|---|---|---|
| `<group>/madrat-cache-manifest.tsv` | `pfm::pfmPrepareCache()`, automatically | every madrat cache file the group's pipeline reads, with size and md5. Deposit these files with the version |
| `<group>/madrat-cache-used-pfm.tsv` | `tools/listMadratCacheUsed.R` on the estimation logs | the **pin**: when present, `pfmPrepareCache()` rebuilds the group's cache from exactly these files |
| `<group>/madrat-cache-used-runs.tsv` | `listMadratCacheUsed.R` on the REMIND run logs | what the coupled runs read |

`config.yml` `recordsDir` names this folder. ADR 0047.
