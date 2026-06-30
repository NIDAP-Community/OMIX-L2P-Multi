#!/usr/bin/env Rscript

# L2P Analysis (Single) - Simplified Main Entry Point
# Over-representation pathway analysis with automatic column detection

# Source the L2P function
source("functions/L2P_Analysis.R")

# Load optparse for command-line argument parsing
library(optparse)

# Define command-line options (all function parameters exposed)
option_list <- list(
  # Basic settings
  make_option("--comparison", type="character", help="Comparison to analyze"),
  make_option("--species", type="character", default="Human", help="Species [default %default]"),
  make_option("--collections_to_include", type="character", default="GO,REACTOME,KEGG", help="Pathway collections [default %default]"),
  
  # Column overrides
  make_option("--gene_name_column", type="character", default=NULL, help="Optional: Override gene name column"),
  make_option("--column_used_to_rank_genes", type="character", default=NULL, help="Optional: Override ranking column"),
  make_option("--significance_column", type="character", default=NULL, help="Optional: Override significance column"),
  make_option("--fold_change_column", type="character", default=NULL, help="Optional: Override fold change column"),
  
  # Gene selection
  make_option("--select_by_rank", type="character", default="TRUE", help="Select by rank [default %default]"),
  make_option("--select_top_percentage_of_genes", type="character", default="TRUE", help="Select top percentage [default %default]"),
  make_option("--select_top_genes", type="integer", default=500, help="Number of top genes [default %default]"),
  make_option("--significance_threshold", type="double", default=0.05, help="Significance threshold [default %default]"),
  make_option("--fold_change_threshold", type="double", default=1.2, help="Fold change threshold [default %default]"),
  make_option("--minimum_number_of_deg_genes", type="integer", default=50, help="Minimum DEG genes [default %default]"),
  
  # Pathway settings
  make_option("--minimum_pathway_hit_count", type="integer", default=5, help="Minimum pathway hits [default %default]"),
  make_option("--p_value_threshold_for_output", type="double", default=0.05, help="P-value threshold [default %default]"),
  make_option("--use_built_in_gene_universe", type="character", default="FALSE", help="Use built-in gene universe [default %default]"),
  make_option("--use_fdr_p_values", type="character", default="FALSE", help="Use FDR p-values [default %default]"),
  
  # Visualization
  make_option("--number_of_pathways_to_plot", type="integer", default=12, help="Number of pathways to plot [default %default]"),
  make_option("--pathway_axis_label_max_length", type="integer", default=50, help="Pathway label max length [default %default]"),
  make_option("--pathway_axis_label_font_size", type="integer", default=15, help="Pathway label font size [default %default]"),
  make_option("--plot_top_pathways_up", type="character", default="TRUE", help="Plot top pathways up [default %default]"),
  make_option("--pathways_to_use_up", type="character", default=NULL, help="Custom pathways up"),
  make_option("--plot_top_pathways_down", type="character", default="TRUE", help="Plot top pathways down [default %default]"),
  make_option("--pathways_to_use_down", type="character", default=NULL, help="Custom pathways down"),
  make_option("--sort_bubble_plot_by", type="character", default="percent gene hits per pathway", help="Sort bubble plot by [default %default]"),
  make_option("--plot_bubble_size", type="character", default="number of hits", help="Bubble size variable [default %default]"),
  make_option("--plot_bubble_color", type="character", default="Fisher's Exact pval", help="Bubble color variable [default %default]"),
  make_option("--bubble_colors", type="character", default="blues", help="Bubble color scheme [default %default]"),
  make_option("--color_for_bar", type="character", default="GreentoBlue", help="Bar plot color [default %default]"),
  make_option("--export_plot_width", type="double", default=12, help="Plot width [default %default]"),
  make_option("--export_plot_height", type="double", default=12, help="Plot height [default %default]")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# Validate required parameters
if (is.null(opt$comparison) || opt$comparison == "") {
  stop("ERROR: 'Comparison' parameter is required. Please specify which comparison to analyze (e.g., 'B-A', 'C-A').")
}

# Find and read DEG table from attached data asset
rds_files <- list.files("/data/deg_table", pattern = "\\.rds$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
csv_files <- list.files("/data/deg_table", pattern = "\\.(csv|tsv|txt)$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)

if (length(rds_files) > 0) {
  deg_table_path <- rds_files[1]
  cat(sprintf("Loading DEG table from RDS file: %s\n", deg_table_path))
  deg_data <- readRDS(deg_table_path)
  
  # If RDS contains a list, extract the data frame
  if (is.list(deg_data) && !is.data.frame(deg_data)) {
    df_elements <- sapply(deg_data, is.data.frame)
    if (any(df_elements)) {
      deg_data <- deg_data[[which(df_elements)[1]]]
      cat("Extracted data frame from list\n")
    } else {
      stop("ERROR: RDS file does not contain a data frame")
    }
  }
  
} else if (length(csv_files) > 0) {
  deg_table_path <- csv_files[1]
  cat(sprintf("Loading DEG table from CSV/TSV file: %s\n", deg_table_path))
  
  file_ext <- tolower(tools::file_ext(deg_table_path))
  if (file_ext == "csv") {
    deg_data <- read.csv(deg_table_path, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    deg_data <- read.delim(deg_table_path, stringsAsFactors = FALSE, check.names = FALSE)
  }
  
} else {
  stop("ERROR: No RDS, CSV, or TSV file found in attached DEG table data asset at /data/deg_table/")
}

# Verify we have a data frame
if (!is.data.frame(deg_data)) {
  stop("ERROR: Loaded data is not a data frame")
}

cat(sprintf("Loaded DEG table: %d rows x %d columns\n", nrow(deg_data), ncol(deg_data)))
cat(sprintf("Available columns: %s\n\n", paste(colnames(deg_data), collapse=", ")))

# Convert string boolean parameters to logical
opt$select_by_rank <- as.logical(opt$select_by_rank)
opt$select_top_percentage_of_genes <- as.logical(opt$select_top_percentage_of_genes)
opt$use_built_in_gene_universe <- as.logical(opt$use_built_in_gene_universe)
opt$use_fdr_p_values <- as.logical(opt$use_fdr_p_values)
opt$plot_top_pathways_up <- as.logical(opt$plot_top_pathways_up)
opt$plot_top_pathways_down <- as.logical(opt$plot_top_pathways_down)

# Parse collections (comma-separated string to vector)
collections <- strsplit(opt$collections_to_include, ",")[[1]]
collections <- trimws(collections)  # Remove whitespace

# Parse custom pathways if provided
pathways_up <- if (!is.null(opt$pathways_to_use_up) && opt$pathways_to_use_up != "") {
  trimws(strsplit(opt$pathways_to_use_up, ",")[[1]])
} else {
  NULL
}

pathways_down <- if (!is.null(opt$pathways_to_use_down) && opt$pathways_to_use_down != "") {
  trimws(strsplit(opt$pathways_to_use_down, ",")[[1]])
} else {
  c()
}

# Set output file paths to /results/
export_plot <- file.path("/results", "l2p_plots.png")
export_results <- file.path("/results", "l2p_results.csv")

# Run L2P analysis
cat(sprintf("Starting L2P Analysis for comparison: %s\n", opt$comparison))
cat(sprintf("Species: %s\n", opt$species))
cat(sprintf("Collections: %s\n\n", paste(collections, collapse=", ")))

# Auto-detect gene name column (or use user override)
if (!is.null(opt$gene_name_column) && opt$gene_name_column != "") {
  # User provided override
  gene_name_column <- opt$gene_name_column
  if (!(gene_name_column %in% colnames(deg_data))) {
    stop(sprintf("ERROR: Specified gene column '%s' not found in data.\nAvailable columns: %s", 
                 gene_name_column, paste(colnames(deg_data), collapse=", ")))
  }
  cat(sprintf("Using user-specified gene name column: '%s'\n", gene_name_column))
} else {
  # Auto-detect
  gene_col_candidates <- c("Gene", "gene", "symbol", "Symbol", "gene_name", "gene_symbol", "GeneSymbol")
  gene_name_column <- NULL
  for (col in gene_col_candidates) {
    if (col %in% colnames(deg_data)) {
      gene_name_column <- col
      break
    }
  }
  
  if (is.null(gene_name_column)) {
    # Default to first column if no match
    gene_name_column <- colnames(deg_data)[1]
    cat(sprintf("Warning: Could not auto-detect gene column. Using first column: '%s'\n", gene_name_column))
    cat("If this is incorrect, specify the correct column in 'Gene Name Column (Optional)' in Advanced Options.\n")
  } else {
    cat(sprintf("Auto-detected gene name column: '%s'\n", gene_name_column))
  }
}

# Handle significance column (or use user override)
if (!is.null(opt$significance_column) && opt$significance_column != "") {
  significance_column <- opt$significance_column
  if (!(significance_column %in% colnames(deg_data))) {
    stop(sprintf("ERROR: Specified significance column '%s' not found in data.\nAvailable columns: %s", 
                 significance_column, paste(colnames(deg_data), collapse=", ")))
  }
  cat(sprintf("Using user-specified significance column: '%s'\n", significance_column))
} else {
  # Try to auto-detect based on comparison
  sig_candidates <- c(
    paste0(opt$comparison, "_pval"),
    paste0(opt$comparison, "_pvalue"),
    paste0(opt$comparison, "_p.value"),
    paste0(opt$comparison, "_FDR")
  )
  significance_column <- NULL
  for (col in sig_candidates) {
    if (col %in% colnames(deg_data)) {
      significance_column <- col
      break
    }
  }
  
  if (!is.null(significance_column)) {
    cat(sprintf("Auto-detected significance column: '%s'\n", significance_column))
  } else {
    cat("Note: Could not auto-detect significance column. Function will handle internally.\n")
  }
}

# Handle fold change column (or use user override)
if (!is.null(opt$fold_change_column) && opt$fold_change_column != "") {
  fold_change_column <- opt$fold_change_column
  if (!(fold_change_column %in% colnames(deg_data))) {
    stop(sprintf("ERROR: Specified fold change column '%s' not found in data.\nAvailable columns: %s", 
                 fold_change_column, paste(colnames(deg_data), collapse=", ")))
  }
  cat(sprintf("Using user-specified fold change column: '%s'\n", fold_change_column))
} else {
  # Try to auto-detect based on comparison
  fc_candidates <- c(
    paste0(opt$comparison, "_FC"),
    paste0(opt$comparison, "_fc"),
    paste0(opt$comparison, "_FoldChange"),
    paste0(opt$comparison, "_logFC")
  )
  fold_change_column <- NULL
  for (col in fc_candidates) {
    if (col %in% colnames(deg_data)) {
      fold_change_column <- col
      break
    }
  }
  
  if (!is.null(fold_change_column)) {
    cat(sprintf("Auto-detected fold change column: '%s'\n", fold_change_column))
  } else {
    cat("Note: Could not auto-detect fold change column. Function will handle internally.\n")
  }
}

# Handle ranking column (or use user override)
if (!is.null(opt$column_used_to_rank_genes) && opt$column_used_to_rank_genes != "") {
  ranking_column <- opt$column_used_to_rank_genes
  if (!(ranking_column %in% colnames(deg_data))) {
    stop(sprintf("ERROR: Specified ranking column '%s' not found in data.\nAvailable columns: %s", 
                 ranking_column, paste(colnames(deg_data), collapse=", ")))
  }
  cat(sprintf("Using user-specified ranking column: '%s'\n", ranking_column))
} else {
  # Try to auto-detect based on comparison
  rank_candidates <- c(
    paste0(opt$comparison, "_tstat"),
    paste0(opt$comparison, "_t.stat"),
    paste0(opt$comparison, "_t_stat"),
    paste0(opt$comparison, "_stat")
  )
  ranking_column <- NULL
  for (col in rank_candidates) {
    if (col %in% colnames(deg_data)) {
      ranking_column <- col
      break
    }
  }
  
  if (!is.null(ranking_column)) {
    cat(sprintf("Auto-detected ranking column: '%s'\n", ranking_column))
  } else {
    cat("Note: Could not auto-detect ranking column. Function will handle internally.\n")
  }
}

results <- l2p_single(
  deg_table = deg_data,
  gene_name_column = gene_name_column,
  column_used_to_rank_genes = ranking_column,
  significance_column = significance_column,
  fold_change_column = fold_change_column,
  comparison = opt$comparison,
  species = opt$species,
  collections_to_include = collections,
  select_by_rank = opt$select_by_rank,
  select_top_percentage_of_genes = opt$select_top_percentage_of_genes,
  select_top_genes = opt$select_top_genes,
  significance_threshold = opt$significance_threshold,
  fold_change_threshold = opt$fold_change_threshold,
  minimum_number_of_deg_genes = opt$minimum_number_of_deg_genes,
  number_of_pathways_to_plot = opt$number_of_pathways_to_plot,
  pathway_axis_label_max_length = opt$pathway_axis_label_max_length,
  plot_top_pathways_up = opt$plot_top_pathways_up,
  pathways_to_use_up = pathways_up,
  plot_top_pathways_down = opt$plot_top_pathways_down,
  pathways_to_use_down = pathways_down,
  sort_bubble_plot_by = opt$sort_bubble_plot_by,
  plot_bubble_size = opt$plot_bubble_size,
  plot_bubble_color = opt$plot_bubble_color,
  bubble_colors = opt$bubble_colors,
  pathway_axis_label_font_size = opt$pathway_axis_label_font_size,
  use_fdr_p_values = opt$use_fdr_p_values,
  color_for_bar = opt$color_for_bar,
  use_built_in_gene_universe = opt$use_built_in_gene_universe,
  minimum_pathway_hit_count = opt$minimum_pathway_hit_count,
  p_value_threshold_for_output = opt$p_value_threshold_for_output,
  export_plot_file = export_plot,
  export_plot_width = opt$export_plot_width,
  export_plot_height = opt$export_plot_height,
  export_results_file = export_results
)

cat("\nL2P Analysis completed successfully!\n")
cat(sprintf("Results saved to: %s\n", export_results))
cat(sprintf("Plots saved to: %s\n", export_plot))
