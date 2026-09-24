# OMIX L2P Analysis (Multi)

## Canonical OMIX module

| Item | Location |
| --- | --- |
| Canonical module | [OMIX L2P Multi](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Multi) |
| Interface contract | [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-L2P-Multi/schemas/interface.yml) |
| Development contract | [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md) |
| Released source reference | [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md) |

The canonical module owns scientific behavior, portable CLI operation, tests,
and the reusable input/output contract. This repository is its Code Ocean
deployment adapter.

## What this deployment adds

- The Code Ocean App Panel and capsule entry point.
- Uploaded and attached multi-comparison DEG-table discovery under `/data`.
- Capsule outputs under `/results` and the pinned runtime configuration.

The attached demonstration dataset is from mouse, so the deployment presets
**Species** to `Mouse` and provides its ordered example comparisons. The App
Panel places the essential controls under **Main Settings** and keeps every
supported tuning control visible in an **Advanced** category. Scientific
parameter names match the canonical CLI; the older `--collections` and
`--select_top_percentage` spellings remain accepted as command-line aliases
for saved capsule runs.

## Overview

**Version**: v4.0 | **Part of the OMIX analysis suite**

Pathway over-representation analysis using L2P (List to pathways) for comparing multiple differential expression contrasts. Creates bubble plots showing pathway enrichment patterns across different comparisons.

## L2P (List to pathways) Analysis

This analysis performs pathway enrichment using Fisher's exact test to identify significantly enriched biological pathways in lists of differentially expressed genes. Results are visualized as bubble plots comparing pathway enrichment across multiple contrasts.

### Key Features

- **Multi-comparison support**: Compare pathway enrichment across multiple DEG contrasts
- **Threshold-based selection by default**: Select genes by nominal p-value ≤ 0.05 and absolute fold change ≥ 1.2; rank selection remains available
- **Multiple pathway databases**: GO, REACTOME, KEGG, MSigDB (H, C1-C8), WikiPathways, and custom pathways
- **Cross-species support**: Human, Mouse, Rat, Macaque, Zebrafish, Rabbit, Drosophila (via ortholog mapping)
- **Gene symbol updates**: Optional automatic gene name updating for consistency
- **Customizable visualization**: Control bubble size, color, font sizes, and pathway ordering

## Input Requirements

### Required Data

- **DEG table**: Data frame with gene names, statistics, and comparison metrics
  - Must contain gene names column
  - For rank-based selection: t-statistic columns
  - For threshold-based selection: p-value/adjusted p-value and fold change columns

### Column Selection

**Option 1: Automatic (using comparisons parameter)**
```bash
--comparisons "B-A,C-A" 
# Derives: B-A_tstat, B-A_pval, B-A_FC, C-A_tstat, C-A_pval, C-A_FC
```

**Option 2: Explicit column specification**
```bash
--t_statistic_columns "contrast1_tstat,contrast2_tstat"
--significance_columns "contrast1_pval,contrast2_pval"
--fold_change_columns "contrast1_FC,contrast2_FC"
```

## Usage

### Basic Example

```bash
./run \
  --input_file /data/deg_results.rds \
  --gene_names_column "gene_name" \
  --comparisons "TreatmentB-Control,TreatmentC-Control" \
  --species "Human" \
  --collections_to_include "H,REACTOME" \
  --select_by_rank FALSE \
  --maximum_pathways_to_plot 20
```

### Gene Selection Methods

**Method 1: Rank-based (optional)**
```bash
--select_by_rank TRUE \
--select_top_percentage_of_genes TRUE    # Top 10% of genes by |t-statistic|
# OR
--select_by_rank TRUE \
--select_top_percentage_of_genes FALSE \
--select_top_genes 500          # Top 500 genes by |t-statistic|
```

**Method 2: Threshold-based (default)**
```bash
--select_by_rank FALSE \
--significance_threshold 0.05 \
--fold_change_threshold 1.5
```

### Pathway Collections

Available collections (comma-separated):
- `GO`: Gene Ontology
- `REACTOME`: Reactome pathways
- `KEGG`: KEGG pathways
- `H`: MSigDB Hallmark gene sets
- `C1`-`C8`: MSigDB curated collections
- `WikiPathways`: WikiPathways database

Example: `--collections_to_include "H,REACTOME,GO"`

### Using Custom Pathway Databases

You can use your own custom pathway database instead of or in addition to the built-in collections.

**File Format Requirements:**

Your custom pathway file must be in **TSV or CSV format** with two required columns:

- **Pathway name column**: Contains pathway/gene set names (default: `gene_set_name`)
- **Gene symbol column**: Contains gene symbols (default: `gene_symbol`)

