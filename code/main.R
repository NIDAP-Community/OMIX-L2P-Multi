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
  # Data input (upload takes priority over data asset)
  make_option(
    "--deg_file",
    type = "character",
    default = NULL,
    help = "Upload DEG file (CSV, TSV, or RDS)"
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

# Filter out empty string arguments before optparse sees them
# Code Ocean passes --param "" for blank file uploads, which optparse rejects
args <- commandArgs(trailingOnly = TRUE)
filtered_args <- character()
i <- 1
while (i <= length(args)) {
  # Skip standalone empty strings
  if (args[i] == "") {
    i <- i + 1
  } else if (i < length(args) && startsWith(args[i], "--") && args[i+1] == "") {
    # Skip flag + empty value pairs
    i <- i + 2
  } else {
    filtered_args <- c(filtered_args, args[i])
    i <- i + 1
  }
}

opt <- parse_args(opt_parser, args = filtered_args)
log_time("Parsed command-line arguments")

# Validate required parameters
if (is.null(opt$gene_names_column)) {
  stop("ERROR: 'gene_names_column' parameter is required")
}

# Load input data: uploaded file > data asset (priority-based loading)
log_time("Starting data loading")

deg_table <- NULL
input_file_path <- NULL

# Priority 1: Check for uploaded file
if (!is.null(opt$deg_file) && opt$deg_file != "" && file.exists(opt$deg_file)) {
  input_file_path <- opt$deg_file
  cat(sprintf("Loading DEG table from uploaded file: %s\n", input_file_path))
  
  if (grepl("\\.rds$", input_file_path, ignore.case = TRUE)) {
    deg_table <- readRDS(input_file_path)
    # If RDS contains a list, extract the data frame
    if (is.list(deg_table) && !is.data.frame(deg_table)) {
      df_elements <- sapply(deg_table, is.data.frame)
      if (any(df_elements)) {
        deg_table <- deg_table[[which(df_elements)[1]]]
        cat("Extracted data frame from list\n")
      } else {
        stop("ERROR: RDS file does not contain a data frame")
      }
    }
  } else if (grepl("\\.csv$", input_file_path, ignore.case = TRUE)) {
    deg_table <- read.csv(input_file_path, stringsAsFactors = FALSE, check.names = FALSE)
  } else if (grepl("\\.tsv$|\\.txt$", input_file_path, ignore.case = TRUE)) {
    deg_table <- read.delim(input_file_path, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    stop("ERROR: Uploaded file must be .rds, .csv, or .tsv")
  }
  log_time("Loaded uploaded file")

  # Warn if the gene names column contains duplicate values
  if (is.data.frame(deg_table) &&
      !is.null(opt$gene_names_column) &&
      opt$gene_names_column %in% colnames(deg_table)) {
    dups <- deg_table[[opt$gene_names_column]][duplicated(deg_table[[opt$gene_names_column]])]
    if (length(dups) > 0) {
      uniq_dups  <- unique(dups)
      sample_str <- paste(head(uniq_dups, 5), collapse = ", ")
      if (length(uniq_dups) > 5) sample_str <- paste0(sample_str, " ...")
      cat(sprintf(
        "\nWARNING: %d duplicate value(s) in '%s' column of '%s': %s\n\n",
        length(dups), opt$gene_names_column, basename(input_file_path), sample_str
      ))
    }
  }
}

# Priority 2: Auto-detect DEG table from attached data asset at /data/deg_table/
#
# Two input types are supported:
#   A) Single flat file (CSV/TSV/TXT) or single RDS  → used directly.
#   B) Folder structure (e.g. MOSuite moo-properties) → controlled by 'DEG Table File':
#        "Filtered DEG" → load analyses/diff_filt.csv  (all comparisons, wide format)
#        "All DEG"      → load diff_{comparison}.csv per comparison, rename columns
#                         with <comparison>_ prefix, then merge on Gene Names Column.
#      If neither keyword is set, comparison-ID scoring picks the best matching file.
#
# All load paths emit a WARNING if the Gene Names Column contains duplicate values.

load_flat_file <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  }
}

