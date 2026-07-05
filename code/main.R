#!/usr/bin/env Rscript

# L2P Multi-Comparison Analysis - Main Entry Point
# Pathway over-representation analysis comparing multiple DEG contrasts

# ===== ENVIRONMENT INFO =====
cat("\n======================================\n")
cat("L2P Multi-Comparison Analysis\n")
cat("======================================\n")
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("l2p package: %s\n", as.character(packageVersion("l2p"))))
cat(sprintf("l2psupp package: %s\n", as.character(packageVersion("l2psupp"))))

# Try to detect MSigDB version
msigdb_version_detected <- FALSE
tryCatch(
  {
    if (exists("msigdb_version", where = asNamespace("l2p"))) {
      cat(sprintf(
        "MSigDB version: %s (from l2p)\n",
        get("msigdb_version", envir = asNamespace("l2p"))
      ))
      msigdb_version_detected <- TRUE
    } else if (exists("msigdb_version", where = asNamespace("l2psupp"))) {
      cat(sprintf(
        "MSigDB version: %s (from l2psupp)\n",
        get("msigdb_version", envir = asNamespace("l2psupp"))
      ))
      msigdb_version_detected <- TRUE
    }
  },
  error = function(e) {}
)

if (!msigdb_version_detected) {
  cat(sprintf(
    "Pathway databases: Bundled in l2psupp v%s\n",
    as.character(packageVersion("l2psupp"))
  ))
  cat(
    "  Pathway database details can be found at https://github.com/ccbr/l2p\n"
  )
}
cat("======================================\n\n")

# ===== DEBUG TIMING UTILITIES =====
.timer_start <- Sys.time()
.step_times <- list()

log_time <- function(step_name) {
  current_time <- Sys.time()
  elapsed <- as.numeric(difftime(current_time, .timer_start, units = "secs"))
  cat(sprintf("[%6.1fs] %s\n", elapsed, step_name))
  .step_times[[step_name]] <<- elapsed
}

# Source the L2P Multi function
log_time("Script initialization")
source("functions/analysis_functions.R")
log_time("Loaded L2P Multi function")

# Load optparse for command-line argument parsing
library(optparse)
log_time("Loaded optparse library")

