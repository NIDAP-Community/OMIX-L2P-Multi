#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-comparison-order.R")
}

adapter_dir <- normalizePath(
  file.path(dirname(sub("^--file=", "", script_arg)), "..")
)
source(file.path(adapter_dir, "code", "functions", "analysis_functions.R"))

# Deliberately interleave comparison groups by p-value. The canonical 4.0.0
# behavior retained this global order, whereas 4.0.1 must group results in the
# requested comparison order and keep ascending p-values inside each group.
requested_comparisons <- c("B-A", "C-A", "B-C")
fixture <- data.frame(
  pathway_name = paste0("PATH_", seq_len(9L)),
  group = c("C-A", "B-C", "B-A", "C-A", "B-C", "B-A", "C-A", "B-C", "B-A"),
  pval = c(0.001, 0.002, 0.003, 0.011, 0.012, 0.013, 0.021, 0.022, 0.023),
  stringsAsFactors = FALSE
)

returned <- order_l2p_multi_results(fixture, requested_comparisons)
stopifnot(
  is.factor(returned$group),
  identical(levels(returned$group), requested_comparisons),
  identical(unique(as.character(returned$group)), requested_comparisons)
)

for (comparison in requested_comparisons) {
  comparison_p <- returned$pval[as.character(returned$group) == comparison]
  stopifnot(identical(comparison_p, sort(comparison_p)))
}

csv_file <- tempfile(fileext = ".csv")
on.exit(unlink(csv_file), add = TRUE)
utils::write.csv(returned, csv_file, row.names = FALSE)
serialized <- utils::read.csv(csv_file, stringsAsFactors = FALSE)

stopifnot(
  identical(unique(serialized$group), requested_comparisons),
  identical(serialized$pval, returned$pval)
)

for (comparison in requested_comparisons) {
  comparison_p <- serialized$pval[serialized$group == comparison]
  stopifnot(identical(comparison_p, sort(comparison_p)))
}

message("L2P Multi returned and serialized comparison-order checks passed")
