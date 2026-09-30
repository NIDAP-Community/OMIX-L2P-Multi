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

blank_collection_args <- filter_codeocean_arguments(c(
  "--deg_table", "",
  "--custom_pathways", "/data/custom.csv",
  "--collections_to_include", "",
  "--species", "Mouse"
))
blank_collection_index <- match(
  "--collections_to_include",
  blank_collection_args
)
blank_collection_value <- blank_collection_args[[blank_collection_index + 1L]]
blank_alias_args <- filter_codeocean_arguments(c("--collections", ""))

stopifnot(
  !"--deg_table" %in% blank_collection_args,
  "--custom_pathways" %in% blank_collection_args,
  isTRUE(option_was_supplied(
    blank_collection_args,
    "collections_to_include"
  )),
  identical(blank_collection_value, ""),
  identical(
    resolve_compatibility_alias(
      blank_collection_value,
      NULL,
      "H",
      "collections_to_include",
      "collections",
      canonical_supplied = TRUE,
      alias_supplied = FALSE
    ),
    ""
  ),
  identical(blank_alias_args, c("--collections", "")),
  isTRUE(option_was_supplied(
    "--collections_to_include=",
    "collections_to_include"
  ))
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
