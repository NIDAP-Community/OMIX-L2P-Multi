#!/usr/bin/env python3
"""Mutation tests proving the L2P Multi adapter checker detects drift."""

import copy
import importlib.util
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "adapter_contract", ROOT / "tests" / "check_adapter_contract.py"
)
CONTRACT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONTRACT)


class AdapterContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.panel = json.loads((ROOT / ".codeocean" / "app-panel.json").read_text())
        cls.main_text = (ROOT / "code" / "main.R").read_text()
        cls.source_text = (ROOT / "OMIX_MODULE_SOURCE.md").read_text()

    def audit(self, panel=None, main_text=None):
        return CONTRACT.audit(
            panel if panel is not None else self.panel,
            main_text if main_text is not None else self.main_text,
            self.source_text,
        )

    def test_repository_contract_passes(self):
        self.assertEqual(self.audit(), [])

    def test_missing_control_is_detected(self):
        panel = copy.deepcopy(self.panel)
        panel["parameters"] = panel["parameters"][:-1]
        self.assertTrue(
            any("missing App Panel controls" in item for item in self.audit(panel))
        )

    def test_extra_control_is_detected(self):
        panel = copy.deepcopy(self.panel)
        panel["parameters"].append(
            {
                "id": "test-extra",
                "param_name": "not_canonical",
                "type": "text",
                "value_type": "string",
            }
        )
        self.assertTrue(
            any("extra App Panel controls" in item for item in self.audit(panel))
        )

    def test_internal_control_is_detected(self):
        panel = copy.deepcopy(self.panel)
        panel["parameters"].append(
            {
                "id": "test-internal",
                "param_name": "plot_width",
                "type": "text",
                "value_type": "number",
            }
        )
        self.assertTrue(
            any("internal controls exposed" in item for item in self.audit(panel))
        )

    def test_default_drift_is_detected(self):
        panel = copy.deepcopy(self.panel)
        for parameter in panel["parameters"]:
            if parameter.get("param_name") == "pathway_bubble_top_n":
                parameter["default_value"] = 10
        self.assertIn(
            "pathway_bubble_top_n: App Panel default mismatch",
            self.audit(panel),
        )

    def test_retired_output_control_is_detected_in_cli(self):
        main_text = self.main_text + (
            '\nmake_option("--output_results", type = "character")\n'
        )
        self.assertIn(
            "result paths must remain deployment managed",
            self.audit(main_text=main_text),
        )


if __name__ == "__main__":
    unittest.main()