load_rds_as_df <- function(path) {
  obj <- readRDS(path)
  if (is.data.frame(obj)) return(obj)
  if (is.list(obj)) {
    df_idx <- which(sapply(obj, is.data.frame))
    if (length(df_idx) > 0) {
      cat("  Extracted data frame from list element\n")
      return(obj[[df_idx[1]]])
    }
  }
  stop(sprintf("ERROR: RDS file '%s' does not contain a data frame.", path))
}

# Emit a warning if gene_col contains duplicate values in df
warn_gene_duplicates <- function(df, gene_col, file_label) {
  if (is.null(gene_col) || !gene_col %in% colnames(df)) return(invisible(NULL))
  dups     <- df[[gene_col]][duplicated(df[[gene_col]])]
  n_dup    <- length(dups)
  if (n_dup > 0) {
    uniq_dups  <- unique(dups)
    sample_str <- paste(head(uniq_dups, 5), collapse = ", ")
    if (length(uniq_dups) > 5) sample_str <- paste0(sample_str, " ...")
    cat(sprintf(
      "\nWARNING: %d duplicate value(s) in '%s' column of '%s': %s\n\n",
      n_dup, gene_col, file_label, sample_str
    ))
  }
}

# Return the first non-empty element of a comma-separated parameter, or default_val
first_or_default <- function(param_val, default_val) {
  if (is.null(param_val)) return(default_val)
  v <- trimws(as.character(param_val))
  if (nchar(v) == 0 || v == "NULL") return(default_val)
  trimws(unlist(strsplit(v, ",")))[1]
}

# Find diff_filt.csv anywhere under base_dir ("Filtered DEG" mode)
find_filtered_deg_file <- function(base_dir) {
  all_csv   <- list.files(base_dir, pattern = "\\.csv$", full.names = TRUE,
                          recursive = TRUE, ignore.case = TRUE)
  filt_files <- all_csv[tolower(basename(all_csv)) == "diff_filt.csv"]
  if (length(filt_files) == 0) {
    stop(paste0(
      "ERROR: 'Filtered DEG' mode: no 'diff_filt.csv' found under /data/deg_table/.\n",
      "  Ensure the moo-properties asset is attached and contains analyses/diff_filt.csv."
    ))
  }
  if (length(filt_files) > 1) {
    cat(sprintf("  Multiple diff_filt.csv found; using: %s\n", filt_files[1]))
  }
  cat(sprintf("  Found: %s\n", filt_files[1]))
  filt_files[1]
}

