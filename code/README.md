# OMIX L2P Pathway Analysis (Multi)

List to pathways (L2P) over-representation analysis for comparing multiple differential expression contrasts. Uses Fisher's exact test to identify enriched pathways and creates bubble plots comparing pathway enrichment across groups.

## Overview

This capsule performs pathway enrichment analysis across **multiple differential expression contrasts** to identify biological pathways that are significantly enriched and compare them across groups. It creates comparative bubble plots that allow you to visualize pathway enrichment patterns across multiple comparisons simultaneously.

## Basic Settings (Required)

Before running the analysis, configure these essential parameters in the **⭐ Basic Settings** category:

### 1. DEG Table File
**Input your differential expression data:**
- **Upload your own file**: Click to upload CSV, TSV, or RDS format
- **Use demo data**: Leave blank to use the attached demo data asset (Mouse RNA-seq example with 3 comparisons)

**Required columns in your file:**
- Gene identifier column (e.g., `Gene`, `symbol`)
- For **each comparison**, three columns with the pattern `{comparison}_tstat`, `{comparison}_pval`, `{comparison}_FC`
  
**Example for comparisons "B-A" and "C-A":**
```
Gene        B-A_tstat   B-A_pval    B-A_FC    C-A_tstat   C-A_pval    C-A_FC
Serpina3f   5.23        0.0001      2.5       3.12        0.005       1.8
Abl1        -3.45       0.002       0.6       -2.89       0.008       0.7
...
```

### 2. Comparisons
**Which contrasts to analyze** (REQUIRED)
- Specify a **comma-separated list** of comparison identifiers
- Example: `B-A,C-A,C-B` or `Treatment1-Control,Treatment2-Control`
- Each comparison must match the column prefixes in your data
- **Tip**: Limit to 3-5 comparisons for clearest visualizations

### 3. Species
**Select your organism** (default: Mouse)
- Options: Human, Mouse, Rat, Rabbit, Zebrafish, Macaque, Drosophila
- Non-human genes are automatically converted to human orthologs for pathway analysis

### 4. Pathway Collections
**Select which pathway databases to search** (default: H)

Copy and paste one or more comma-separated identifiers (see full list below):

**Quick options:**
- `H` - Start here! MSigDB Hallmark gene sets (50 focused, well-defined pathways)
- `GO,REACTOME,KEGG` - Broad coverage of standard databases
- `H,C2,C6` - Cancer-focused analysis
- `GO,REACTOME,C7` - Immunology-focused analysis

See the "Available Pathway Collections" section below for the complete list and descriptions.

## Available Pathway Collections

The **Pathway Collections** parameter accepts a **comma-separated list** of pathway database identifiers. You can mix and match any combination.

### Standard Biological Databases

Copy and paste these into the "Pathway Collections" field:

```
GO
```
- Gene Ontology: Comprehensive biological processes, molecular functions, and cellular components

```
REACTOME
```
- Reactome: Curated pathway database focused on human biology

```
KEGG
```
- KEGG: Kyoto Encyclopedia of Genes and Genomes pathway database

```
PANTH
```
- PANTHER: Protein Analysis Through Evolutionary Relationships

```
PID
```
- Pathway Interaction Database: Curated cancer and signaling pathways

```
BIOCYC
```
- BioCyc: Collection of metabolic pathway databases

```
WikiPathways
```
- Community-curated pathway database

### MSigDB Collections

