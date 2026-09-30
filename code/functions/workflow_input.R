# Code Ocean workflow-input helpers for the L2P Multi adapter.
# These helpers intentionally belong to the adapter because they understand
# Code Ocean mounts and the optional MOSuite moo-diff.rds fallback.

first_existing_column <- function(candidates, available_cols) {
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  match <- candidates[candidates %in% available_cols]
  if (length(match) > 0L) match[[1L]] else NULL
}

select_unique_path <- function(paths, label, required = FALSE) {
  paths <- sort(unique(normalizePath(paths, mustWork = FALSE)))
  if (length(paths) > 1L) {
    stop(
      "ERROR: Multiple ", label, " candidates were found. Select the intended ",
      "file explicitly.\n", paste(paths, collapse = "\n")
    )
  }
  if (length(paths) == 0L) {
    if (isTRUE(required)) {
      stop("ERROR: No ", label, " candidate was found.")
    }
    return(NULL)
  }
  paths[[1L]]
}

find_attached_deg_table <- function(base_dir = "/data/deg_table", required = TRUE) {
  candidates <- list.files(
    base_dir,
    pattern = "\\.(csv|tsv|txt|rds)$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  select_unique_path(candidates, "attached DEG table", required = required)
}

find_filtered_deg_file <- function(base_dir = "/data", required = TRUE) {
  candidates <- list.files(
    base_dir,
    pattern = "\\.csv$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  candidates <- candidates[tolower(basename(candidates)) == "diff_filt.csv"]
  select_unique_path(candidates, "Filtered DEG diff_filt.csv", required = required)
}

find_comparison_deg_file <- function(comparison, base_dir = "/data") {
  candidates <- list.files(
    base_dir,
    pattern = "\\.csv$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  target <- tolower(paste0("diff_", comparison, ".csv"))
  matches <- candidates[tolower(basename(candidates)) == target]
  select_unique_path(
    matches,
    paste0("All DEG file for comparison '", comparison, "'"),
    required = TRUE
  )
}

find_workflow_csv <- function(base_dir = "/data") {
  all_csv <- list.files(
    base_dir,
    pattern = "\\.csv$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  matches <- all_csv[grepl("DEG", basename(all_csv), ignore.case = TRUE)]
  select_unique_path(matches, "workflow DEG CSV", required = FALSE)
}

find_workflow_moo_rds <- function(base_dir = "/data") {
  all_rds <- list.files(
    base_dir,
    pattern = "\\.rds$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  matches <- all_rds[tolower(basename(all_rds)) == "moo-diff.rds"]
  select_unique_path(matches, "workflow moo-diff.rds", required = FALSE)
}

load_workflow_moo_rds <- function(path) {
  moo <- readRDS(path)
  diff_tables <- tryCatch(moo@analyses$diff, error = function(e) NULL)
  if (is.null(diff_tables) || !is.list(diff_tables) || length(diff_tables) == 0L) {
    stop("ERROR: Workflow RDS does not contain MOSuite differential-analysis results: ", path)
  }
  if (is.null(names(diff_tables)) || any(!nzchar(names(diff_tables)))) {
    stop("ERROR: MOSuite differential-analysis results must be named by comparison.")
  }
  tryCatch(
    as.data.frame(MOSuite::join_dfs_wide(diff_tables)),
    error = function(e) {
      stop("ERROR: Could not convert workflow moo-diff.rds into a DEG table: ", conditionMessage(e))
    }
  )
}

first_comparison_column <- function(comparison, suffixes, available_cols) {
  direct <- first_existing_column(paste0(comparison, suffixes), available_cols)
  if (!is.null(direct)) return(direct)

  prefixed <- available_cols[
    startsWith(available_cols, paste0(comparison, "_")) &
      vapply(available_cols, function(column) any(endsWith(column, suffixes)), logical(1))
  ]
  if (length(prefixed) > 0L) return(prefixed[[1L]])
  ""
}

parse_workflow_comparisons <- function(comparisons) {
  if (is.null(comparisons) || !nzchar(trimws(comparisons))) {
    stop("ERROR: 'Comparisons' is required when using a workflow DEG table.")
  }
  trimws(strsplit(comparisons, ",", fixed = TRUE)[[1L]])
}

resolve_workflow_multi_columns <- function(df, comparisons) {
  columns <- list(
    gene_names_column = first_existing_column(
      c("GeneName", "Gene Symbols", "Gene", "gene_name", "gene_symbol", "GeneSymbol"),
      colnames(df)
    ),
    t_statistic_columns = vapply(
      comparisons,
      first_comparison_column,
      character(1),
      suffixes = c("_tstat", "_t.stat", "_t_stat", "_stat"),
      available_cols = colnames(df)
    ),
    significance_columns = vapply(
      comparisons,
      first_comparison_column,
      character(1),
      suffixes = c("_pval", "_adjpval", "_padj", "_pvalue", "_p.value", "_FDR"),
      available_cols = colnames(df)
    ),
    fold_change_columns = vapply(
      comparisons,
      first_comparison_column,
      character(1),
      suffixes = c("_FC", "_fc", "_FoldChange", "_logFC"),
      available_cols = colnames(df)
    )
  )

  missing <- c(
    if (is.null(columns$gene_names_column)) "gene_names_column",
    if (any(!nzchar(columns$t_statistic_columns))) "t_statistic_columns",
    if (any(!nzchar(columns$significance_columns))) "significance_columns",
    if (any(!nzchar(columns$fold_change_columns))) "fold_change_columns"
  )
  if (length(missing) > 0L) {
    stop(
      "ERROR: Workflow input lacks required column(s): ",
      paste(missing, collapse = ", "),
      "\nComparisons: ", paste(comparisons, collapse = ", "),
      "\nAvailable columns: ", paste(colnames(df), collapse = ", ")
    )
  }
  columns
}
