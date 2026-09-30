# OMIX L2P Multi

Run L2P over-representation analysis across several differential-expression
contrasts and compare pathway signals in standardized OMIX bubble plots.

This repository is the Code Ocean deployment adapter. The portable scientific
implementation, interface schema, and tests are maintained in the canonical
[OMIX L2P Multi module](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Multi).

## What it does

- selects up- and down-regulated genes for each ordered contrast;
- tests built-in L2P collections and optional custom gene sets;
- exports all pathways meeting the configured hit and significance criteria;
- creates combined, cross-collection, and collection-specific bubble plots;
  and
- keeps comparison order consistent from the input controls through the plots.

Threshold selection is the default: nominal p-value at most `0.05` and
absolute linear fold change at least `1.2`. Rank selection remains available as
an advanced compatibility method. Shared plots show the top 20 pathways by
adjusted p-value by default; the CSV is not truncated to 20 rows.

## Input

Provide one wide DEG table in CSV, TSV, TXT, or RDS format. It must contain:

- one gene-symbol column;
- one signed ranking statistic per comparison;
- one p-value or adjusted-p-value column per comparison; and
- one linear- or log-fold-change column per comparison.

For example:

```text
GeneName,B-A_tstat,B-A_pval,B-A_FC,C-A_tstat,C-A_pval,C-A_FC
Gene1,3.2,0.001,2.1,-2.4,0.010,-1.8
```

Enter comparison IDs in the exact order you want analyzed and plotted. The
adapter does not reinterpret or reverse contrasts. `C-B` therefore requires
`C-B_*` columns; it will not silently substitute `B-C_*` columns.

The optional custom pathway input may be an L2P-compatible RDS object or a
delimited table with one pathway/gene membership per row. The default columns
are `gene_set_name` and `gene_symbol`.

## Code Ocean quick start

1. Open the App Panel.
2. To try the attached demo, leave **DEG Table** blank and retain
   `Mouse` plus `B-A,C-A,B-C`.
3. For your data, select **DEG Table**, replace **Comparisons**, and select the
   correct species.
4. Leave column overrides blank when names follow the comparison-prefix
   convention; otherwise provide one comma-separated column per comparison in
   the same order.
5. Choose built-in collections such as `H,REACTOME` and optionally select a
   custom pathway file.
6. Run the capsule and inspect `/results`.

If **DEG Table** is blank, the adapter accepts only one unambiguous eligible
table from the attached `deg_table` asset or workflow result. When several
candidates exist, it stops and lists them rather than choosing one silently.

The attached mouse demo and its comparison list are the only App Panel default
exceptions to the canonical portable interface. All other public and advanced
controls use canonical names and defaults. Retired legacy-renderer controls and
platform result paths are not shown in the App Panel.

## Main controls

| Control | Default | Purpose |
| --- | --- | --- |
| `comparisons` | demo: `B-A,C-A,B-C` | Ordered contrast identifiers. |
| `species` | demo: `Mouse` | Species for symbol validation and ortholog mapping. |
| `collections_to_include` | `H` | Comma-separated built-in pathway collections. |
| `select_by_rank` | `FALSE` | Use threshold selection unless explicitly enabled. |
| `significance_threshold` | `0.05` | Gene-list significance threshold. |
| `fold_change_threshold` | `1.2` | Absolute linear fold-change threshold. |
| `number_of_significant_events` | `1` | Comparisons in which a pathway must pass export criteria. |
| `minimum_pathway_hit_count` | `5` | Minimum selected-gene hits for export selection. |
| `p_value_limit` | `0.05` | Pathway export threshold. |
| `pathway_bubble_top_n` | `20` | Rows per standardized plot scope; `0` means all. |
| `pathway_bubble_significance_statistic` | `padj` | `padj` or `pval` for shared-plot selection and shapes. |

All additional supported controls remain available in the App Panel's advanced
sections. See the canonical
[interface schema](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-L2P-Multi/schemas/interface.yml)
for exact types, allowed values, and semantics.

## Outputs

The adapter writes stable artifacts under `/results`:

- `l2p_multi_results.csv` — all pathways meeting export criteria;
- `l2p_multi_results_provenance.csv` — result provenance;
- `L2P-Multi-Pathway-Bubble_*.png` — standardized shared plots; and
- `L2P-Multi-Pathway-Bubble_manifest.csv` — selection, ordering, scale, and
  figure metadata.

## Compatibility

Older saved capsule runs may still use `--deg_file`, `--collections`, and
`--select_top_percentage`. The adapter translates these aliases to the
canonical controls and warns when they are used. New App Panel runs emit only
canonical names.

The optional legacy `Table`, `Filtered DEG`, and `All DEG` values accepted by
`--deg_file` are retained for saved runs but are not new App Panel controls.

## Reproducibility and validation

[OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md) records the canonical commit,
scientific-file hash, schema hash, runtime tag, platform translations, and
pending release evidence. The runtime digest and Code Ocean run are not yet
recorded. Follow the [Code Ocean validation plan](docs/code-ocean-validation-plan.md)
before release.

## For developers

Read [AGENTS.md](AGENTS.md) and [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md)
before editing. Scientific changes belong in canonical OMIX and must flow
one-way into `code/functions/` without modification. Deployment input
discovery, App Panel configuration, and `/results` translation belong here.

## References and support

- [L2P](https://github.com/ccbr/l2p)
- [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)
- NIDAP Team: `NCICCBRNIDAP@mail.nih.gov`