**Example format**:
```
gene_set_name,gene_symbol
My_Custom_Pathway_1,TP53
My_Custom_Pathway_1,BRCA1
My_Custom_Pathway_1,MYC
My_Custom_Pathway_2,EGFR
My_Custom_Pathway_2,KRAS
```

**How to Use:**

1. Prepare your custom pathway file in the format above (TSV or CSV)
2. Open the **App Panel** (⚙️ icon) in this capsule
3. Go to **"Custom Pathways (Optional)"** section
4. **Custom Pathway File**: Click to upload your file from your local computer
5. **Pathway Name Column**: Adjust if your column name differs (default: `gene_set_name`)
6. **Gene Symbol Column**: Adjust if your column name differs (default: `gene_symbol`)
7. **Pathway Collections**: Leave blank to use *only* custom pathways, or keep filled to use custom + standard collections
8. Click **Run**

**Tips:**
- Gene symbols must match your species or will undergo ortholog conversion
- You can combine custom pathways with standard collections (GO, REACTOME, etc.)
- Coming soon: Curated custom pathway databases available as dropdown options

### Visualization Options

```bash
--plot_bubble_size "pval"                    # or "fdr", "number_hits"
--plot_bubble_color "enrichment_score"       # or "net_enrichment_score"
--maximum_pathways_to_plot 20                # Number of rows shown in each legacy summary plot
--number_of_significant_events 1             # Min significant events across contrasts
--pathway_axis_label_max_length 100          # Max pathway label length
--pathway_axis_label_font_size 5             # Pathway label font size
```

## Key Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input_file` | string | required | Input DEG table (RDS, CSV, or TSV) |
| `gene_names_column` | string | required | Column with gene names |
| `comparisons` | string | required | Comma-separated comparison IDs |
| `species` | string | "Mouse" | Species for ortholog mapping |
| `collections_to_include` | string | "H" | Comma-separated pathway collections (`collections` remains a compatibility alias) |
| `select_by_rank` | boolean | FALSE | Use the optional rank-based gene selection |
| `maximum_pathways_to_plot` | integer | 20 | Limit rows displayed in the legacy summary plot |
| `significance_threshold` | numeric | 0.05 | P-value threshold (if not rank-based) |
| `fold_change_threshold` | numeric | 1.2 | FC threshold (if not rank-based) |
| `output_results` | string | /results/l2p_multi_results.csv | Output results path |

## Complete Parameter Reference

### Basic Settings
- **`input_file`**: Path to DEG table (RDS, CSV, TSV)
- **`gene_names_column`**: Column containing gene symbols (default: "Gene")
- **`comparisons`**: Comma-separated comparison IDs (e.g., "B-A, C-A, B-C")
- **`species`**: Human, Mouse, Rat, Macaque, Zebrafish, Rabbit, Drosophila (default: "Mouse")
- **`collections_to_include`**: Pathway collections - GO, REACTOME, KEGG, H, C1-C8, WikiPathways (default: "H"; `collections` remains a compatibility alias)

### Column Overrides (Advanced)
- **`t_statistic_columns`**: Override auto-detected t-statistic columns (comma-separated)
- **`significance_columns`**: Override auto-detected p-value columns (comma-separated)
- **`fold_change_columns`**: Override auto-detected fold change columns (comma-separated)

### Gene Selection Method
- **`select_by_rank`**: Use rank-based selection (TRUE) or thresholds (FALSE) (default: FALSE)
- **`select_top_percentage_of_genes`**: Select top 10% (TRUE) or fixed number (FALSE) (default: TRUE; `select_top_percentage` remains a compatibility alias)
- **`select_top_genes`**: Number of top genes if not using percentage (default: 500)
- **`significance_threshold`**: P-value threshold for threshold-based selection (default: 0.05)
- **`fold_change_threshold`**: Fold change threshold for threshold-based selection (default: 1.2)
- **`minimum_number_of_deg_genes`**: Minimum DEG genes required per comparison (default: 100)

### Pathway Filtering
- **`top_pathways`**: Deprecated compatibility setting; it does not truncate the exported pathway table
- **`number_of_significant_events`**: Minimum comparisons where pathway must be significant (default: 1)
- **`maximum_pathways_to_plot`**: Maximum pathways displayed in the legacy summary plot (default: 20)
- **`update_genes`**: Update gene symbols to current nomenclature (default: TRUE)

