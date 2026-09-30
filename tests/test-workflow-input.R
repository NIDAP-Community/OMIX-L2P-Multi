#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-workflow-input.R")
}
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))
source(file.path(repo_root, "code", "functions", "workflow_input.R"))

expect_error <- function(expression, pattern) {
  error <- tryCatch({
    force(expression)
    NULL
  }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error), fixed = TRUE))
}

fixture <- tempfile("l2p-multi-workflow-")
workflow_dir <- file.path(fixture, "workflow-id")
dir.create(workflow_dir, recursive = TRUE)
on.exit(unlink(fixture, recursive = TRUE), add = TRUE)

comparisons <- c("B-A", "C-A", "B-C")
deg_table <- data.frame(GeneName = c("GeneA", "GeneB"), check.names = FALSE)
for (comparison in comparisons) {
  deg_table[[paste0(comparison, "_tstat")]] <- c(1, -1)
  deg_table[[paste0(comparison, "_pval")]] <- c(0.001, 0.002)
  deg_table[[paste0(comparison, "_adjpval")]] <- c(0.01, 0.02)
  deg_table[[paste0(comparison, "_FC")]] <- c(2, -2)
}
deg_path <- file.path(workflow_dir, "DEG_Analysis.csv")
write.csv(deg_table, deg_path, row.names = FALSE)
write.csv(data.frame(Package = "example"), file.path(workflow_dir, "r-packages.csv"), row.names = FALSE)

stopifnot(identical(normalizePath(find_workflow_csv(fixture)), normalizePath(deg_path)))
columns <- resolve_workflow_multi_columns(deg_table, comparisons)
stopifnot(
  identical(columns$gene_names_column, "GeneName"),
  identical(unname(columns$t_statistic_columns), paste0(comparisons, "_tstat")),
  identical(unname(columns$significance_columns), paste0(comparisons, "_pval")),
  identical(unname(columns$fold_change_columns), paste0(comparisons, "_FC"))
)

alternative_suffix_table <- data.frame(
  GeneName = c("GeneA", "GeneB"),
  check.names = FALSE
)
for (comparison in comparisons) {
  alternative_suffix_table[[paste0(comparison, "_statistic")]] <- c(1, -1)
  alternative_suffix_table[[paste0(comparison, "_adjpval")]] <- c(0.01, 0.02)
  alternative_suffix_table[[paste0(comparison, "_logFC")]] <- c(1, -1)
}
alternative_columns <- resolve_workflow_multi_columns(
  alternative_suffix_table,
  comparisons,
  t_statistic_suffix = "_statistic",
  significance_suffix = "_adjpval",
  fold_change_suffix = "_logFC"
)
stopifnot(
  identical(
    unname(alternative_columns$t_statistic_columns),
    paste0(comparisons, "_statistic")
  ),
  identical(
    unname(alternative_columns$significance_columns),
    paste0(comparisons, "_adjpval")
  ),
  identical(
    unname(alternative_columns$fold_change_columns),
    paste0(comparisons, "_logFC")
  )
)

expect_error(
  resolve_workflow_multi_columns(
    alternative_suffix_table,
    comparisons,
    t_statistic_suffix = "_statistic",
    significance_suffix = "_missing_significance",
    fold_change_suffix = "_logFC"
  ),
  "Workflow input lacks required column(s): significance_columns"
)

override_table <- alternative_suffix_table
override_table$rank_one <- c(3, -3)
override_table$rank_two <- c(4, -4)
override_table$rank_three <- c(5, -5)
override_table$sig_one <- c(0.01, 0.02)
override_table$sig_two <- c(0.02, 0.03)
override_table$sig_three <- c(0.03, 0.04)
override_table$fc_one <- c(2, -2)
override_table$fc_two <- c(3, -3)
override_table$fc_three <- c(4, -4)
override_columns <- resolve_workflow_multi_columns(
  override_table,
  comparisons,
  t_statistic_columns = "rank_one,rank_two,rank_three",
  significance_columns = "sig_one,sig_two,sig_three",
  fold_change_columns = "fc_one,fc_two,fc_three",
  t_statistic_suffix = "_unused_rank",
  significance_suffix = "_unused_significance",
  fold_change_suffix = "_unused_fold_change"
)
stopifnot(
  identical(unname(override_columns$t_statistic_columns), c(
    "rank_one", "rank_two", "rank_three"
  )),
  identical(unname(override_columns$significance_columns), c(
    "sig_one", "sig_two", "sig_three"
  )),
  identical(unname(override_columns$fold_change_columns), c(
    "fc_one", "fc_two", "fc_three"
  ))
)

gene_symbols_table <- deg_table
names(gene_symbols_table)[names(gene_symbols_table) == "GeneName"] <- "Gene Symbols"
stopifnot(identical(
  resolve_workflow_multi_columns(gene_symbols_table, comparisons)$gene_names_column,
  "Gene Symbols"
))

second_deg <- file.path(workflow_dir, "additional_DEG.csv")
write.csv(data.frame(x = 1), second_deg, row.names = FALSE)
expect_error(find_workflow_csv(fixture), "Multiple workflow DEG CSV candidates")
unlink(second_deg)
unlink(deg_path)

moo_path <- file.path(workflow_dir, "moo-diff.rds")
saveRDS(list(placeholder = TRUE), moo_path)
stopifnot(identical(normalizePath(find_workflow_moo_rds(fixture)), normalizePath(moo_path)))
dir.create(file.path(fixture, "second"))
saveRDS(list(placeholder = TRUE), file.path(fixture, "second", "moo-diff.rds"))
expect_error(find_workflow_moo_rds(fixture), "Multiple workflow moo-diff.rds candidates")

attached_dir <- file.path(fixture, "attached")
dir.create(attached_dir)
attached_csv <- file.path(attached_dir, "table.csv")
write.csv(deg_table, attached_csv, row.names = FALSE)
stopifnot(identical(
  normalizePath(find_attached_deg_table(attached_dir)),
  normalizePath(attached_csv)
))
write.csv(deg_table, file.path(attached_dir, "second.tsv"), row.names = FALSE)
expect_error(find_attached_deg_table(attached_dir), "Multiple attached DEG table candidates")

filtered_one <- file.path(fixture, "filtered-one")
filtered_two <- file.path(fixture, "filtered-two")
dir.create(filtered_one)
dir.create(filtered_two)
write.csv(deg_table, file.path(filtered_one, "diff_filt.csv"), row.names = FALSE)
stopifnot(grepl("filtered-one", find_filtered_deg_file(fixture), fixed = TRUE))
write.csv(deg_table, file.path(filtered_two, "diff_filt.csv"), row.names = FALSE)
expect_error(find_filtered_deg_file(fixture), "Multiple Filtered DEG diff_filt.csv candidates")

comparison_one <- file.path(fixture, "comparison-one")
comparison_two <- file.path(fixture, "comparison-two")
dir.create(comparison_one)
dir.create(comparison_two)
write.csv(deg_table, file.path(comparison_one, "diff_B-A.csv"), row.names = FALSE)
stopifnot(grepl("comparison-one", find_comparison_deg_file("B-A", comparison_one), fixed = TRUE))
write.csv(deg_table, file.path(comparison_two, "diff_B-A.csv"), row.names = FALSE)
expect_error(find_comparison_deg_file("B-A", fixture), "Multiple All DEG file for comparison 'B-A' candidates")

message("L2P Multi workflow-input checks passed")
