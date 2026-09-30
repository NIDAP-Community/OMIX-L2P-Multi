# Local Code Ocean I/O testing

Use this guide to reproduce the mounted layout of a downstream Code Ocean
workflow without committing input data.

## Fixture layout

`data/` and `results/` are ignored by Git. Place an extracted upstream-results
download under an opaque workflow identifier:

```text
data/debug/codeocean-workflow/
`-- <workflow-result-id>/
    |-- DEG_Analysis.csv
    |-- figures/
    |-- moo/moo-diff.rds
    |-- output
    `-- r-packages.csv
```

When mounted at `/data`, the adapter finds exactly one CSV whose filename
matches the case-insensitive regex `DEG`. Other artifacts such as
`r-packages.csv` are ignored. If no DEG CSV is available, a uniquely named
`moo-diff.rds` remains an explicit fallback.

## Run the adapter locally

```bash
scripts/run-local-codeocean-workflow-debug.sh \
  ghcr.io/nidap-community/omix-r-pathway:<tag>
```

The runner uses the attached-demo comparison order (`B-A`, `C-A`, `B-C`) while
leaving `--deg_table` and column overrides blank. The workflow input layer must
therefore select the one wide DEG table and infer all ordered column mappings.

## Run workflow-input checks

```bash
Rscript tests/test-workflow-input.R
```

The check covers preferred DEG CSV selection, non-DEG CSV artifacts, ambiguity
errors, inferred multi-comparison columns, and MOO fallback discovery.