### Visualization Options
- **`pathway_bubble_plots`**: Write standardized OMIX bubble plots and a manifest (default: TRUE)
- **`pathway_bubble_top_n`**: Maximum rows shown in each standardized bubble plot (default: 20; 0 = all)
- **`pathway_bubble_significance_statistic`**: Use `padj` (default) or `pval` for standardized-bubble selection and shapes
- **`collection_color_scale`**: Use independent (default) or shared color limits across pathway collections
- **`plot_bubble_size`**: Bubble size metric - pval, fdr, or number_hits (default: "pval")
- **`plot_bubble_color`**: Bubble color metric - enrichment_score, net_enrichment_score, or percent_gene_hits_per_pathway (default: "enrichment_score")
- **`pathway_axis_label_max_length`**: Max characters for pathway labels (default: 45)
- **`pathway_axis_label_font_size`**: Font size for pathway labels (default: 5)

### Custom Pathways (Optional)
- **`custom_pathways`**: Path to custom pathway file (TSV/CSV format)
- **`custom_pathway_name_column`**: Column with pathway names in custom file (default: "gene_set_name")
- **`custom_pathway_gene_column`**: Column with gene symbols in custom file (default: "gene_symbol")

### Advanced Pathway Filtering
- **`use_built_in_gene_universe`**: Use built-in gene universe instead of detected genes (default: FALSE)
- **`minimum_pathway_hit_count`**: Minimum genes required per pathway (default: 5)
- **`pathway_size_limit`**: Maximum pathway size - larger pathways excluded (default: 500)
- **`p_value_limit`**: P-value cutoff for including pathways (default: 0.05)
- **`use_fdr_for_significance`**: Use FDR instead of raw p-values (default: FALSE)

### Advanced Plot Customization
- **`plot_bubble_max_color`**: Maximum value for color scale gradient (default: 1)
- **`pathways_to_remove`**: Comma-separated pathway names to exclude from plot
- **`rename_groups`**: Comma-separated new names for comparison groups
- **`vertical_line_placement`**: Comma-separated positions for vertical separator lines
- **`use_panel_plot`**: Use panel layout splitting comparisons into separate panels (default: FALSE)
- **`use_dynamic_pathway_font_size`**: Auto-adjust pathway label font size (default: TRUE)
- **`custom_pathway_order`**: Comma-separated pathway names to define custom Y-axis order
- **`column_spacing`**: Spacing between comparison columns (default: 0.5)

### Axis Customization (Optional)
- **`x_axis_title`**: Custom title for x-axis (comparison axis)
- **`y_axis_title`**: Custom title for y-axis (pathway axis)
- **`x_axis_title_font_size`**: Font size for x-axis title (default: 14)
- **`y_axis_title_font_size`**: Font size for y-axis title (default: 14)
- **`x_axis_tick_font_size`**: Font size for x-axis tick labels (default: 14)
- **`x_axis_tick_labels`**: Comma-separated custom labels for x-axis ticks
- **`y_axis_tick_labels`**: Comma-separated custom labels for y-axis ticks

### Output Settings
- **`output_plot`**: Deprecated compatibility value for the retired legacy summary image; current shared plots are written beside `output_results`
- **`output_results`**: File path for output results table (default: /results/l2p_multi_results.csv)
- **`plot_width`**: Plot width in inches (default: 14)
- **`plot_height`**: Plot height in inches (default: 16)

## Output Files

1. **Shared OMIX bubble plots** (`L2P-Multi-Pathway-Bubble-*.png`)
   - One combined plot, a cross-collection faceted plot, collection-specific plots, and a manifest
   - Bubble selection and significance shapes use adjusted p-values/FDR by default
   - Each figure shows the top 20 pathways by default, while `l2p_multi_results.csv` retains every pathway that meets the selected significance and hit-count criteria

2. **Results Table** (`l2p_multi_results.csv`)
   - Pathway name, category, direction
   - Hit counts, enrichment scores
   - P-values, FDR
   - Gene lists (original and updated symbols)

## Advanced Features

### Custom Pathway Order
Manually specify pathway display order in the plot.

### Dynamic Font Sizing
Automatically adjusts pathway label font size based on number of pathways.

### Vertical Separators
Add visual separators between comparison groups.

### Panel Plots
Divide plot into panels by pathway collection (not recommended for many collections).

## Reproducibility

- Uses MOSuite R v0.3.2 base image with l2p and l2psupp packages
- Gene symbol updating uses latest databases (optional via `--update_genes`)
- All parameters logged to output for provenance

## References

- **L2P package**: https://github.com/ccbr/l2p
- **Original version**: L2P Multi v93

## Support

For questions or issues:
- **NIDAP Team**: NCICCBRNIDAP@mail.nih.gov
- **CCBR**: CCR Collaborative Bioinformatics Resource

## For developers

Read [AGENTS.md](AGENTS.md) and [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md)
before editing. Reusable scientific changes belong in the canonical OMIX module
and are exported here only after validation.

---

**OMIX Collection** | **Bioinformatics** | **Pathway Analysis** | **R**
