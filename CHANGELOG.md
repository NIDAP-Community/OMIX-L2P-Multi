# Changelog

All notable changes to OMIX L2P Pathway Analysis (Multi) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Version numbers correspond to Code Ocean capsule release versions (integers: v1, v2, v3, etc.).

## [Unreleased]

### Added
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
- Downstream workflow input now takes priority over the legacy `All DEG` and
  `Filtered DEG` data-asset modes. It selects one CSV whose filename matches
  the case-insensitive regex `DEG` and infers every requested comparison's
  t-statistic, significance, and fold-change columns.
- Aligned the runtime species default with the Code Ocean App Panel (`Mouse`).
- Replaced `--input_file` parameter with `--deg_file` for consistency
- Data loading logic now supports three input methods:
  1. Direct file upload via App Panel (highest priority)
  2. Data asset attached at `/data/deg_table/` mount point
  3. Falls back with clear error if neither provided
- Default organism changed from "Human" to "Mouse" (2026-07-08)
  - Updated in App Panel default value
  - Updated in `/code/README.md` documentation
- Capsule name simplified from "OMIX L2P Pathway Analysis (Multi)" to "OMIX L2P Multi" (2026-07-08)
- App Panel categories reorganized from 10 to 6 standardized categories (2026-07-08)
  - New structure: Basic Settings, Column Overrides, Gene Selection, Pathway Settings, Custom Pathways, Visualization
  - Matches L2P Single structure for consistency
- App Panel instructions restructured to numbered steps matching OMIX suite style (2026-07-08)
- Support contact updated from "OMIX Team" to "NIDAP Team" in References section (2026-07-08)
- Removed hard-coded input file path requirement

### Fixed
- Non-interactive runs no longer create an implicit `Rplots.pdf` in the code
  directory; plots are written only to the explicit results path.
- Reduced ortholog-mapping logs to a short preview rather than every mapped
  gene.
- App Panel now uses named parameters mode (2026-01-08)
  - Passes arguments as `--param value` instead of positional arguments
  - Prevents optparse errors when file uploads are left blank
  - Enables proper demo dataset functionality
- Empty string argument handling in main.R (2026-01-08)
  - Filters out blank file upload parameters before parsing
  - Resolves "not a valid option" errors when using demo data
- Removed input file existence validation (now handled by data loading logic)

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