# Load diff_{comparison}.csv for every comparison, rename tstat/sig/fc columns
# with a <comparison>_ prefix, and merge all tables on gene_col ("All DEG" mode).
# Also updates opt$t_statistic_columns, opt$significance_columns, opt$fold_change_columns
# so downstream parsing sees the merged column names.
merge_comparison_files <- function(base_dir, comparisons_vec, gene_col,
                                   tstat_col, sig_col, fc_col) {
  cat(sprintf(
    "  Merging %d per-comparison file(s) joined on '%s'...\n",
    length(comparisons_vec), gene_col
  ))
  all_csv <- list.files(base_dir, pattern = "\\.csv$", full.names = TRUE,
                        recursive = TRUE, ignore.case = TRUE)
  merged <- NULL

  for (comp in comparisons_vec) {
    target <- tolower(paste0("diff_", comp, ".csv"))
    matches <- all_csv[tolower(basename(all_csv)) == target]

    if (length(matches) == 0) {
      # Scan for available diff_*.csv files and extract contrast names for guidance
      available_diff <- all_csv[grepl("^diff_.*\\.csv$", tolower(basename(all_csv)))]
      available_contrasts <- sub("^diff_", "", sub("\\.csv$", "", basename(available_diff),
                                                   ignore.case = TRUE), ignore.case = TRUE)
      cat(sprintf(
        "\n=== ERROR: File not found for comparison '%s' ===\n", comp
      ))
      cat(sprintf("  Expected file: diff_%s.csv\n", comp))
      cat(sprintf("  You specified: Comparisons = '%s'\n",
                  paste(comparisons_vec, collapse = ", ")))
      if (length(available_contrasts) > 0) {
        cat("\n  Available contrasts in the dataset (based on diff_*.csv filenames):\n")
        for (ac in sort(available_contrasts)) {
          cat(sprintf("    - %s\n", ac))
        }
        cat("\n  Tip: Update the 'Comparisons' parameter to match one or more of the above.\n")
      } else {
        cat("  No diff_*.csv files found in the dataset at all.\n")
        cat("  Ensure the attached asset is a MOSuite moo-properties output with an analyses/diff/ folder.\n")
      }
      cat("\n")
      stop(sprintf(
        "File 'diff_%s.csv' not found. Check the Comparisons parameter. Available: %s",
        comp,
        if (length(available_contrasts) > 0) paste(sort(available_contrasts), collapse = ", ") else "none"
      ))
    }
    path <- matches[1]
    if (length(matches) > 1) cat(sprintf("  [%s] Multiple matches; using: %s\n", comp, path))
    cat(sprintf("  [%s] Loading: %s\n", comp, path))

    df <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)

    # Validate required columns
    required <- unique(c(gene_col, tstat_col, sig_col, fc_col))
    missing  <- setdiff(required, colnames(df))
    if (length(missing) > 0) {
      stop(sprintf(
        "ERROR: 'diff_%s.csv' is missing column(s): %s\n  Available: %s",
        comp, paste(missing, collapse = ", "), paste(colnames(df), collapse = ", ")
      ))
    }

    # Warn on duplicate gene names within this file
    warn_gene_duplicates(df, gene_col, paste0("diff_", comp, ".csv"))

    # Select, rename: prepend <comparison>_ to the stat columns
    comp_df <- df[, unique(c(gene_col, tstat_col, sig_col, fc_col)), drop = FALSE]
    for (col in c(tstat_col, sig_col, fc_col)) {
      colnames(comp_df)[colnames(comp_df) == col] <- paste0(comp, "_", col)
    }

    merged <- if (is.null(merged)) comp_df else merge(merged, comp_df, by = gene_col, all = TRUE)
    cat(sprintf(
      "  [%s] Columns added: %s_%s, %s_%s, %s_%s\n",
      comp, comp, tstat_col, comp, sig_col, comp, fc_col
    ))
  }

  cat(sprintf("  Merged table: %d row(s) x %d column(s)\n", nrow(merged), ncol(merged)))
  merged
}

