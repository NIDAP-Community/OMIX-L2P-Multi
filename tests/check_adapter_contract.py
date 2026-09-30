#!/usr/bin/env python3
"""Audit the L2P Multi Code Ocean adapter against its canonical contract."""

from __future__ import annotations

import json
import hashlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

EXPECTED_ORDER = [
    "deg_table", "custom_pathways", "comparisons", "gene_names_column",
    "t_statistic_columns", "significance_columns", "fold_change_columns",
    "t_statistic_suffix", "significance_suffix", "fold_change_suffix",
    "species", "update_genes", "collections_to_include", "select_by_rank",
    "select_top_percentage_of_genes", "select_top_genes",
    "significance_threshold", "fold_change_threshold",
    "minimum_number_of_deg_genes", "number_of_significant_events",
    "pathway_bubble_plots", "pathway_bubble_top_n",
    "pathway_bubble_significance_statistic", "collection_color_scale",
    "use_built_in_gene_universe", "minimum_pathway_hit_count",
    "pathway_size_limit", "p_value_limit", "use_fdr_for_significance",
    "custom_pathway_name_column", "custom_pathway_gene_column",
    "pathways_to_remove",
]

INTERNAL_CONTROLS = {
    "output_dir", "top_pathways", "maximum_pathways_to_plot",
    "plot_bubble_size", "plot_bubble_color", "plot_bubble_max_color",
    "pathway_axis_label_max_length", "pathway_axis_label_font_size",
    "rename_groups", "vertical_line_placement", "use_panel_plot",
    "use_dynamic_pathway_font_size", "custom_pathway_order", "x_axis_title",
    "y_axis_title", "x_axis_title_font_size", "y_axis_title_font_size",
    "x_axis_tick_font_size", "x_axis_tick_labels", "y_axis_tick_labels",
    "plot_width", "plot_height", "column_spacing",
}
ADAPTER_OUTPUT_CONTROLS = {"output_plot", "output_results"}
LEGACY_ALIASES = {"deg_file", "collections", "select_top_percentage"}

EXPECTED_DEFAULTS = {
    "comparisons": "B-A,C-A,B-C",
    "t_statistic_suffix": "_tstat",
    "significance_suffix": "_pval",
    "fold_change_suffix": "_FC",
    "species": "Mouse",
    "collections_to_include": "H",
    "select_by_rank": "False",
    "select_top_percentage_of_genes": "True",
    "select_top_genes": "500",
    "significance_threshold": "0.05",
    "fold_change_threshold": "1.2",
    "minimum_number_of_deg_genes": "100",
    "number_of_significant_events": "1",
    "pathway_bubble_plots": "True",
    "pathway_bubble_top_n": "20",
    "pathway_bubble_significance_statistic": "padj",
    "collection_color_scale": "independent",
    "use_built_in_gene_universe": "False",
    "minimum_pathway_hit_count": "5",
    "pathway_size_limit": "500",
    "p_value_limit": "0.05",
    "use_fdr_for_significance": "False",
    "update_genes": "True",
    "custom_pathway_name_column": "gene_set_name",
    "custom_pathway_gene_column": "gene_symbol",
}


