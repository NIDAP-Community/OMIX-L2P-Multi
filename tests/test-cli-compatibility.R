#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-cli-compatibility.R")
}
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))
source(file.path(repo_root, "code", "functions", "cli_compatibility.R"))

stopifnot(
  identical(resolve_compatibility_alias(NULL, NULL, "H", "canonical", "old"), "H"),
  identical(resolve_compatibility_alias("GO", NULL, "H", "canonical", "old"), "GO"),
  identical(
    suppressWarnings(resolve_compatibility_alias(NULL, "REACTOME", "H", "canonical", "old")),
    "REACTOME"
  ),
  identical(
    suppressWarnings(resolve_compatibility_alias(
      "H", "REACTOME", "H", "canonical", "old",
      canonical_supplied = FALSE, alias_supplied = TRUE
    )),
    "REACTOME"
  ),
  identical(resolve_compatibility_alias(FALSE, NULL, TRUE, "canonical", "old"), FALSE),
  identical(resolve_compatibility_alias(TRUE, TRUE, FALSE, "canonical", "old"), TRUE),
  isTRUE(option_was_supplied(c("--canonical", "x"), "canonical")),
  isTRUE(option_was_supplied("--canonical=x", "canonical")),
  !isTRUE(option_was_supplied(c("--other", "x"), "canonical"))
)

conflict <- tryCatch(
  resolve_compatibility_alias("GO", "H", "H", "canonical", "old"),
  error = identity
)
stopifnot(
  inherits(conflict, "error"),
  grepl("both set to different values", conditionMessage(conflict), fixed = TRUE)
)

message("L2P Multi CLI compatibility checks passed")
