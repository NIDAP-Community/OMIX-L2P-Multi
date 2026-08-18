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

second_deg <- file.path(workflow_dir, "additional_DEG.csv")
write.csv(data.frame(x = 1), second_deg, row.names = FALSE)
expect_error(find_workflow_csv(fixture), "Multiple workflow DEG CSV files")
unlink(second_deg)
unlink(deg_path)

moo_path <- file.path(workflow_dir, "moo-diff.rds")
saveRDS(list(placeholder = TRUE), moo_path)
stopifnot(identical(normalizePath(find_workflow_moo_rds(fixture)), normalizePath(moo_path)))
dir.create(file.path(fixture, "second"))
saveRDS(list(placeholder = TRUE), file.path(fixture, "second", "moo-diff.rds"))
expect_error(find_workflow_moo_rds(fixture), "Multiple workflow moo-diff.rds files")

message("L2P Multi workflow-input checks passed")