def reject_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def audit(
    panel: dict,
    main_text: str,
    source_text: str,
    scientific_digest: str | None = None,
) -> list[str]:
    """Return human-readable findings without mutating repository state."""
    findings: list[str] = []
    parameter_list = panel.get("parameters", [])
    parameter_names = [item.get("param_name") for item in parameter_list]

    if panel.get("named_parameters") is not True:
        findings.append("named_parameters must be true")
    if not all(parameter_names):
        findings.append("every App Panel parameter must define param_name")
    if len(parameter_names) != len(set(parameter_names)):
        findings.append("duplicate App Panel param_name values")

    missing = [name for name in EXPECTED_ORDER if name not in parameter_names]
    extra = [name for name in parameter_names if name not in EXPECTED_ORDER]
    if missing:
        findings.append("missing App Panel controls: " + ", ".join(missing))
    if extra:
        findings.append("extra App Panel controls: " + ", ".join(map(str, extra)))
    if parameter_names != EXPECTED_ORDER:
        findings.append("App Panel control order differs from canonical schema")

    parameters = {
        item["param_name"]: item for item in parameter_list if item.get("param_name")
    }
    hidden = sorted(set(parameters) & INTERNAL_CONTROLS)
    if hidden:
        findings.append("internal controls exposed in App Panel: " + ", ".join(hidden))
    outputs = sorted(set(parameters) & ADAPTER_OUTPUT_CONTROLS)
    if outputs:
        findings.append("deployment output controls exposed in App Panel: " + ", ".join(outputs))
    aliases = sorted(set(parameters) & LEGACY_ALIASES)
    if aliases:
        findings.append("legacy aliases exposed in App Panel: " + ", ".join(aliases))

    for name, expected in EXPECTED_DEFAULTS.items():
        observed = parameters.get(name, {}).get("default_value")
        if str(observed) != expected:
            findings.append(f"{name}: App Panel default mismatch")

    expected_shapes = {
        "deg_table": ("file", None),
        "custom_pathways": ("file", None),
        "species": (
            "list",
            ["Human", "Mouse", "Macaque", "Rat", "Zebrafish", "Rabbit", "Drosophila"],
        ),
        "pathway_bubble_significance_statistic": ("list", ["padj", "pval"]),
        "collection_color_scale": ("list", ["independent", "shared"]),
    }
    for name, (panel_type, choices) in expected_shapes.items():
        parameter = parameters.get(name, {})
        if parameter.get("type") != panel_type:
            findings.append(f"{name}: App Panel type mismatch")
        if choices is not None and parameter.get("extra_data") != choices:
            findings.append(f"{name}: App Panel choices mismatch")

    cli_flags = set(re.findall(r'make_option\(\s*"--([a-z0-9_]+)"', main_text))
    missing_cli = sorted(set(EXPECTED_ORDER) - cli_flags)
    if missing_cli:
        findings.append("canonical controls missing from adapter CLI: " + ", ".join(missing_cli))
    if not LEGACY_ALIASES <= cli_flags:
        findings.append("released CLI aliases are no longer accepted")
    if ADAPTER_OUTPUT_CONTROLS & cli_flags:
        findings.append("result paths must remain deployment managed")

    marker = (
        '"aliases":{"deg_table":"deg_file","collections_to_include":"collections",'
        '"select_top_percentage_of_genes":"select_top_percentage"}'
    )
    if marker not in source_text:
        findings.append("machine-readable alias record is missing")
    if scientific_digest is not None and scientific_digest not in source_text:
        findings.append("managed scientific source SHA-256 is absent from source record")
    for required in (
        "OMIX_RESULTS_DIR",
        "find_attached_deg_table",
        "filter_codeocean_arguments",
        "t_statistic_suffix = opt$t_statistic_suffix",
        "significance_suffix = opt$significance_suffix",
        "fold_change_suffix = opt$fold_change_suffix",
        'opt[["x_axis_title"]]',
        'opt[["y_axis_title"]]',
    ):
        if required not in main_text:
            findings.append(f"required adapter binding is missing: {required}")

    return findings


def audit_repository() -> list[str]:
    panel = json.loads(
        (ROOT / ".codeocean" / "app-panel.json").read_text(),
        object_pairs_hook=reject_duplicate_keys,
    )
    scientific_digest = hashlib.sha256(
        (ROOT / "code" / "functions" / "analysis_functions.R").read_bytes()
    ).hexdigest()
    return audit(
        panel,
        (ROOT / "code" / "main.R").read_text(),
        (ROOT / "OMIX_MODULE_SOURCE.md").read_text(),
        scientific_digest,
    )


if __name__ == "__main__":
    failures = audit_repository()
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        raise SystemExit(1)
    print("L2P Multi adapter contract checks passed")
