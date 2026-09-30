#!/usr/bin/env python3
"""Backward-compatible entry point for the adapter contract audit."""

import sys

from check_adapter_contract import audit_repository


failures = audit_repository()
if failures:
    for failure in failures:
        print(f"ERROR: {failure}", file=sys.stderr)
    raise SystemExit(1)

print("L2P Multi adapter contract checks passed")
