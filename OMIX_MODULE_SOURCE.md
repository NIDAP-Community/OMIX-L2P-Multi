# Canonical OMIX Module Source

<!-- omix-adapter-contract: {"aliases":{"deg_table":"deg_file","collections_to_include":"collections","select_top_percentage_of_genes":"select_top_percentage"}} -->

## Canonical module

- **Module:** [OMIX L2P Multi](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Multi)
- **Canonical path:** `modules/OMIX-L2P-Multi/`
- **Canonical module version:** `4.1.0`
- **Canonical interface version:** `1`
- **Canonical release tag:** Pending — baseline tag not yet established.
- **Canonical source reference:** [`53b2ca65aa23f54477f698c4ab6ce0d6ab637a5f`](https://github.com/NIDAP-Community/OMIX/commit/53b2ca65aa23f54477f698c4ab6ce0d6ab637a5f)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-L2P-Multi/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

| Canonical file | Adapter copy | SHA-256 | Purpose |
| --- | --- | --- | --- |
| `R/analysis_functions.R` | `code/functions/analysis_functions.R` | `3e646757f19f0beaae78e6983f77545af25a38dc25b057612b350c7ac3251f45` | Multi-comparison L2P implementation. |

The complete canonical `R/` tree contains the one file above. It was exported
without modification and verified byte-for-byte at the canonical source
reference. The completed canonical `schemas/interface.yml` used to build the
adapter contract has SHA-256
`5f25de92c72b582852f052b10c82ba501cde9283d0d44752dba205cc03920584`.

Canonical `4.1.0` adds configurable rank, significance, and fold-change column
suffixes while preserving the requested comparison order. Exact ordered
column-list overrides take precedence over suffix settings. Returned and
CSV-serialized result rows remain grouped in requested comparison order with
ascending p-value ranking within each comparison. The adapter does not
post-process or independently reorder those scientific results.

## Platform translations and compatibility

- The canonical `deg_table` path is the named Code Ocean file selector. When
  left blank, the adapter accepts exactly one supported attached table or one
  unambiguous workflow DEG result; it lists candidates and stops on ambiguity.
- The released `--deg_file` alias remains accepted for saved runs, including
  its legacy `Table`, `Filtered DEG`, and `All DEG` modes. New App Panel runs
  emit only `--deg_table`.
- The released `--collections` and `--select_top_percentage` aliases remain
  accepted for saved runs. The App Panel emits the canonical
  `collections_to_include` and `select_top_percentage_of_genes` names.
- The canonical internal `output_dir` is deployment-managed. Code Ocean writes
  stable outputs to `/results`; local adapter validation may set the internal
  `OMIX_RESULTS_DIR` environment variable. Output paths are not App Panel
  parameters.
- The App Panel exposes all 32 canonical public and advanced controls in schema
  order. It does not expose the 23 internal, deprecated, or inactive
  legacy-renderer controls.
- The App Panel presets the canonical suffix defaults `_tstat`, `_pval`, and
  `_FC`. Users may replace them for a consistent alternative convention;
  exact ordered column-list overrides remain higher priority.

## Genuine demonstration presets

The attached demonstration table is mouse and contains the ordered comparison
columns `B-A`, `C-A`, and `B-C`. To make the untouched demo runnable, the App
Panel presets `species=Mouse` and `comparisons=B-A,C-A,B-C`. These are the only
scientific default exceptions. The adapter CLI itself retains the canonical
portable `species=Human` default and requires comparisons when the caller does
not supply the App Panel preset. Comparison order is preserved through column
inference, analysis, and shared bubble plots; the adapter never reverses a
requested contrast to match an available column.

## Adapter-only support code

- `code/functions/workflow_input.R` implements deterministic Code Ocean mount
  discovery and optional legacy MOSuite workflow conversion.
- `code/functions/cli_compatibility.R` preserves the three released aliases
  documented in the machine-readable marker above.

These files are not canonical scientific exports. They remain co-located with
the managed export until a reviewed Syncweaver mapping can exclude or relocate
them without breaking the capsule.

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | Pending — baseline tag not yet established. |
| Adapter release tag | Pending. |
| Platform release | Pending validation record. |
| Runtime tag | `codeocean/omix-r-pathway:r4.4.3-bioconductor3.20-v2` (from `.codeocean/environment.json`). |
| Runtime digest | Pending — no immutable digest has been validated or recorded. |
| Named-parameter platform run | Code Ocean computation `814585` completed successfully on 2026-09-30 against merged adapter commit `f47e569dfc131bf38a47109b301d1772e03547f3` using `OMIX Pathways v2`. The immutable runtime digest, platform release identifier, and durable output checklist remain pending. |
| Syncweaver lock | Pending — no generated `.syncweaver-lock.json` is recorded. |

The observed computation is recorded in
[docs/code-ocean-validation.md](docs/code-ocean-validation.md), and the
remaining checks are defined by
[docs/code-ocean-validation-plan.md](docs/code-ocean-validation-plan.md). Do
not tag or release the adapter until that exact merged commit, its named runtime
and immutable runtime digest, and the output checklist have passed recorded
platform validation.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior, schemas,
tests, and scientific documentation. This adapter owns deployment UI, input
discovery, result paths, runtime setup, and the platform entry point.

Make reusable changes in the canonical module first, validate them there, and
then export the complete reviewed `R/` tree without modification. Beacon must
audit source, interface, App Panel, and provenance parity before release.
