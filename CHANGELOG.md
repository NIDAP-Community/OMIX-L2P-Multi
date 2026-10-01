# Changelog

All notable changes to OMIX L2P Pathway Analysis (Multi) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Version numbers correspond to Code Ocean capsule release versions (integers: v1, v2, v3, etc.).

## [Unreleased]

### Added
- A synchronized Code Ocean computation (`868130`) for execution-bearing
  adapter commit `743acb2ebae0ca4325bf801bb8ef1f59a71ab3cb` in
  capsule `5721592`, including the attached-demo parameters and complete visible
  output set. Artifact-content assertions, remaining validation-plan cases,
  runtime digest, release identifier, and release approval remain pending.
- A partial Code Ocean validation record for successful computation `814585`
  on the merged v4.1.0 adapter. The runtime digest, platform release identifier,
  and durable output checklist remain pending and no release is claimed.
- Canonical interface-1 App Panel coverage for all 29 public and advanced
  controls, plus schema/source SHA-256 provenance and a Code Ocean validation
  plan.
- Deterministic attached-input helpers and regression tests that fail with all
  candidate paths instead of selecting the first table on ambiguity.
- Static App Panel contract checks covering complete CLI exposure, canonical
  parameter names, compatibility aliases, category organization, and defaults.
- Local workflow-input tests and a reproducible Code Ocean-shaped debug
  runner for the preferred wide DEG CSV and the `moo-diff.rds` fallback.
- Metadata tag improvements for better discoverability (2026-01-08)
  - Added "MSigDB" tag (tool supports MSigDB H and C collections)
  - Added "gene-sets" tag
  - Standardized tag order across OMIX suite
- File upload capability for DEG tables (2026-07-07)
  - Added "Upload DEG File (Optional)" parameter in App Panel
  - Added data asset support with "DEG Table" dataset parameter
  - Supports RDS, CSV, and TSV file formats
  - Priority-based data loading: uploaded file > data asset > error
  - Automatic extraction of data frames from RDS list objects
  - Updated App Panel instructions to reflect flexible input options
- Demo dataset documentation (2026-07-08)
  - Exposed "Demo DEG Table" in App Panel Data section with help text
  - Updated capsule description to mention demo dataset with 3 comparisons
  - App Panel instructions clarify automatic demo dataset usage
- Support section to `/README.md` and `/code/README.md` with NIDAP Team contact (2026-07-08)
- Keyword footer to `/README.md` and `/code/README.md` for visual branding (2026-07-08)

### Changed
- Updated the managed scientific export to canonical OMIX L2P Multi `4.1.0`
  at commit `53b2ca65aa23f54477f698c4ab6ce0d6ab637a5f`.
  The App Panel and adapter CLI now expose shared suffix controls for ordered
  rank, significance, and fold-change columns. Exact ordered column-list
  overrides retain precedence, and result rows remain grouped in requested
  comparison order with ascending p-value order within each comparison.
- Reorganized the App Panel into Main and Advanced categories containing only
  canonical public and advanced controls. The 23 internal, deprecated, and
  inactive legacy-renderer controls are no longer shown.
- Added the canonical `deg_table` file selector and retained `deg_file` only as
  a released CLI alias for older saved runs.
- Made platform result paths internal and stable under `/results`; removed the
  obsolete `output_plot` and `output_results` App Panel/CLI controls.
- Restored the adapter CLI's canonical `Human` species default. The App Panel
  still presets `Mouse` and `B-A,C-A,B-C` solely for the attached demo.
- The panel now emits canonical `collections_to_include` and
  `select_top_percentage_of_genes` parameters. The previously released
  `collections` and `select_top_percentage` command-line spellings remain
  accepted as aliases for older saved runs.
- Realigned the pathway-label font-size preset with the canonical L2P Multi
  default of 5; the mouse species and ordered demo comparisons remain
  intentional deployment presets.
- Downstream workflow input now takes priority over the legacy `All DEG` and
  `Filtered DEG` data-asset modes. It selects one CSV whose filename matches
  the case-insensitive regex `DEG` and infers every requested comparison's
  t-statistic, significance, and fold-change columns.
- Data loading logic now supports three input methods:
  1. Direct file upload via App Panel (highest priority)
  2. Data asset attached at `/data/deg_table/` mount point
  3. Falls back with clear error if neither provided
- Capsule name simplified from "OMIX L2P Pathway Analysis (Multi)" to "OMIX L2P Multi" (2026-07-08)
- App Panel categories reorganized from 10 to 6 standardized categories (2026-07-08)
  - New structure: Basic Settings, Column Overrides, Gene Selection, Pathway Settings, Custom Pathways, Visualization
  - Matches L2P Single structure for consistency
- App Panel instructions restructured to numbered steps matching OMIX suite style (2026-07-08)
- Support contact updated from "OMIX Team" to "NIDAP Team" in References section (2026-07-08)
- Removed hard-coded input file path requirement

### Fixed
- An explicitly blank `collections_to_include` value is now preserved so a
  custom pathway table can run without silently restoring Hallmark pathways.
- The Code Ocean validation plan now checks requested comparison order in
  analysis provenance and rendered axes, not in the plot manifest, which has
  no comparison-order field.
- Non-interactive runs no longer create an implicit `Rplots.pdf` in the code
  directory; plots are written only to the deployment-managed results path.
- Reduced ortholog-mapping logs to a short preview rather than every mapped
  gene.
- App Panel now uses named parameters mode (2026-01-08)
  - Passes arguments as `--param value` instead of positional arguments
  - Prevents optparse errors when file uploads are left blank
  - Enables proper demo dataset functionality
- Empty string argument handling in main.R (2026-01-08)
  - Filters out blank file upload parameters before parsing
  - Resolves "not a valid option" errors when using demo data
- Explicit input paths and auto-discovered candidates are validated before
  analysis.

## [v4] - 2026-07-06

### Changed
- Minor fixes and improvements

## [v3] - 2026-07-06

### Changed
- Minor fixes and improvements

## [v2] - 2026-07-05

### Added
- Enhanced reproducibility tracking with version logging
- MSigDB version detection and reporting in console output

### Changed
- Improved parameter naming and organization
- Enhanced error messages for better user guidance

## [v1] - 2026-07-04

### Added
- Initial published release of L2P Multi-Comparison Analysis
- Compare pathway enrichment across multiple differential expression contrasts
- Over-representation analysis using Fisher's exact test
- Support for multiple pathway collections (GO, REACTOME, KEGG, MSigDB, WikiPathways)
- Species ortholog mapping (Human, Mouse, Rat, Macaque, Zebrafish, Rabbit, Drosophila)
- Multi-comparison bubble plot visualization
- Gene selection by rank or threshold
- Custom pathway database support
- Advanced plot customization options
- Panel plot layout support
- Comprehensive axis and labeling controls
