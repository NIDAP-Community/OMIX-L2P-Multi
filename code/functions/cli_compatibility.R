# Adapter-only helpers for preserving released Code Ocean command-line names.

resolve_compatibility_alias <- function(
    canonical_value,
    alias_value,
    default_value,
    canonical_name,
    alias_name) {
  if (!is.null(canonical_value) && !is.null(alias_value)) {
    if (!identical(canonical_value, alias_value)) {
      stop(sprintf(
        "ERROR: --%s and its deprecated alias --%s were both set to different values.",
        canonical_name,
        alias_name
      ))
    }
    return(canonical_value)
  }
  if (!is.null(canonical_value)) return(canonical_value)
  if (!is.null(alias_value)) {
    warning(sprintf(
      "--%s is deprecated; use --%s for new runs.",
      alias_name,
      canonical_name
    ))
    return(alias_value)
  }
  default_value
}