[MSigDB (Molecular Signatures Database)](http://www.gsea-msigdb.org/gsea/msigdb/) provides expertly curated gene sets:

```
H
```
- **Hallmark gene sets**: Well-defined biological states/processes (50 gene sets)

```
C1
```
- **Positional gene sets**: Genes grouped by chromosomal location

```
C2
```
- **Curated gene sets**: Chemical and genetic perturbations, canonical pathways (KEGG, REACTOME, BIOCARTA, PID)

```
C3
```
- **Regulatory target gene sets**: microRNA and transcription factor targets

```
C4
```
- **Computational gene sets**: Cancer-related gene sets from computational analyses

```
C5
```
- **Ontology gene sets**: GO biological process, cellular component, molecular function

```
C6
```
- **Oncogenic signature gene sets**: Gene sets from cancer-related studies

```
C7
```
- **Immunologic signature gene sets**: Cell types, states, and perturbations from immunology studies

```
C8
```
- **Cell type signature gene sets**: Gene sets from single-cell sequencing studies

### Common Examples

**Default (comprehensive but focused):**
```
H
```

**Broad pathway coverage:**
```
GO,REACTOME,KEGG
```

**Cancer-focused analysis:**
```
H,C2,C6
```

**Immunology-focused analysis:**
```
GO,REACTOME,C7
```

**Comprehensive MSigDB analysis:**
```
H,C1,C2,C3,C4,C5,C6,C7,C8
```

**All available databases:**
```
GO,REACTOME,KEGG,PANTH,PID,BIOCYC,WikiPathways,H,C1,C2,C3,C4,C5,C6,C7,C8
```

## Multi-Comparison Analysis

The key difference from L2P Single is the ability to analyze **multiple contrasts simultaneously**:

**Output advantages:**
1. Perform pathway enrichment analysis for each comparison separately
2. Identify pathways enriched in upregulated or downregulated genes
3. Create **comparative bubble plots** showing pathway enrichment across all comparisons
4. Generate separate detailed plots for each individual comparison

**Interpretation**: The comparative bubble plots are excellent for identifying pathways that are:
- **Consistently enriched** across all comparisons
- **Uniquely enriched** in specific comparisons  
- **Differentially enriched** between comparisons

## Species Support

The analysis supports multiple species with automatic ortholog mapping to human gene symbols:

- Human, Mouse, Rat, Rabbit, Zebrafish, Macaque, Drosophila

All genes are mapped to human orthologs internally for pathway matching, ensuring compatibility across species.

## Custom Pathways

You can provide your own pathway definitions via the "Custom Pathway File" parameter:

**Format**: TSV or CSV file with two columns:
- Pathway name column (default: `gene_set_name`)
- Gene symbol column (default: `gene_symbol`)

Custom pathways can be used **with** or **without** standard collections.

## Output Files

The analysis generates:

1. **l2p_results.csv**: Complete pathway enrichment results for all comparisons
   - Pathway names, categories, comparison, direction
   - Number of hits, percent gene hits, enrichment score
   - P-values and FDR-adjusted p-values
   - Genes in pathway and overlapping genes

2. **Comparative bubble plots**:
   - `l2p_plots_upregulated_pathways_bubble.png`: Compare upregulated pathways across all contrasts
   - `l2p_plots_downregulated_pathways_bubble.png`: Compare downregulated pathways across all contrasts

3. **Individual comparison plots** (for each comparison):
   - `l2p_plots_{comparison}_upregulated_pathways_bubble.png`
   - `l2p_plots_{comparison}_upregulated_pathways_bar.png`
   - `l2p_plots_{comparison}_downregulated_pathways_bubble.png`
   - `l2p_plots_{comparison}_downregulated_pathways_bar.png`

4. **l2p_results_provenance.csv**: Analysis metadata and parameters

## Optional: Advanced Configuration

Beyond the basic settings, you can fine-tune the analysis using these optional parameter categories:

### Column Overrides
If the automatic column detection doesn't work for your data:
- **Gene Name Column**: Specify which column contains gene identifiers
- **Ranking Column**: Override the auto-detected `{comparison}_tstat` column
- **Significance Column**: Override the auto-detected `{comparison}_pval` column
- **Fold Change Column**: Override the auto-detected `{comparison}_FC` column

### Gene Selection
Control which genes are included in the pathway analysis:
- **Select by rank** (default: FALSE): Use top-ranked genes instead of the default significance and fold-change thresholds
- **Select top percentage** (default: TRUE): Select top % of genes vs. fixed number
- **Select top genes** (default: 500): Number of top genes when not using percentage
- **Significance threshold** (default: 0.05): P-value cutoff when selecting by significance
- **Fold change threshold** (default: 1.2): FC cutoff when selecting by significance
- **Minimum DEG genes** (default: 100): Minimum genes required to proceed

### Pathway Settings
Filter and refine pathway results:
- **Minimum pathway hits** (default: 5): Minimum genes required per pathway
- **P-value threshold for output** (default: 0.05): Filter results to significant pathways (set to 0 to show all)
- **Use built-in gene universe** (default: FALSE): Use curated gene lists vs. detected genes
- **Use FDR p-values** (default: FALSE): Report FDR-adjusted p-values instead of raw p-values

### Visualization
Customize plot appearance:
- **Shared bubble plot top pathways** (default: 20): Top N pathways shown in each current OMIX plot
- **Pathway label max length** (default: 45): Truncate long pathway names
- **Font sizes**: Customize pathway labels, axis titles, and tick labels
- **Custom pathway selection**: Manually specify which pathways to visualize (overrides automatic top N selection)
- **Plot dimensions** (default: 14×16 inches): Width and height for saved plots
- **Bubble plot variables**: Choose which metrics control bubble size, color, and sorting

## Tips for Multi-Comparison Analysis

1. **Start with Hallmark (H)**: If unsure which collections to use, start with `H` for a focused set of 50 well-defined pathways
2. **Limit comparisons for clarity**: For clearest visualizations, limit to 3-5 comparisons. More comparisons can make the comparative bubble plots crowded
3. **Adjust filtering as needed**: If you get too few or too many results, adjust:
   - The p-value threshold for output (default 0.05)
   - Gene selection criteria (top N genes or significance thresholds)
   - Minimum pathway hits (default 5 genes)
4. **Use demo data to explore**: Leave "DEG Table File" blank to test with the attached demo data (3 mouse comparisons: B-A, C-A, C-B)
5. **Interpret comparative patterns**: The multi-comparison bubble plots reveal:
   - **Horizontal patterns**: Pathways consistently enriched across multiple comparisons
   - **Vertical patterns**: Comparisons with similar pathway enrichment profiles
   - **Isolated bubbles**: Comparison-specific pathway enrichment

## Understanding the Comparative Bubble Plots

The key output of L2P Multi is the comparative bubble plot showing pathway enrichment across all your comparisons:

**Plot layout:**
- **Y-axis**: Pathway names (top pathways selected)
- **X-axis**: Your comparison groups (e.g., B-A, C-A, C-B)
- **Bubble size**: Typically represents number of hits or percent gene hits per pathway
- **Bubble color**: Typically represents p-value significance (darker = more significant)

**What to look for:**
- Pathways appearing across all comparisons suggest core biological processes
- Pathways unique to one comparison highlight condition-specific biology
- Comparing bubble sizes shows relative enrichment strength across conditions

---

## For Advanced Users: Command-Line Usage

If running via command line or scripts (most users should use the App Panel above):

```bash
Rscript main.R \
  --deg_file /data/deg_table/var_DEGAnalysis.rds \
  --comparisons "B-A,C-A,C-B" \
  --species Mouse \
  --collections_to_include "H,C2" \
  --select_top_genes 500 \
  --minimum_pathway_hit_count 5
```

## Citation

If you use this tool in your research, please cite:
- The l2p R package: https://github.com/ccbr/l2p
- MSigDB (if using MSigDB collections): Liberzon et al., Cell Systems 2015

## Support

For questions or issues:
- **NIDAP Team**: NCICCBRNIDAP@mail.nih.gov
- **CCBR**: CCR Collaborative Bioinformatics Resource

---

**OMIX Collection** | **Bioinformatics** | **Pathway Analysis** | **R**
