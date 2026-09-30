#!/usr/bin/env Rscript

assert_custom_only_output <- function(results, provenance) {
  stopifnot(
    "categ" %in% colnames(results),
    all(c("field", "value") %in% colnames(provenance)),
    nrow(results) > 0L
  )

  provenance_value <- function(field) {
    match_index <- match(field, provenance$field)
    if (is.na(match_index)) {
      stop("Missing provenance field: ", field)
    }
    provenance$value[[match_index]]
  }

  collections <- provenance_value("analysis_collections_to_include")
  custom_used <- provenance_value("analysis_custom_pathways_used")
  categories <- unique(as.character(results$categ))

  if (!(is.na(collections) || identical(collections, ""))) {
    stop("Custom-only provenance unexpectedly records built-in collections: ", collections)
  }
  if (!identical(custom_used, "TRUE")) {
    stop("Custom-only provenance does not record custom pathways as used.")
  }
  if (!all(startsWith(categories, "CUSTOM_"))) {
    stop(
      "Custom-only results contain a non-custom category: ",
      paste(categories[!startsWith(categories, "CUSTOM_")], collapse = ", ")
    )
  }

  invisible(TRUE)
}

# Always exercise the assertion and its failure mode without external data.
fixture_provenance <- data.frame(
  field = c(
    "analysis_collections_to_include",
    "analysis_custom_pathways_used"
  ),
  value = c(NA_character_, "TRUE"),
  stringsAsFactors = FALSE
)
stopifnot(isTRUE(assert_custom_only_output(
  data.frame(categ = "CUSTOM_EXAMPLE", stringsAsFactors = FALSE),
  fixture_provenance
)))

built_in_error <- tryCatch(
  {
    assert_custom_only_output(
      data.frame(categ = c("CUSTOM_EXAMPLE", "H"), stringsAsFactors = FALSE),
      fixture_provenance
    )
    NULL
  },
  error = identity
)
stopifnot(
  inherits(built_in_error, "error"),
  grepl("non-custom category", conditionMessage(built_in_error), fixed = TRUE)
)

# When a representative execution directory is supplied, assert its real
# deployment outputs as well. CI runs the dependency-free fixture above; the
# review evidence invokes this path after a full L2P custom-only execution.
results_dir <- Sys.getenv("OMIX_CUSTOM_ONLY_RESULTS_DIR", unset = "")
if (nzchar(results_dir)) {
  assert_custom_only_output(
    utils::read.csv(
      file.path(results_dir, "l2p_multi_results.csv"),
      stringsAsFactors = FALSE,
      check.names = FALSE
    ),
    utils::read.csv(
      file.path(results_dir, "l2p_multi_results_provenance.csv"),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )
  message("Representative custom-only output assertions passed")
} else {
  message("Custom-only output assertion fixtures passed")
}
