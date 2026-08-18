# Code Ocean workflow-input helpers for the L2P Multi adapter.
# These helpers intentionally belong to the adapter because they understand
# Code Ocean mounts and the optional MOSuite moo-diff.rds fallback.

first_existing_column <- function(candidates, available_cols) {
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  match <- candidates[candidates %in% available_cols]
  if (length(match) > 0L) match[[1L]] else NULL
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
  if (length(matches) > 1L) {
    stop(
      "ERROR: Multiple workflow DEG CSV files were found under ", base_dir,
      ". Specify an uploaded file or provide exactly one CSV whose filename ",
      "matches the regex 'DEG'.\n", paste(matches, collapse = "\n")
    )
  }
  if (length(matches) == 1L) matches[[1L]] else NULL
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
  if (length(matches) > 1L) {
    stop(
      "ERROR: Multiple workflow moo-diff.rds files were found under ",
      base_dir, ".\n", paste(matches, collapse = "\n")
    )
  }
  if (length(matches) == 1L) matches[[1L]] else NULL
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
      c("GeneName", "Gene", "gene_name", "gene_symbol", "GeneSymbol"),
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
      suffixes = c("_adjpval", "_pval", "_padj", "_pvalue", "_p.value", "_FDR"),
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
