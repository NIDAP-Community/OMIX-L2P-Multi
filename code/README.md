# L2P Multi Code Ocean entry point

`main.R` is the platform adapter for the canonical
[OMIX L2P Multi module](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Multi).
It translates Code Ocean named parameters, mounted inputs, and `/results`
paths; it does not own the scientific algorithm.

## Files

- `main.R` — Code Ocean entry point and platform translation.
- `functions/analysis_functions.R` — byte-identical canonical scientific
  export; do not edit here.
- `functions/workflow_input.R` — deterministic attached/workflow input
  discovery owned by this adapter.
- `functions/cli_compatibility.R` — released CLI alias handling owned by this
  adapter.
- `run` — capsule launcher.

## Input precedence

1. An explicit `--deg_table PATH` selected in the App Panel.
2. One unambiguous workflow DEG CSV or `moo-diff.rds` below `/data`.
3. Exactly one supported table below `/data/deg_table`.

Ambiguity is an error and every candidate is printed. Older saved runs may use
`--deg_file`, including the legacy `Table`, `Filtered DEG`, and `All DEG`
modes. New runs should use `--deg_table`.

Ordered comparison columns are derived with `--t_statistic_suffix`,
`--significance_suffix`, and `--fold_change_suffix` when their corresponding
exact column-list controls are blank. Exact comma-separated column lists take
precedence over these shared suffix settings.

## Local validation example

Run from `code/` so relative function paths resolve:

```bash
OMIX_RESULTS_DIR=/tmp/l2p-multi-results Rscript main.R \
  --deg_table data/example_inputs/deg_table.csv \
  --comparisons B-A,C-A,B-C \
  --gene_names_column Gene \
  --species Mouse \
  --collections_to_include H \
  --pathway_bubble_plots false
```

This is a local adapter check, not Code Ocean validation. Platform release
requires the evidence listed in
[`../docs/code-ocean-validation-plan.md`](../docs/code-ocean-validation-plan.md).
