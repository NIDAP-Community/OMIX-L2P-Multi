#!/usr/bin/env python3
"""Static contract checks for the L2P Multi Code Ocean adapter."""

import json
import pathlib
import re


ROOT = pathlib.Path(__file__).resolve().parents[1]


def reject_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        assert key not in result, f"Duplicate JSON key: {key}"
        result[key] = value
    return result


PANEL = json.loads(
    (ROOT / ".codeocean" / "app-panel.json").read_text(),
    object_pairs_hook=reject_duplicate_keys,
)
MAIN = (ROOT / "code" / "main.R").read_text()


parameters_list = PANEL.get("parameters", [])
parameter_names = [parameter.get("param_name") for parameter in parameters_list]
assert all(parameter_names), "Every panel parameter must define param_name"
assert len(parameter_names) == len(set(parameter_names)), "Panel param_name values must be unique"
parameters = {parameter["param_name"]: parameter for parameter in parameters_list}

cli_flags = set(re.findall(r'make_option\(\s*"--([a-z0-9_]+)"', MAIN))
cli_flags.update(re.findall(r'^\s*"--([a-z0-9_]+)",?\s*$', MAIN, re.MULTILINE))
compatibility_aliases = {"collections", "select_top_percentage"}
assert compatibility_aliases <= cli_flags, "Released CLI aliases must remain accepted"
assert set(parameters) == cli_flags - compatibility_aliases, (
    f"Panel/canonical CLI controls differ: "
    f"panel-only={sorted(set(parameters) - cli_flags)}; "
    f"CLI-only={sorted((cli_flags - compatibility_aliases) - set(parameters))}"
)
assert "collections" not in parameters
assert "select_top_percentage" not in parameters
assert 'opt$collections_to_include <- resolve_compatibility_alias(' in MAIN
assert 'opt$select_top_percentage_of_genes <- resolve_compatibility_alias(' in MAIN

# Mouse and example comparison order are intentional deployment presets for
# the attached demo. The remaining values below follow the canonical CLI.
expected_defaults = {
    "species": "Mouse",
    "comparisons": "B-A, C-A, B-C",
    "collections_to_include": "H",
    "select_by_rank": "False",
    "select_top_percentage_of_genes": "True",
    "select_top_genes": "500",
    "significance_threshold": "0.05",
    "fold_change_threshold": "1.2",
    "minimum_number_of_deg_genes": "100",
    "number_of_significant_events": "1",
    "pathway_bubble_top_n": "20",
    "pathway_bubble_significance_statistic": "padj",
    "collection_color_scale": "independent",
    "pathway_axis_label_font_size": "5",
}
for name, expected in expected_defaults.items():
    observed = str(parameters[name].get("default_value"))
    assert observed == expected, f"{name}: expected default {expected}, found {observed}"

category_names = {category["id"]: category["name"] for category in PANEL["categories"]}
assert category_names["basic"] == "Main Settings"
for category_id, category_name in category_names.items():
    if category_id != "basic":
        assert category_name.startswith("Advanced:"), (
            f"Non-primary category {category_id} must be explicitly labeled Advanced"
        )
assert parameters["gene_names_column"]["category"] == "columns"
for legacy_name in ("top_pathways", "maximum_pathways_to_plot", "output_plot"):
    assert parameters[legacy_name]["category"] == "compatibility"

print("L2P Multi app-panel contract checks passed")