# Define command-line options (matching L2P Multi parameters)
option_list <- list(
  # Required parameters
  make_option(
    "--input_file",
    type = "character",
    help = "Input DEG table file path (RDS, CSV, TSV)"
  ),
  make_option(
    "--gene_names_column",
    type = "character",
    help = "Column containing gene names"
  ),

  # Comparison columns
  make_option(
    "--comparisons",
    type = "character",
    default = NULL,
    help = "Comma-separated comparison IDs (e.g., 'B-A,C-A')"
  ),
  make_option(
    "--t_statistic_columns",
    type = "character",
    default = NULL,
    help = "Comma-separated t-statistic column names"
  ),
  make_option(
    "--significance_columns",
    type = "character",
    default = NULL,
    help = "Comma-separated p-value column names"
  ),
  make_option(
    "--fold_change_columns",
    type = "character",
    default = NULL,
    help = "Comma-separated fold change column names"
  ),

  # Analysis parameters
  make_option(
    "--species",
    type = "character",
    default = "Human",
    help = "Species [default %default]"
  ),
  make_option(
    "--update_genes",
    type = "logical",
    default = TRUE,
    help = "Update gene symbols [default %default]"
  ),
  make_option(
    "--collections",
    type = "character",
    default = "H",
    help = "Comma-separated collections (GO,REACTOME,KEGG,H,C1-C8) [default %default]"
  ),
  make_option(
    "--select_by_rank",
    type = "logical",
    default = TRUE,
    help = "Select genes by rank [default %default]"
  ),
  make_option(
    "--select_top_percentage",
    type = "logical",
    default = TRUE,
    help = "Select top percentage of genes [default %default]"
  ),
  make_option(
    "--select_top_genes",
    type = "integer",
    default = 500,
    help = "Number of top genes if not using percentage [default %default]"
  ),
  make_option(
    "--significance_threshold",
    type = "double",
    default = 0.05,
    help = "P-value threshold [default %default]"
  ),
  make_option(
    "--fold_change_threshold",
    type = "double",
    default = 1.2,
    help = "Fold change threshold [default %default]"
  ),
  make_option(
    "--minimum_number_of_deg_genes",
    type = "integer",
    default = 100,
    help = "Minimum DEG genes per comparison [default %default]"
  ),

  # Plot parameters
  make_option(
    "--top_pathways",
    type = "integer",
    default = 10,
    help = "Number of top pathways to compare [default %default]"
  ),
  make_option(
    "--number_of_significant_events",
    type = "integer",
    default = 1,
    help = "Minimum significant events [default %default]"
  ),
  make_option(
    "--maximum_pathways_to_plot",
    type = "integer",
    default = 15,
    help = "Maximum pathways to display in plot [default %default]"
  ),
  make_option(
    "--plot_bubble_size",
    type = "character",
    default = "pval",
    help = "Bubble size metric (pval/fdr/number_hits) [default %default]"
  ),
  make_option(
    "--plot_bubble_color",
    type = "character",
    default = "enrichment_score",
    help = "Bubble color metric [default %default]"
  ),
  make_option(
    "--pathway_axis_label_max_length",
    type = "integer",
    default = 45,
    help = "Max pathway label length [default %default]"
  ),
  make_option(
    "--pathway_axis_label_font_size",
    type = "integer",
    default = 5,
    help = "Pathway label font size [default %default]"
  ),

  # Output parameters
  make_option(
    "--output_plot",
    type = "character",
    default = "/results/l2p_multi_plot.png",
    help = "Output plot file path [default %default]"
  ),
  make_option(
    "--output_results",
    type = "character",
    default = "/results/l2p_multi_results.csv",
    help = "Output results file path [default %default]"
  ),
  make_option(
    "--plot_width",
    type = "integer",
    default = 14,
    help = "Plot width in inches [default %default]"
  ),
  make_option(
    "--plot_height",
    type = "integer",
    default = 16,
    help = "Plot height in inches [default %default]"
  ),

  # Advanced parameters
  make_option(
    "--custom_pathways",
    type = "character",
    default = NULL,
    help = "Path to custom pathway file [default %default]"
  ),
  make_option(
    "--custom_pathway_name_column",
    type = "character",
    default = "gene_set_name",
    help = "Column name for pathway names in custom file [default %default]"
  ),
  make_option(
    "--custom_pathway_gene_column",
    type = "character",
    default = "gene_symbol",
    help = "Column name for genes in custom file [default %default]"
  ),
  make_option(
    "--plot_bubble_max_color",
    type = "double",
    default = 1,
    help = "Maximum value for color scale [default %default]"
  ),
  make_option(
    "--use_built_in_gene_universe",
    type = "logical",
    default = FALSE,
    help = "Use built-in gene universe [default %default]"
  ),
  make_option(
    "--minimum_pathway_hit_count",
    type = "integer",
    default = 5,
    help = "Minimum genes per pathway [default %default]"
  ),
  make_option(
    "--pathway_size_limit",
    type = "integer",
    default = 500,
    help = "Maximum pathway size [default %default]"
  ),
  make_option(
    "--p_value_limit",
    type = "double",
    default = 0.05,
    help = "P-value cutoff for pathways [default %default]"
  ),
  make_option(
    "--use_fdr_for_significance",
    type = "logical",
    default = FALSE,
    help = "Use FDR instead of p-value [default %default]"
  ),
  make_option(
    "--pathways_to_remove",
    type = "character",
    default = NULL,
    help = "Comma-separated pathways to exclude [default %default]"
  ),
  make_option(
    "--rename_groups",
    type = "character",
    default = NULL,
    help = "Comma-separated new names for comparison groups [default %default]"
  ),
  make_option(
    "--vertical_line_placement",
    type = "character",
    default = NULL,
    help = "Comma-separated positions for vertical separator lines [default %default]"
  ),
  make_option(
    "--use_panel_plot",
    type = "logical",
    default = FALSE,
    help = "Use panel layout for plot [default %default]"
  ),
  make_option(
    "--use_dynamic_pathway_font_size",
    type = "logical",
    default = TRUE,
    help = "Auto-adjust font based on pathway count [default %default]"
  ),
  make_option(
    "--custom_pathway_order",
    type = "character",
    default = NULL,
    help = "Comma-separated custom order for pathways [default %default]"
  ),
  make_option(
    "--column_spacing",
    type = "double",
    default = 0.5,
    help = "Spacing between comparison columns [default %default]"
  ),

  # Axis labeling
  make_option(
    "--x_axis_title",
    type = "character",
    default = NULL,
    help = "Optional x-axis title [default %default]"
  ),
  make_option(
    "--y_axis_title",
    type = "character",
    default = NULL,
    help = "Optional y-axis title [default %default]"
  ),
  make_option(
    "--x_axis_title_font_size",
    type = "integer",
    default = 14,
    help = "X-axis title font size [default %default]"
  ),
  make_option(
    "--y_axis_title_font_size",
    type = "integer",
    default = 14,
    help = "Y-axis title font size [default %default]"
  ),
  make_option(
    "--x_axis_tick_font_size",
    type = "integer",
    default = 14,
    help = "X-axis tick label font size [default %default]"
  ),
  make_option(
    "--x_axis_tick_labels",
    type = "character",
    default = NULL,
    help = "Comma-separated labels for x-axis ticks [default %default]"
  ),
  make_option(
    "--y_axis_tick_labels",
    type = "character",
    default = NULL,
    help = "Comma-separated labels for y-axis ticks [default %default]"
  )
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
log_time("Parsed command-line arguments")

# Validate required parameters
if (is.null(opt$input_file)) {
  stop("ERROR: 'input_file' parameter is required")
}
if (is.null(opt$gene_names_column)) {
  stop("ERROR: 'gene_names_column' parameter is required")
}
if (!file.exists(opt$input_file)) {
  stop(sprintf("ERROR: Input file not found: %s", opt$input_file))
}

# Load input data
log_time("Starting data loading")
if (grepl("\\.rds$", opt$input_file, ignore.case = TRUE)) {
  deg_table <- readRDS(opt$input_file)
} else if (grepl("\\.csv$", opt$input_file, ignore.case = TRUE)) {
  deg_table <- read.csv(opt$input_file, stringsAsFactors = FALSE)
} else if (grepl("\\.tsv$|\\.txt$", opt$input_file, ignore.case = TRUE)) {
  deg_table <- read.delim(opt$input_file, stringsAsFactors = FALSE)
} else {
  stop("ERROR: Input file must be .rds, .csv, or .tsv")
}
log_time("Loaded data file")

# Validate gene names column exists
available_cols <- colnames(deg_table)
if (!opt$gene_names_column %in% available_cols) {
  cat("\n=== ERROR: Gene names column not found ===\n")
  cat(sprintf("You specified: '%s'\n", opt$gene_names_column))
  cat(sprintf("Available columns (%d total):\n", length(available_cols)))
  cat(paste("  -", available_cols, collapse = "\n"))
  cat("\n\n")
  stop(sprintf(
    "Column '%s' does not exist in the data. Please check the column name.",
    opt$gene_names_column
  ))
}
cat(sprintf("Using gene names column: %s\n", opt$gene_names_column))

# Parse comma-separated parameters
parse_comma_sep <- function(x) {
  if (is.null(x) || x == "" || x == "NULL") {
    return(NULL)
  }
  trimws(unlist(strsplit(x, ",")))
}

parse_axis_title <- function(x, title_font_size, arg_name) {
  if (is.null(x)) {
    return(NULL)
  }

  x <- trimws(as.character(x))
  if (!nzchar(x) || x %in% c("NULL", "NA")) {
    return(NULL)
  }

  if (
    grepl("^[0-9]+(\\.[0-9]+)?$", x) &&
      isTRUE(all.equal(as.numeric(x), as.numeric(title_font_size)))
  ) {
    warning(sprintf(
      paste0(
        "`%s` was set to `%s`, which matches its title font-size value. ",
        "Treating it as blank; check the app-panel parameter mapping if ",
        "this was not intentional."
      ),
      arg_name,
      x
    ))
    return(NULL)
  }

  x
}

comparisons_vec <- parse_comma_sep(opt$comparisons)
t_stat_cols <- parse_comma_sep(opt$t_statistic_columns)
sig_cols <- parse_comma_sep(opt$significance_columns)
fc_cols <- parse_comma_sep(opt$fold_change_columns)
collections_vec <- parse_comma_sep(opt$collections)
log_time("Parsed column parameters")

cat("\n=== L2P Multi-Comparison Analysis ===\n")
cat(sprintf("Species: %s\n", opt$species))
cat(sprintf("Collections: %s\n", paste(collections_vec, collapse = ", ")))
cat(sprintf("Select by rank: %s\n", opt$select_by_rank))
if (!is.null(comparisons_vec)) {
  cat(sprintf("Comparisons: %s\n", paste(comparisons_vec, collapse = ", ")))
  cat("\nDerived column names:\n")
  for (comp in comparisons_vec) {
    cat(sprintf("  %s_tstat, %s_pval, %s_FC\n", comp, comp, comp))
  }
  cat("\nSearching for these in the data...\n")
  all_cols <- colnames(deg_table)
  for (comp in comparisons_vec) {
    tstat_col <- paste0(comp, "_tstat")
    pval_col <- paste0(comp, "_pval")
    fc_col <- paste0(comp, "_FC")
    cat(sprintf(
      "  %s: %s\n",
      tstat_col,
      ifelse(tstat_col %in% all_cols, "✓ FOUND", "✗ MISSING")
    ))
    cat(sprintf(
      "  %s: %s\n",
      pval_col,
      ifelse(pval_col %in% all_cols, "✓ FOUND", "✗ MISSING")
    ))
    cat(sprintf(
      "  %s: %s\n",
      fc_col,
      ifelse(fc_col %in% all_cols, "✓ FOUND", "✗ MISSING")
    ))
  }

  # Show columns that might match
  cat("\nColumns in data that contain comparison names:\n")
  for (comp in comparisons_vec) {
    matching <- grep(comp, all_cols, value = TRUE, fixed = TRUE)
    if (length(matching) > 0) {
      cat(sprintf(
        "  Matching '%s': %s\n",
        comp,
        paste(matching, collapse = ", ")
      ))
    }
  }
}
cat("\n")

# Run L2P Multi analysis
log_time("Starting L2P Multi analysis")

# Parse advanced parameters that may be NULL or comma-separated
custom_pathways_param <- if (
  !is.null(opt$custom_pathways) && opt$custom_pathways != ""
) {
  opt$custom_pathways
} else {
  NULL
}
pathways_to_remove_vec <- if (
  !is.null(opt$pathways_to_remove) && opt$pathways_to_remove != ""
) {
  trimws(strsplit(opt$pathways_to_remove, ",")[[1]])
} else {
  NULL
}
rename_groups_vec <- if (
  !is.null(opt$rename_groups) && opt$rename_groups != ""
) {
  trimws(strsplit(opt$rename_groups, ",")[[1]])
} else {
  NULL
}
vertical_line_vec <- if (
  !is.null(opt$vertical_line_placement) && opt$vertical_line_placement != ""
) {
  as.numeric(trimws(strsplit(opt$vertical_line_placement, ",")[[1]]))
} else {
  c()
}
custom_pathway_order_vec <- if (
  !is.null(opt$custom_pathway_order) && opt$custom_pathway_order != ""
) {
  trimws(strsplit(opt$custom_pathway_order, ",")[[1]])
} else {
  NULL
}
x_axis_tick_labels_vec <- if (
  !is.null(opt$x_axis_tick_labels) && opt$x_axis_tick_labels != ""
) {
  trimws(strsplit(opt$x_axis_tick_labels, ",")[[1]])
} else {
  NULL
}
y_axis_tick_labels_vec <- if (
  !is.null(opt$y_axis_tick_labels) && opt$y_axis_tick_labels != ""
) {
  trimws(strsplit(opt$y_axis_tick_labels, ",")[[1]])
} else {
  NULL
}
x_axis_title_value <- parse_axis_title(
  opt$x_axis_title,
  opt$x_axis_title_font_size,
  "x_axis_title"
)
y_axis_title_value <- parse_axis_title(
  opt$y_axis_title,
  opt$y_axis_title_font_size,
  "y_axis_title"
)

results <- l2p_multi(
  deg_table = deg_table,
  gene_names_column = opt$gene_names_column,
  comparisons = comparisons_vec,
  t_statistic_columns = t_stat_cols,
  significance_columns = sig_cols,
  fold_change_columns = fc_cols,
  species = opt$species,
  update_genes = opt$update_genes,
  collections_to_include = collections_vec,
  custom_pathways = custom_pathways_param,
  custom_pathway_name_column = opt$custom_pathway_name_column,
  custom_pathway_gene_column = opt$custom_pathway_gene_column,
  select_by_rank = opt$select_by_rank,
  top_pathways = opt$top_pathways,
  number_of_significant_events = opt$number_of_significant_events,
  select_top_percentage_of_genes = opt$select_top_percentage,
  select_top_genes = opt$select_top_genes,
  significance_threshold = opt$significance_threshold,
  fold_change_threshold = opt$fold_change_threshold,
  minimum_number_of_deg_genes = opt$minimum_number_of_deg_genes,
  plot_bubble_size = opt$plot_bubble_size,
  plot_bubble_color = opt$plot_bubble_color,
  plot_bubble_max_color = opt$plot_bubble_max_color,
  pathway_axis_label_max_length = opt$pathway_axis_label_max_length,
  pathway_axis_label_font_size = opt$pathway_axis_label_font_size,
  use_built_in_gene_universe = opt$use_built_in_gene_universe,
  minimum_pathway_hit_count = opt$minimum_pathway_hit_count,
  pathway_size_limit = opt$pathway_size_limit,
  p_value_limit = opt$p_value_limit,
  use_fdr_for_significance = opt$use_fdr_for_significance,
  maximum_pathways_to_plot = opt$maximum_pathways_to_plot,
  pathways_to_remove = pathways_to_remove_vec,
  rename_groups = rename_groups_vec,
  vertical_line_placement = vertical_line_vec,
  use_panel_plot = opt$use_panel_plot,
  use_dynamic_pathway_font_size = opt$use_dynamic_pathway_font_size,
  custom_pathway_order = custom_pathway_order_vec,
  x_axis_title = x_axis_title_value,
  y_axis_title = y_axis_title_value,
  x_axis_title_font_size = opt$x_axis_title_font_size,
  y_axis_title_font_size = opt$y_axis_title_font_size,
  x_axis_tick_font_size = opt$x_axis_tick_font_size,
  x_axis_tick_labels = x_axis_tick_labels_vec,
  y_axis_tick_labels = y_axis_tick_labels_vec,
  export_plot_file = opt$output_plot,
  export_plot_width = opt$plot_width,
  export_plot_height = opt$plot_height,
  column_spacing = opt$column_spacing,
  export_results_file = opt$output_results
)
log_time("L2P Multi analysis completed")

cat("\n=== L2P Multi Analysis completed successfully! ===\n")
cat(sprintf("Results saved to: %s\n", opt$output_results))
cat(sprintf("Plot saved to: %s\n", opt$output_plot))
cat("\n")

# Print timing summary
cat("\n=== Timing Summary (Sorted by Duration) ===\n")

# Calculate step durations
step_durations <- list()
prev_time <- 0
for (step_name in names(.step_times)) {
  elapsed <- .step_times[[step_name]]
  step_duration <- elapsed - prev_time
  step_durations[[step_name]] <- list(
    duration = step_duration,
    cumulative = elapsed
  )
  prev_time <- elapsed
}

# Sort by duration (descending)
sorted_steps <- names(step_durations)[order(
  sapply(step_durations, function(x) x$duration),
  decreasing = TRUE
)]

# Print sorted
for (step_name in sorted_steps) {
  info <- step_durations[[step_name]]
  cat(sprintf(
    "[%6.1fs] (+%5.1fs) %s\n",
    info$cumulative,
    info$duration,
    step_name
  ))
}

total_time <- as.numeric(difftime(Sys.time(), .timer_start, units = "secs"))
cat(sprintf("\n[%6.1fs] TOTAL RUNTIME\n", total_time))
