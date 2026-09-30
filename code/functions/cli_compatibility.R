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
