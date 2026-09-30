# Adapter-only helpers for preserving released Code Ocean command-line names.

resolve_compatibility_alias <- function(
    canonical_value,
    alias_value,
    default_value,
    canonical_name,
    alias_name,
    canonical_supplied = !is.null(canonical_value),
    alias_supplied = !is.null(alias_value)) {
  if (isTRUE(canonical_supplied) && isTRUE(alias_supplied)) {
    if (!identical(canonical_value, alias_value)) {
      stop(sprintf(
        "ERROR: --%s and its deprecated alias --%s were both set to different values.",
        canonical_name,
        alias_name
      ))
    }
    return(canonical_value)
  }
  if (isTRUE(canonical_supplied)) return(canonical_value)
  if (isTRUE(alias_supplied)) {
    warning(sprintf(
      "--%s is deprecated; use --%s for new runs.",
      alias_name,
      canonical_name
    ))
    return(alias_value)
  }
  default_value
}

option_was_supplied <- function(arguments, option_name) {
  any(arguments == paste0("--", option_name)) ||
    any(startsWith(arguments, paste0("--", option_name, "=")))
}

# Code Ocean emits blank file selectors and blank text controls as
# `--parameter ""`. File-selector blanks must be removed before optparse sees
# them, but an empty collection list is meaningful: it requests custom-only
# pathway analysis. Preserve that one intentional empty value (and its released
# alias) while continuing to discard all other empty pairs.
filter_codeocean_arguments <- function(
    arguments,
    preserve_empty_options = c("collections_to_include", "collections")) {
  filtered <- character()
  index <- 1L

  while (index <= length(arguments)) {
    current <- arguments[[index]]

    if (!nzchar(current)) {
      index <- index + 1L
      next
    }

    if (
      startsWith(current, "--") &&
        index < length(arguments) &&
        identical(arguments[[index + 1L]], "")
    ) {
      option_name <- sub("^--", "", current)
      option_name <- sub("=.*$", "", option_name)
      if (option_name %in% preserve_empty_options) {
        filtered <- c(filtered, current, "")
      }
      index <- index + 2L
      next
    }

    filtered <- c(filtered, current)
    index <- index + 1L
  }

  filtered
}