if (is.null(deg_table)) {
  # Detect explicit keyword in DEG Table File (only if it is NOT a real file path)
  deg_input_mode <- ""
  if (!is.null(opt$deg_file) && nchar(trimws(opt$deg_file)) > 0) {
    candidate <- trimws(opt$deg_file)
    if (tolower(candidate) %in% c("filtered deg", "all deg")) {
      deg_input_mode <- tolower(candidate)
      cat(sprintf("DEG Table File mode: '%s'\n", candidate))
    }
  }

  cat("Auto-detecting DEG table in /data/deg_table/...\n")
  csv_files <- list.files("/data/deg_table", pattern = "\\.(csv|tsv|txt)$",
                          full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  rds_files  <- list.files("/data/deg_table", pattern = "\\.rds$",
                           full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  cat(sprintf("  Found %d flat file(s) [CSV/TSV/TXT] and %d RDS file(s)\n",
              length(csv_files), length(rds_files)))

  # ── "Filtered DEG": load diff_filt.csv ──────────────────────────────────────
  if (deg_input_mode == "filtered deg") {
    cat("  Mode: Filtered DEG — searching for diff_filt.csv\n")
    input_file_path <- find_filtered_deg_file("/data/deg_table")
    deg_table       <- load_flat_file(input_file_path)
    warn_gene_duplicates(deg_table, opt$gene_names_column, "diff_filt.csv")
    log_time("Loaded diff_filt.csv (Filtered DEG mode)")

  # ── "All DEG": load & merge per-comparison files ─────────────────────────────
  } else if (deg_input_mode == "all deg") {
    cat("  Mode: All DEG — loading and merging per-comparison files\n")
    if (is.null(opt$comparisons) || nchar(trimws(opt$comparisons)) == 0) {
      stop("ERROR: 'All DEG' mode requires the 'Comparisons' parameter to be set.")
    }
    comparisons_vec <- trimws(unlist(strsplit(opt$comparisons, ",")))
    tstat_col <- first_or_default(opt$t_statistic_columns, "tstat")
    sig_col   <- first_or_default(opt$significance_columns, "adjpval")
    fc_col    <- first_or_default(opt$fold_change_columns,  "FC")
    cat(sprintf(
      "  Per-file column names: gene='%s'  tstat='%s'  sig='%s'  fc='%s'\n",
      opt$gene_names_column, tstat_col, sig_col, fc_col
    ))

    deg_table <- merge_comparison_files(
      "/data/deg_table", comparisons_vec,
      opt$gene_names_column, tstat_col, sig_col, fc_col
    )
    input_file_path <- sprintf(
      "All DEG merge of: %s",
      paste(paste0("diff_", comparisons_vec, ".csv"), collapse = ", ")
    )
    warn_gene_duplicates(deg_table, opt$gene_names_column, "merged table")

    # Update column override opts so downstream parse_comma_sep picks up merged names
    opt$t_statistic_columns <- paste(paste0(comparisons_vec, "_", tstat_col), collapse = ",")
    opt$significance_columns <- paste(paste0(comparisons_vec, "_", sig_col),   collapse = ",")
    opt$fold_change_columns  <- paste(paste0(comparisons_vec, "_", fc_col),    collapse = ",")
    cat(sprintf("  Updated T-Statistic Columns → %s\n", opt$t_statistic_columns))
    cat(sprintf("  Updated Significance Columns → %s\n", opt$significance_columns))
    cat(sprintf("  Updated Fold Change Columns  → %s\n", opt$fold_change_columns))
    log_time("Loaded and merged per-comparison files (All DEG mode)")

  # ── Auto Case 1: single flat file ────────────────────────────────────────────
  } else if (length(csv_files) == 1) {
    input_file_path <- csv_files[1]
    cat(sprintf("  Single flat file detected — loading: %s\n", input_file_path))
    deg_table <- load_flat_file(input_file_path)
    warn_gene_duplicates(deg_table, opt$gene_names_column, basename(input_file_path))
    log_time("Loaded single flat file from data asset")

  # ── Auto Case 2: multiple flat files — score by comparison IDs ───────────────
  } else if (length(csv_files) > 1) {
    comparisons_vec_local <- character(0)
    if (!is.null(opt$comparisons) && nchar(trimws(opt$comparisons)) > 0) {
      comparisons_vec_local <- trimws(unlist(strsplit(opt$comparisons, ",")))
    }

    if (length(comparisons_vec_local) > 0) {
      scores    <- sapply(csv_files, function(f) {
        sum(sapply(comparisons_vec_local, function(cmp) grepl(cmp, f, fixed = TRUE)))
      })
      best_score <- max(scores)
      if (best_score > 0) {
        matched         <- csv_files[scores == best_score]
        input_file_path <- matched[1]
        cat(sprintf(
          "  Comparison-matched file (%d/%d IDs in path): %s\n",
          best_score, length(comparisons_vec_local), input_file_path
        ))
        if (length(matched) > 1)
          cat(sprintf(
            "  (%d files tied; using first. Set 'DEG Table File' to select explicitly.)\n",
            length(matched)
          ))
      } else {
        input_file_path <- csv_files[1]
        cat(sprintf("  No comparison-matched file; using first: %s\n", input_file_path))
        cat("  Tip: use 'Filtered DEG' or 'All DEG' for moo-properties assets,")
        cat(" or set 'DEG Table File' explicitly.\n")
      }
    } else {
      input_file_path <- csv_files[1]
      cat(sprintf("  Multiple flat files; using first: %s\n", input_file_path))
      cat("  Tip: set 'DEG Table File' ('Filtered DEG', 'All DEG', or a path) to improve selection.\n")
    }
    deg_table <- load_flat_file(input_file_path)
    warn_gene_duplicates(deg_table, opt$gene_names_column, basename(input_file_path))
    log_time("Loaded flat file from data asset (multi-file asset)")

  # ── Auto Case 3: no flat files, single RDS ───────────────────────────────────
  } else if (length(rds_files) == 1) {
    input_file_path <- rds_files[1]
    cat(sprintf("  Single RDS file detected — loading: %s\n", input_file_path))
    deg_table <- load_rds_as_df(input_file_path)
    warn_gene_duplicates(deg_table, opt$gene_names_column, basename(input_file_path))
    log_time("Loaded single RDS file from data asset")

  # ── Auto Case 4: no flat files, multiple RDS ─────────────────────────────────
  } else if (length(rds_files) > 1) {
    input_file_path <- rds_files[1]
    cat(sprintf("  Multiple RDS files; using first: %s\n", input_file_path))
    cat("  Tip: set 'DEG Table File' to select a specific file.\n")
    deg_table <- load_rds_as_df(input_file_path)
    warn_gene_duplicates(deg_table, opt$gene_names_column, basename(input_file_path))
    log_time("Loaded RDS file from data asset (multi-file asset)")

  # ── Case 5: nothing found ─────────────────────────────────────────────────────
  } else {
    stop(paste0(
      "ERROR: No DEG table found in /data/deg_table/. ",
      "Set 'DEG Table File' to a path, 'Filtered DEG', or 'All DEG'; ",
      "or attach a data asset with mount name 'deg_table'."
    ))
  }
}

# Verify we have a data frame
if (!is.data.frame(deg_table)) {
  stop("ERROR: Loaded data is not a data frame")
}

# ── DEG table input summary ──────────────────────────────────────────────────
cat("\n")
cat("=== DEG Table Input ===\n")
if (exists("input_file_path") && !is.null(input_file_path) && nchar(input_file_path) > 0) {
  cat(sprintf("  File   : %s\n", input_file_path))
} else if (!is.null(opt$deg_file) && tolower(trimws(opt$deg_file)) == "all deg") {
  cat(sprintf("  Mode   : All DEG (merged per-comparison files)\n"))
}
cat(sprintf("  Rows   : %d\n", nrow(deg_table)))
cat(sprintf("  Columns: %d  [%s]\n",
            ncol(deg_table),
            paste(head(colnames(deg_table), 6), collapse = ", ")))
cat("=======================\n\n")

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

load_custom_pathways <- function(path, pathway_name_column, gene_column) {
  if (is.null(path)) {
    return(NULL)
  }

  path <- trimws(as.character(path[[1]]))
  if (!nzchar(path) || path %in% c("NULL", "NA")) {
    return(NULL)
  }

  if (!file.exists(path)) {
    stop(sprintf("ERROR: Custom pathway file not found: %s", path))
  }

  cat(sprintf("\nLoading custom pathways from: %s\n", path))
  custom_pathways <- if (grepl("\\.rds$", path, ignore.case = TRUE)) {
    readRDS(path)
  } else if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  } else if (grepl("\\.tsv$|\\.txt$", path, ignore.case = TRUE)) {
    utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    stop(
      paste0(
        "ERROR: Custom pathway file must be .rds, .csv, .tsv, or .txt. ",
        "Received: ",
        path
      )
    )
  }

  if (is.data.frame(custom_pathways)) {
    cat(sprintf(
      "Loaded custom pathway table with %d rows and %d columns.\n",
      nrow(custom_pathways),
      ncol(custom_pathways)
    ))
    cat(sprintf(
      "Custom pathway columns: %s\n",
      paste(colnames(custom_pathways), collapse = ", ")
    ))

    required_columns <- c(pathway_name_column, gene_column)
    missing_columns <- setdiff(required_columns, colnames(custom_pathways))
    if (length(missing_columns) > 0) {
      stop(sprintf(
        paste0(
          "ERROR: Custom pathway file is missing required column(s): %s. ",
          "Set `custom_pathway_name_column` and ",
          "`custom_pathway_gene_column` to match the file."
        ),
        paste(missing_columns, collapse = ", ")
      ))
    }
  } else if (is.list(custom_pathways)) {
    cat(sprintf(
      "Loaded custom pathway list with %d pathway entries.\n",
      length(custom_pathways)
    ))
  } else {
    stop(
      paste0(
        "ERROR: Custom pathway file must contain either a data frame or ",
        "an l2p-formatted list."
      )
    )
  }

  custom_pathways
}

comparisons_vec <- parse_comma_sep(opt$comparisons)
t_stat_cols <- parse_comma_sep(opt$t_statistic_columns)
sig_cols <- parse_comma_sep(opt$significance_columns)
fc_cols <- parse_comma_sep(opt$fold_change_columns)
collections_vec <- parse_comma_sep(opt$collections)
log_time("Parsed column parameters")

# ── Validate all required columns are present in deg_table ──────────────────
# Build a named list of every column we expect to find, flagging which
# parameter specified each one so the error message is actionable.
validate_columns_in_table <- function(cols, param_name, available_cols) {
  if (is.null(cols) || length(cols) == 0) return(invisible(NULL))
  missing <- setdiff(cols, available_cols)
  if (length(missing) > 0) {
    cat(sprintf("\n=== ERROR: Column(s) not found in DEG table ===\n"))
    cat(sprintf("Parameter '%s' specifies: %s\n", param_name, paste(cols, collapse = ", ")))
    cat(sprintf("Missing column(s): %s\n", paste(missing, collapse = ", ")))
    cat(sprintf("Available columns (%d total):\n", length(available_cols)))
    cat(paste("  -", available_cols, collapse = "\n"))
    cat("\n")
    stop(sprintf(
      "Column(s) specified in '%s' not found in data: %s",
      param_name, paste(missing, collapse = ", ")
    ))
  }
}

# Auto-expand a single bare column name (e.g. "tstat") to comparison-prefixed
# equivalents (e.g. "B-A_tstat, C-A_tstat") when the table is in wide format.
# Returns the expanded vector; leaves multi-value or already-found params unchanged.
auto_expand_col <- function(cols, param_name, comparisons_vec, available_cols) {
  if (is.null(cols) || length(cols) != 1) return(cols)      # multi-value: no change
  if (cols[1] %in% available_cols) return(cols)              # found as-is: no change
  if (is.null(comparisons_vec) || length(comparisons_vec) == 0) return(cols)
  expanded <- paste0(comparisons_vec, "_", cols[1])
  if (all(expanded %in% available_cols)) {
    cat(sprintf(
      "  Auto-expanded '%s': '%s' → '%s' (wide-format table)\n",
      param_name, cols[1], paste(expanded, collapse = ", ")
    ))
    return(expanded)
  }
  return(cols)  # can't expand — will fail in validate step with helpful message
}

available_cols <- colnames(deg_table)

# Auto-expand bare column names to comparison-prefixed form (handles diff_filt.csv)
if (!is.null(t_stat_cols)) {
  t_stat_cols <- auto_expand_col(t_stat_cols, "T-Statistic Columns", comparisons_vec, available_cols)
  opt$t_statistic_columns <- paste(t_stat_cols, collapse = ",")
}
if (!is.null(sig_cols)) {
  sig_cols <- auto_expand_col(sig_cols, "Significance Columns", comparisons_vec, available_cols)
  opt$significance_columns <- paste(sig_cols, collapse = ",")
}
if (!is.null(fc_cols)) {
  fc_cols <- auto_expand_col(fc_cols, "Fold Change Columns", comparisons_vec, available_cols)
  opt$fold_change_columns <- paste(fc_cols, collapse = ",")
}

validate_columns_in_table(t_stat_cols, "T-Statistic Columns", available_cols)
validate_columns_in_table(sig_cols,    "Significance Columns", available_cols)
validate_columns_in_table(fc_cols,     "Fold Change Columns",  available_cols)

# When column overrides are NOT set, the analysis derives names from comparisons.
# Validate those derived names are present so the run fails early with clear guidance.
if (!is.null(comparisons_vec) && length(comparisons_vec) > 0 &&
    (is.null(t_stat_cols) || is.null(sig_cols) || is.null(fc_cols))) {
  # Determine the suffix pattern actually used by the data (tstat vs _tstat etc.)
  # We check derived names only for whichever columns are NOT explicitly overridden.
  derived_missing <- character(0)
  for (comp in comparisons_vec) {
    if (is.null(t_stat_cols)) {
      col <- paste0(comp, "_tstat")
      if (!col %in% available_cols) derived_missing <- c(derived_missing, col)
    }
    if (is.null(sig_cols)) {
      col <- paste0(comp, "_pval")
      if (!col %in% available_cols) derived_missing <- c(derived_missing, col)
    }
    if (is.null(fc_cols)) {
      col <- paste0(comp, "_FC")
      if (!col %in% available_cols) derived_missing <- c(derived_missing, col)
    }
  }
  if (length(derived_missing) > 0) {
    cat("\n=== ERROR: Derived column(s) not found in DEG table ===\n")
    cat(sprintf("Comparisons: %s\n", paste(comparisons_vec, collapse = ", ")))
    cat(sprintf("Expected column(s) missing: %s\n", paste(derived_missing, collapse = ", ")))
    cat("Columns in data that contain a comparison ID:\n")
    for (comp in comparisons_vec) {
      matches <- grep(comp, available_cols, value = TRUE, fixed = TRUE)
      if (length(matches) > 0)
        cat(sprintf("  '%s' matches: %s\n", comp, paste(matches, collapse = ", ")))
    }
    cat(sprintf("\nAll available columns (%d):\n", length(available_cols)))
    cat(paste("  -", available_cols, collapse = "\n"))
    cat("\n")
    stop(paste0(
      "Derived column(s) missing from DEG table: ",
      paste(derived_missing, collapse = ", "),
      ". Use the Column Overrides to specify the actual column names, ",
      "or ensure Comparisons matches the column prefix used in your file."
    ))
  }
}
log_time("Validated column presence in DEG table")

cat("\n=== L2P Multi-Comparison Analysis ===\n")
cat(sprintf("Species: %s\n", opt$species))
cat(sprintf("Collections: %s\n", paste(collections_vec, collapse = ", ")))
cat(sprintf("Select by rank: %s\n", opt$select_by_rank))
if (!is.null(comparisons_vec)) {
  cat(sprintf("Comparisons: %s\n", paste(comparisons_vec, collapse = ", ")))
}
# Show the actual column names that passed validation
cat("\nColumn mapping (validated):\n")
cat(sprintf("  Gene names  : %s\n", opt$gene_names_column))
cat(sprintf("  T-statistic : %s\n", if (!is.null(t_stat_cols)) paste(t_stat_cols, collapse = ", ") else "(auto-derived from Comparisons)"))
cat(sprintf("  Significance: %s\n", if (!is.null(sig_cols))    paste(sig_cols, collapse = ", ")    else "(auto-derived from Comparisons)"))
cat(sprintf("  Fold change : %s\n", if (!is.null(fc_cols))     paste(fc_cols, collapse = ", ")     else "(auto-derived from Comparisons)"))
cat("\n")

# Run L2P Multi analysis
log_time("Starting L2P Multi analysis")

# Parse advanced parameters that may be NULL or comma-separated
custom_pathways_param <- load_custom_pathways(
  opt$custom_pathways,
  opt$custom_pathway_name_column,
  opt$custom_pathway_gene_column
)
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
