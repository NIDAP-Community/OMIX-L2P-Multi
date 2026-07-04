#!/usr/bin/env Rscript

# Check installed package versions
cat("=== Installed Package Versions ===\n\n")

packages <- c("l2p", "l2psupp", "optparse", "RCurl", "dplyr", "ggplot2", "tidyr")

for (pkg in packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    version <- as.character(packageVersion(pkg))
    cat(sprintf("%-15s: %s\n", pkg, version))
  } else {
    cat(sprintf("%-15s: NOT INSTALLED\n", pkg))
  }
}

cat("\n=== R Version ===\n")
cat(sprintf("%s\n", R.version.string))
